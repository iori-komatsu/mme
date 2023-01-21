float4x4 WorldViewProjMatrix      : WORLDVIEWPROJECTION;
float4x4 ViewProjMatrix           : VIEWPROJECTION;
float4x4 WorldMatrix              : WORLD;
float4x4 ViewMatrix               : VIEW;
float4x4 LightWorldViewProjMatrix : WORLDVIEWPROJECTION < string Object = "Light"; >;

float2 ViewportSize : VIEWPORTPIXELSIZE;
static const float2 ViewportOffset = float2(0.5, 0.5) / ViewportSize;

//-----------------------------------------------------------------------------

float3 mCenter : CONTROLOBJECT<string name = "Counter.pmx"; string item = "Center";>;
float3 mSize   : CONTROLOBJECT<string name = "Counter.pmx"; string item = "Size";>;
float3 mCount  : CONTROLOBJECT<string name = "Counter.pmx"; string item = "Count";>;

static const float FontSizePx = abs(mSize.y);
static const float CharWidthPx = FontSizePx * 0.5;
static const float CharHeightPx = FontSizePx;

static const float  Value = mCount.x;

static int Keta = int(log10(max(1.0, Value + 0.5))) + 1;
static int NumComma = (Keta - 1) / 3;
static int KetaWithComma = Keta + NumComma;
static float TextBoxWidthPx = CharWidthPx * KetaWithComma;
static float TextBoxHeightPx = CharHeightPx;
static float2 TextBoxSizePx = float2(TextBoxWidthPx, TextBoxHeightPx);

static const float4 BackgroundColor = float4(0.9, 0.9, 0.9, 1.0);

//-----------------------------------------------------------------------------

texture2D DigitsTexture <
    string ResourceName = "digits.png";
	string Format = "D3DFMT_A16B16G16R16F";
>;
sampler2D DigitsSamp = sampler_state {
    Texture = <DigitsTexture>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

static const float2 DigitsTextureSize = float2(1100, 200);
static float2 OneDigitSize = float2(100, 200) / DigitsTextureSize;

//-----------------------------------------------------------------------------

void VS(
	float4 pos : POSITION,
	float2 coord : TEXCOORD0,
	out float4 oPos : POSITION,
	out float2 oCoord : TEXCOORD0
) {
	float4 clipCenter = mul(float4(mCenter, 1.0), ViewProjMatrix);
	float2 ndcCenter = clipCenter.xy / clipCenter.w;
	float2 ndcPos = lerp(
		ndcCenter - TextBoxSizePx * 0.5 / ViewportSize,
		ndcCenter + TextBoxSizePx * 0.5 / ViewportSize,
		coord
	);

	oPos = float4(ndcPos, 0.0, 1.0);
	oCoord = coord + ViewportOffset;
}

float Rand1D(float x)  { return frac(sin(x) * 43758.5453123); }

float4 PS(float2 coord : TEXCOORD0) : COLOR {
	float2 pixelPos = coord * TextBoxSizePx;
	// �����琔���ĉ����ڂ� (�R���}�܂�)
	int il = int(pixelPos.x / CharWidthPx);
	if (il >= KetaWithComma) {
		clip(-1);
	}
	// �E���琔���ĉ����ڂ� (�R���}�܂�)
	int ir = KetaWithComma - il - 1;
	// �\�����ׂ�����
	int d;
	if (ir % 4 == 3) {
		d = 10; // �R���}��\������
	} else {
		int numCommaRight = (ir + 1) / 4; // �E�ɂ���R���}�̐�
		int kr = ir - numCommaRight; // �E���琔���ĉ����ڂ� (�R���}�܂܂�)
		int kl = Keta - kr - 1;      // �����琔���ĉ����ڂ� (�R���}�܂܂�)
		if (kl < 6) {
			// Value �� kr ���ڂ����o��
			d = int(clamp(fmod(Value, pow(10.0, kr+1)) / pow(10.0, kr), 0, 9.99));
		} else {
			// �����琔����7���ڈȍ~�͐��x������Ȃ��̂ŗ����Ŗ��߂�
			float e;
			d = int(clamp(Rand1D(frexp(Value, e) + kr) * 10, 0, 9.99));
		}
	}

	float texLeft = OneDigitSize.x * d;
	float texRight = OneDigitSize.x * (d + 1);
	float2 uv = float2(
		lerp(texLeft, texRight, frac(pixelPos.x / CharWidthPx)),
		1.0 - coord.y);

	float4 colorFG = tex2D(DigitsSamp, uv);
    return float4(lerp(BackgroundColor.rgb, colorFG.rgb, colorFG.a), 1.0);
}

//-----------------------------------------------------------------------------

#define MAIN_TEC(name, mmdpass) \
	technique name < string MMDPass = mmdpass; > { \
		pass DrawObject { \
			VertexShader = compile vs_3_0 VS(); \
			PixelShader  = compile ps_3_0 PS(); \
		} \
	}

MAIN_TEC(MainTec, "object")
MAIN_TEC(MainTecBS, "object_ss")

technique EdgeTec < string MMDPass = "edge"; > {
    // �`�悵�Ȃ�
}

technique ShadowTec < string MMDPass = "shadow"; > {
    // �`�悵�Ȃ�
}
