//
// gatagata: ���f�����K�^�K�^�ɂ��܂�
//

static const float PerturbMaxWidth = 10.0;
static const float PerturbFrequency = 1;
static const float YScalingMin = 0.2;
static const float YScalingMax = 0.8;
static const float NormalDistortionFrequency = 0.1;
static const float NormalDistortionMaxAngle = 0.2;

// LightColor �ɑ΂��� AmbientColor �̑傫��
static const float AmbientCoeff = 0.1;

//---------------------------------------------------------------------------------------------

// ���@�ϊ��s��
float4x4 WorldViewProjMatrix      : WORLDVIEWPROJECTION;
float4x4 WorldMatrix              : WORLD;
float4x4 ViewMatrix               : VIEW;
float4x4 LightWorldViewProjMatrix : WORLDVIEWPROJECTION < string Object = "Light"; >;

float3   LightDirection    : DIRECTION < string Object = "Light"; >;
float3   CameraPosition    : POSITION  < string Object = "Camera"; >;

// �}�e���A���F
float3   MaterialAmbient   : AMBIENT  < string Object = "Geometry"; >;
float4   MaterialDiffuse   : DIFFUSE  < string Object = "Geometry"; >;
float3   MaterialSpecular  : SPECULAR < string Object = "Geometry"; >;
float    SpecularPower     : SPECULARPOWER < string Object = "Geometry"; >;
float4   EdgeColor         : EDGECOLOR;
float4   GroundShadowColor : GROUNDSHADOWCOLOR;
// ���C�g�F
float3   LightAmbient        : AMBIENT < string Object = "Light"; >;
static float3 LightColor = LightAmbient * 4;
static float3 AmbientColor = LightColor * AmbientCoeff;

// �e�N�X�`���ގ����[�t�l
float4   TextureAddValue   : ADDINGTEXTURE;
float4   TextureMulValue   : MULTIPLYINGTEXTURE;

bool     parthf;   // �p�[�X�y�N�e�B�u�t���O
bool     transp;   // �������t���O
#define SKII1    1500
#define SKII2    8000

// �I�u�W�F�N�g�̃e�N�X�`��
texture ObjectTexture: MATERIALTEXTURE;
sampler ObjectTextureSampler = sampler_state {
	texture = <ObjectTexture>;
	MINFILTER = LINEAR;
	MAGFILTER = LINEAR;
	MIPFILTER = LINEAR;
	ADDRESSU  = WRAP;
	ADDRESSV  = WRAP;
};

static const float PI = 3.14159265;
static const float TAU = 2 * PI;

// �V���h�E�o�b�t�@�̃T���v���B"register(s0)"�Ȃ̂�MMD��s0���g���Ă��邩��
sampler ShadowBufferSampler : register(s0);

//---------------------------------------------------------------------------------------------

float  hash(float  v) { return frac(sin(v * 78.233) * 43758.5453123); }
float2 hash(float2 v) { return frac(sin(v * 78.233) * 43758.5453123); }
float3 hash(float3 v) { return frac(sin(v * 78.233) * 43758.5453123); }
float4 hash(float4 v) { return frac(sin(v * 78.233) * 43758.5453123); }

float hash12(float2 v)
{
	float2 e;
	v = frexp(v, e);
	v += e * (1.0 / 129.0);
	return hash(hash(v.x) + v.y);
}

float hash13(float3 v)
{
	float3 e;
	v = frexp(v, e);
	v += e * (1.0 / 129.0);
	return hash(hash(hash(v.x) + v.y) + v.z);
}

float3 hash33(float3 v)
{
	float3 e;
	v = frexp(v, e);
	v += e * (1.0 / 129.0);
	return hash(hash(hash(v.x + float3(0, 4.31265, 9.38974)) + v.y) + v.z);
}

