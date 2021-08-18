//
// gatagata: ���f�����K�^�K�^�ɂ��܂�
//

#include "sub/gatagata_ex.fxsub"
#include "sub/HitTexture.fxsub"

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
float3   LightDiffuse        : DIFFUSE < string Object = "Light"; >;
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

shared texture HitHistory1RT : RENDERCOLORTARGET;
sampler HitHistory1Sampler = sampler_state {
    Texture = (HitHistory1RT);
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
    MAGFILTER = NONE;
    MINFILTER = NONE;
    MIPFILTER = NONE;
};

//---------------------------------------------------------------------------------------------

float SampleHitState(float4 worldPos) {
	float2 uv = WorldPosToHitTexturePos(worldPos).xy;
	uv += HitTextureOffset;
	uv = float2(0.5 + 0.5 * uv.x, 0.5 - 0.5 * uv.y);
	return tex2Dlod(HitHistory1Sampler, float4(uv, 0, 0)).g;
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
	out float3 oWorldPos : TEXCOORD3,
	out float3 oModelPos : TEXCOORD4,
	out float  oHitState : TEXCOORD5
) {
	oHitState = SampleHitState(mul(pos, WorldMatrix));
	if (oHitState > 1e-8) {
		pos = PerturbPosition(pos);
	}

	oModelPos = pos.xyz;

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
	float3 lightColor,
	float3 ambientColor
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

	return (specular + diffuse) * lightColor + ambientColor * baseColor;
}

float4 BaseColor(float2 tex, uniform bool useTexture)
{
	float4 baseColor = float4(lerp(MaterialAmbient, MaterialDiffuse.rgb, LightDiffuse), MaterialDiffuse.a);
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

// �s�N�Z���V�F�[�_
float4 MainPS(
	float4 lightClipPos : TEXCOORD0,
	float2 tex : TEXCOORD1,
	float3 normal : TEXCOORD2,
	float3 worldPos : TEXCOORD3,
	float3 modelPos : TEXCOORD4,
	float  hitState : TEXCOORD5,
	uniform bool useTexture,
	uniform bool selfShadow
) : COLOR0 {
	float3 ambientColor = AmbientColor;
	if (hitState > 1e-8) {
		normal = DistortNormal(modelPos, worldPos, normal, tex);
		ambientColor *= 0.7;
	}

	float3 eye = normalize(CameraPosition - worldPos);

	float4 baseColor = BaseColor(tex, useTexture);
	float3 lightColor = CalculateLight(lightClipPos, selfShadow);
	return float4(
		Phong(baseColor.rgb, normal, eye, lightColor, ambientColor),
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
