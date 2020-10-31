//
// phong: �t�H���̔��˃��f�����g�����V�F�[�f�B���O���s��
//

//----------------------------------------------------------------------------------------------

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
// ���C�g�F
float3   LightColor        : SPECULAR < string Object = "Light"; >;
static float3 AmbientColor = LightColor * 0.75;

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

//---------------------------------------------------------------------------------------------

// �V���h�E�o�b�t�@�̃T���v���B"register(s0)"�Ȃ̂�MMD��s0���g���Ă��邩��
sampler ShadowBufferSampler : register(s0);

// ���_�V�F�[�_
void BasicVS(
	in float4 pos : POSITION,
	in float3 normal : NORMAL,
	in float2 texCoord : TEXCOORD0,
	in uniform bool useTexture,
	in uniform bool selfShadow,
	out float4 oPos : POSITION,
	out float4 oLightClipPos : TEXCOORD0,
	out float2 oTexCoord : TEXCOORD1,
	out float3 oNormal : TEXCOORD2,
	out float3 oEye : TEXCOORD3
) {
    // �J�������_�̃��[���h�r���[�ˉe�ϊ�
    oPos = mul(pos, WorldViewProjMatrix);

    // �J�����Ƃ̑��Έʒu
    oEye = CameraPosition - mul(pos, WorldMatrix).rgb;
    // ���_�@��
    oNormal = normalize(mul(normal, (float3x3)WorldMatrix));

	if (selfShadow) {
		// ���C�g���_�ɂ�郏�[���h�r���[�ˉe�ϊ�
		oLightClipPos = mul(pos, LightWorldViewProjMatrix);
	}

    // �e�N�X�`�����W
    oTexCoord = texCoord;
}

float3 Phong(
	float3 baseColor,
	float3 normal,
	float3 eye,
	float3 lightColor
) {
    // Phong specular
    float3 halfVector = normalize(eye + -LightDirection);
    float3 specular = pow(max(0, dot(halfVector, normal)), SpecularPower) * MaterialSpecular;

    // Lambert diffuse
	float3 diffuse = max(0, dot(normal, -LightDirection)) * baseColor / PI;

	return (specular + diffuse) * lightColor + AmbientColor * baseColor;
}

// �s�N�Z���V�F�[�_
float4 BasicPS(
	float4 lightClipPos : TEXCOORD0,
	float2 tex : TEXCOORD1,
	float3 normal : TEXCOORD2,
	float3 eye : TEXCOORD3,
	uniform bool useTexture,
	uniform bool selfShadow
) : COLOR0 {
	normal = normalize(normal);
	eye = normalize(eye);

	float4 texColor = float4(1, 1, 1, 1);
    if (useTexture) {
        // �e�N�X�`���K�p
        texColor = tex2D(ObjectTextureSampler, tex);
        // �e�N�X�`���ގ����[�t��
	    texColor.rgb = lerp(1, texColor.rgb * TextureMulValue.rgb + TextureAddValue.rgb, TextureMulValue.a + TextureAddValue.a);
    }
	float3 baseColor = MaterialAmbient.rgb * texColor.rgb;

	float3 lightColor = LightColor;
	if (selfShadow) {
		// �V���h�E�}�b�v�̍��W�ɕϊ�
		lightClipPos /= lightClipPos.w;
		float2 shadowMapCoord = float2(
			(1 + lightClipPos.x) * 0.5,
			(1 - lightClipPos.y) * 0.5);

		if (any(saturate(shadowMapCoord) == shadowMapCoord)) {
			float lightDepth = max(lightClipPos.z - tex2D(ShadowBufferSampler, shadowMapCoord).r, 0);
			float comp;
			if (parthf) {
				// �Z���t�V���h�E mode2
				comp = 1 - saturate(lightDepth * SKII2 * shadowMapCoord.y - 0.3);
			} else {
				// �Z���t�V���h�E mode1
				comp = 1 - saturate(lightDepth * SKII1 - 0.3);
			}
			lightColor = lerp(0, LightColor, comp);
		}
	}

	return float4(
		Phong(baseColor.rgb, normal, eye, lightColor),
		transp ? 0.5 : MaterialDiffuse.a * texColor.a);
}

//---------------------------------------------------------------------------------------------

#define MAIN_TEC(name, mmdpass, usetexture, selfshadow) \
	technique name < string MMDPass = mmdpass; bool UseTexture = usetexture; > { \
		pass DrawObject { \
			VertexShader = compile vs_3_0 BasicVS(usetexture, selfshadow); \
			PixelShader  = compile ps_3_0 BasicPS(usetexture, selfshadow); \
		} \
	}

MAIN_TEC(MainTec0, "object", false, false)
MAIN_TEC(MainTec1, "object", true, false)
MAIN_TEC(MainTecBS0, "object_ss", false, true)
MAIN_TEC(MainTecBS1, "object_ss", true, true)