float ValueNoise12(float2 src)
{
	float2 i = floor(src);
	float2 f = frac(src);

	float v1 = hash12(i + float2(0.0, 0.0));
	float v2 = hash12(i + float2(1.0, 0.0));
	float v3 = hash12(i + float2(0.0, 1.0));
	float v4 = hash12(i + float2(1.0, 1.0));

	float2 a = f * f * f * (10.0 + f * (-15.0 + f * 6.0));

	return 2.0 * lerp(
		lerp(v1, v2, a.x),
		lerp(v3, v4, a.x),
		a.y
	) - 1.0;
}

float ValueNoise13(float3 src)
{
	float3 i = floor(src);
	float3 f = frac(src);

	float v1 = hash13(i + float3(0.0, 0.0, 0.0));
	float v2 = hash13(i + float3(1.0, 0.0, 0.0));
	float v3 = hash13(i + float3(0.0, 1.0, 0.0));
	float v4 = hash13(i + float3(1.0, 1.0, 0.0));
	float v5 = hash13(i + float3(0.0, 0.0, 1.0));
	float v6 = hash13(i + float3(1.0, 0.0, 1.0));
	float v7 = hash13(i + float3(0.0, 1.0, 1.0));
	float v8 = hash13(i + float3(1.0, 1.0, 1.0));

	float3 a = f * f * f * (10.0 + f * (-15.0 + f * 6.0));

	return 2.0 * lerp(
		lerp(lerp(v1, v2, a.x), lerp(v3, v4, a.x), a.y),
		lerp(lerp(v5, v6, a.x), lerp(v7, v8, a.x), a.y),
		a.z
	) - 1.0;
}

float3 ValueNoise33(float3 src) {
	float3 i = floor(src);
	float3 f = frac(src);

	float3 v1 = hash33(i + float3(0.0, 0.0, 0.0));
	float3 v2 = hash33(i + float3(1.0, 0.0, 0.0));
	float3 v3 = hash33(i + float3(0.0, 1.0, 0.0));
	float3 v4 = hash33(i + float3(1.0, 1.0, 0.0));
	float3 v5 = hash33(i + float3(0.0, 0.0, 1.0));
	float3 v6 = hash33(i + float3(1.0, 0.0, 1.0));
	float3 v7 = hash33(i + float3(0.0, 1.0, 1.0));
	float3 v8 = hash33(i + float3(1.0, 1.0, 1.0));

	float3 a = f * f * f * (10.0 + f * (-15.0 + f * 6.0));

	return 2.0 * lerp(
		lerp(lerp(v1, v2, a.x), lerp(v3, v4, a.x), a.y),
		lerp(lerp(v5, v6, a.x), lerp(v7, v8, a.x), a.y),
		a.z
	) - 1.0;
}

float FBM13(float3 src) {
	const float3x3 M = 2.0 * float3x3(
		 0.54030231,  0.45464871,  0.70807342,
		-0.84147098,  0.29192658,  0.45464871,
		 0.0       , -0.84147098,  0.54030231);
	float ret = 0.0;
	ret += 0.5000 * ValueNoise13(src); src = mul(M, src);
	ret += 0.2500 * ValueNoise13(src); src = mul(M, src);
	ret += 0.1250 * ValueNoise13(src); src = mul(M, src);
	ret += 0.0625 * ValueNoise13(src); src = mul(M, src);
	return ret * (1.0 / 0.9375);
}

//---------------------------------------------------------------------------------------------

float4 PerturbPosition(float4 pos) {
	float3 noise1 = ValueNoise33(pos.xyz * PerturbFrequency);
	float  noise2 = ValueNoise12(pos.xy  * PerturbFrequency);
	pos.xyz += noise1 * PerturbMaxWidth;
	pos.y *= lerp(YScalingMin, YScalingMax, noise2);
	return pos;
}

