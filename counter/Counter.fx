float4x4 WorldViewProjMatrix      : WORLDVIEWPROJECTION;
float4x4 ViewProjMatrix           : VIEWPROJECTION;
float4x4 WorldMatrix              : WORLD;
float4x4 ViewMatrix               : VIEW;
float4x4 LightWorldViewProjMatrix : WORLDVIEWPROJECTION < string Object = "Light"; >;

float2 ViewportSize : VIEWPORTPIXELSIZE;
static const float2 ViewportOffset = float2(0.5, 0.5) / ViewportSize;

// �摜�o�͎��� ViewportSize ���ω�����̂ŁA�c�̕��� 1080 �ɌŒ肵�����z�I�� ViewportSize ��p����
static float2 VirtualViewportSize = float2(1080.0 * ViewportSize.x / ViewportSize.y, 1080);

//-----------------------------------------------------------------------------

float3 mCenter : CONTROLOBJECT<string name = "Counter.pmx"; string item = "Center";>;
float3 mSize   : CONTROLOBJECT<string name = "Counter.pmx"; string item = "Size";>;
float3 mCount  : CONTROLOBJECT<string name = "Counter.pmx"; string item = "Count";>;

static float Value = mCount.x;
static int Keta = int(log10(max(1.0, Value + 0.5))) + 1;
static int NumComma = (Keta - 1) / 3;

static float4 BackgroundColor = float4(0.9, 0.9, 0.9, 1.0);

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

static float2 DigitsTextureSizePx = float2(1100, 200);
static float2 DigitTexSizePx = float2(100, 200);
static float2 CommaTexSizePx = float2(67, 200);

static float FontSizePx = abs(mSize.y);
static float DigitWidthPx = FontSizePx * 0.5;
static float CommaWidthPx = DigitWidthPx * (CommaTexSizePx.x / DigitTexSizePx.x);
static float CharHeightPx = FontSizePx;

static float TextBoxWidthPx = DigitWidthPx * Keta + CommaWidthPx * NumComma;
static float TextBoxHeightPx = CharHeightPx;
static float2 TextBoxSizePx = float2(TextBoxWidthPx, TextBoxHeightPx);

static float PaddingLeftPx = 10;
static float PaddingRightPx = 10;

static float ContainerBoxWidthPx = TextBoxWidthPx + PaddingLeftPx + PaddingRightPx;
static float ContainerBoxHeightPx = TextBoxHeightPx;
static float2 ContainerBoxSizePx = float2(ContainerBoxWidthPx, ContainerBoxHeightPx);

static float PartWidthPx = DigitWidthPx * 3 + CommaWidthPx;

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
		ndcCenter - ContainerBoxSizePx * 0.5 / VirtualViewportSize,
		ndcCenter + ContainerBoxSizePx * 0.5 / VirtualViewportSize,
		coord
	);

	oPos = float4(ndcPos, 0.0, 1.0);
	oCoord = coord + ViewportOffset;
}

float Rand1D(float x)  {
	return frac(sin(x) * 43758.5453123);
}

float4 TextBox(float2 pixelPos) {
	float xr = TextBoxWidthPx - pixelPos.x;

	// �R���}�ŋ�؂�ꂽ��Ԃ��p�[�g�ƌĂԂ��Ƃɂ���B
	// pixelPos ���E���琔���ĉ��Ԗڂ̃p�[�g�ɂ��邩���ׂ�B
	float partIndex = floor(xr / PartWidthPx);
	float xpr = xr - partIndex * PartWidthPx; // �E���琔�����p�[�g���΍��W

	float d; // �\�����ׂ������܂��̓R���}
	float cw; // �\�����ׂ������̕�
	float cx; // �\�����ׂ��������̑��΍��W
	if (xpr >= 3 * DigitWidthPx) {
		// �R���}��\������
		d = 10;
		cw = CommaTexSizePx.x;
		cx = 1.0 - (xpr - 3 * DigitWidthPx) / CommaWidthPx;
	} else {
		int kr = partIndex * 3 + int(xpr / DigitWidthPx); // �E���琔���ĉ����ڂ�
		int kl = Keta - kr - 1; // �����琔���ĉ����ڂ�
		if (kl < 6) {
			// Value �� kr ���ڂ����o��
			d = int(clamp(fmod(Value, pow(10.0, kr+1)) / pow(10.0, kr), 0, 9.99));
		} else {
			// �����琔����7���ڈȍ~�͐��x������Ȃ��̂ŗ����Ŗ��߂�
			float e;
			d = int(clamp(Rand1D(frexp(Value, e) + kr) * 10, 0, 9.99));
		}
		cw = DigitTexSizePx.x;
		cx = 1.0 - fmod(xpr, DigitWidthPx) / DigitWidthPx;
	}

	// �e�N�X�`����̈ʒu���v�Z����
	float texLeft = DigitTexSizePx.x * d;
	float texRight = texLeft + cw;
	float2 uv = float2(
		lerp(texLeft, texRight, cx) / DigitsTextureSizePx.x,
		1.0 - pixelPos.y / TextBoxHeightPx);

	return tex2D(DigitsSamp, uv);
}

float4 PS(float2 coord : TEXCOORD0) : COLOR {
	float2 pixelPos = coord * ContainerBoxSizePx;
	float4 colorFG;
	if (pixelPos.x < PaddingLeftPx) {
		colorFG = BackgroundColor;
	} else if (pixelPos.x < PaddingLeftPx + TextBoxWidthPx) {
		colorFG = TextBox(pixelPos - float2(PaddingLeftPx, 0.0));
	} else {
		colorFG = BackgroundColor;
	}
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