// ���_�V�F�[�_
void MainVS(
	in float4 pos : POSITION,
	in float3 normal : NORMAL,
	in float2 texCoord : TEXCOORD0,
	in uniform bool useTexture,
	in uniform bool selfShadow,
	out float4 oPos : POSITION,
	out float4 oLightClipPos : TEXCOORD0,
	out float2 oTexCoord : TEXCOORD1,
	out float3 oNormal : TEXCOORD2,
	out float3 oWorldPos : TEXCOORD3
) {
	pos = PerturbPosition(pos);

	// �J�������_�̃��[���h�r���[�ˉe�ϊ�
	oPos = mul(pos, WorldViewProjMatrix);

	// ���[���h���W
	oWorldPos = mul(pos, WorldMatrix).xyz;
	// ���_�@��
	oNormal = normalize(mul(normal, (float3x3)WorldMatrix));

	if (selfShadow) {
		// ���C�g���_�ɂ�郏�[���h�r���[�ˉe�ϊ�
		oLightClipPos = mul(pos, LightWorldViewProjMatrix);
	}

	// �e�N�X�`�����W
	oTexCoord = texCoord;
}

float3 CalculateLight(
	float4 lightClipPos,
	uniform bool selfShadow
) {
	if (!selfShadow) {
		return LightColor;
	}

	// �V���h�E�}�b�v�̍��W�ɕϊ�
	lightClipPos /= lightClipPos.w;
	float2 shadowMapCoord = float2(
		(1 + lightClipPos.x) * 0.5,
		(1 - lightClipPos.y) * 0.5);

	if (any(saturate(shadowMapCoord) != shadowMapCoord)) {
		return LightColor;
	}

	float lightDepth = max(lightClipPos.z - tex2D(ShadowBufferSampler, shadowMapCoord).r, 0);
	float comp;
	if (parthf) {
		// �Z���t�V���h�E mode2
		comp = 1 - saturate(lightDepth * SKII2 * shadowMapCoord.y - 0.3);
	} else {
		// �Z���t�V���h�E mode1
		comp = 1 - saturate(lightDepth * SKII1 - 0.3);
	}
	return lerp(0, LightColor, comp);
}

float3 Phong(
	float3 baseColor,
	float3 normal,
	float3 eye,
	float3 lightColor
) {
	// Blinn-Phong specular
	const float Z_P = (SpecularPower + 2.0) * (SpecularPower + 4.0)
					/ (8.0 * PI * (exp2(-0.5 * SpecularPower) + SpecularPower));
	float3 halfVector = normalize(eye + -LightDirection);
	float3 specular = Z_P * pow(max(0, dot(halfVector, normal)), SpecularPower) * MaterialSpecular;

	// Half Lambert diffuse
	const float Z_L = 3.0 / (4.0 * PI);
	float diffuseLight = dot(normal, -LightDirection) * 0.5 + 0.5;
	float3 diffuse = Z_L * diffuseLight * diffuseLight * baseColor;

	return (specular + diffuse) * lightColor + AmbientColor * baseColor;
}

float4 BaseColor(float2 tex, uniform bool useTexture)
{
	float4 baseColor = float4(MaterialAmbient, MaterialDiffuse.a);
	if (useTexture) {
		float4 texColor = tex2D(ObjectTextureSampler, tex);
		// �e�N�X�`���ގ����[�t
		texColor.rgb = lerp(
			1,
			texColor.rgb * TextureMulValue.rgb + TextureAddValue.rgb,
			TextureMulValue.a + TextureAddValue.a);
		baseColor *= texColor;
	}
	return baseColor;
}

float3 TangentNormalToWorldNormal(float3 tangentNormal, float3 normal, float3 pos, float2 uv) {
	float3 p1 = ddx(pos);
	float3 p2 = ddy(pos);
	float2 uv1 = ddx(uv);
	float2 uv2 = ddy(uv);

	// world��Ԃɂ�����u����v���̕��������߂�
	float3 u = normalize(uv2.y * p1 - uv1.y * p2);
	float3 v = normalize(uv1.x * p2 - uv2.x * p1);

	// u��v��normal��@���Ƃ��镽�ʂɎˉe���� tangent vector �� binormal vector �𓾂�
	float3 tangent  = normalize(u - dot(u, normal) * normal);
	float3 binormal = normalize(v - dot(v, normal) * normal);

	return normalize(tangentNormal.x * tangent + tangentNormal.y * binormal + tangentNormal.z * normal);
}

float3 RandomUnitVector(float3 p) {
	float r1 = FBM13(p);
	float r2 = FBM13(p + float3(42, 12, 91)) * TAU;
	float theta = acos(1 - r1 * NormalDistortionMaxAngle);
	float phi = r2;
	return float3(sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta));
}

// �s�N�Z���V�F�[�_
float4 MainPS(
	float4 lightClipPos : TEXCOORD0,
	float2 tex : TEXCOORD1,
	float3 normal : TEXCOORD2,
	float3 worldPos : TEXCOORD3,
	uniform bool useTexture,
	uniform bool selfShadow
) : COLOR0 {
	float3 tangentNormal = RandomUnitVector(worldPos * NormalDistortionFrequency);
	normal = TangentNormalToWorldNormal(tangentNormal, normal, worldPos, tex);

	float3 eye = normalize(CameraPosition - worldPos);

	float4 baseColor = BaseColor(tex, useTexture);
	float3 lightColor = CalculateLight(lightClipPos, selfShadow);
	return float4(
		Phong(baseColor.rgb, normal, eye, lightColor),
		baseColor.a);
}

//---------------------------------------------------------------------------------------------

#define MAIN_TEC(name, mmdpass, usetexture, selfshadow) \
	technique name < string MMDPass = mmdpass; bool UseTexture = usetexture; > { \
		pass DrawObject { \
			VertexShader = compile vs_3_0 MainVS(usetexture, selfshadow); \
			PixelShader  = compile ps_3_0 MainPS(usetexture, selfshadow); \
		} \
	}

MAIN_TEC(MainTec0, "object", false, false)
MAIN_TEC(MainTec1, "object", true, false)
MAIN_TEC(MainTecBS0, "object_ss", false, true)
MAIN_TEC(MainTecBS1, "object_ss", true, true)

//---------------------------------------------------------------------------------------------

void ZPlotVS(
	in float4 pos : POSITION,
	out float4 oPos : POSITION,
	out float4 oShadowMapTex : TEXCOORD0
) {
	pos = PerturbPosition(pos);

	// ���C�g�̖ڐ��ɂ�郏�[���h�r���[�ˉe�ϊ�������
	oPos = mul(pos, LightWorldViewProjMatrix);

	// �e�N�X�`�����W�𒸓_�ɍ��킹��
	oShadowMapTex = oPos;
}

// �s�N�Z���V�F�[�_
float4 ZPlotPS(
	in float4 shadowMapTex : TEXCOORD0
) : COLOR {
	// R�F������Z�l���L�^����
	return float4(shadowMapTex.z / shadowMapTex.w, 0, 0, 1);
}

// Z�l�v���b�g�p�e�N�j�b�N
technique ZPlotTec < string MMDPass = "zplot"; > {
	pass PlotZ {
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_3_0 ZPlotVS();
		PixelShader  = compile ps_3_0 ZPlotPS();
	}
}

//---------------------------------------------------------------------------------------------

// ���_�V�F�[�_
float4 PositionOnlyVS(float4 pos : POSITION) : POSITION
{
	pos = PerturbPosition(pos);

	// �J�������_�̃��[���h�r���[�ˉe�ϊ�
	return mul(pos, WorldViewProjMatrix);
}

// �s�N�Z���V�F�[�_
float4 SolidColorPS(uniform float4 color) : COLOR
{
	return color;
}

// �e�`��p�e�N�j�b�N
technique ShadowTec < string MMDPass = "shadow"; > {
	pass DrawShadow {
		VertexShader = compile vs_3_0 PositionOnlyVS();
		PixelShader  = compile ps_3_0 SolidColorPS(GroundShadowColor);
	}
}

// �֊s�`��p�e�N�j�b�N
technique EdgeTec < string MMDPass = "edge"; > {
	pass DrawEdge {
		VertexShader = compile vs_3_0 PositionOnlyVS();
		PixelShader  = compile ps_3_0 SolidColorPS(EdgeColor);
	}
}
