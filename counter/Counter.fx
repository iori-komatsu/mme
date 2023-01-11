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

static const float2 NDCSize = abs(mSize.xy / ViewportSize);
static const float2 PxSize = abs(mSize.xy);
static const float  Value = mCount.x;

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
		ndcCenter - NDCSize * 0.5,
		ndcCenter + NDCSize * 0.5,
		coord
	);

	oPos = float4(ndcPos, 0.0, 1.0);
	oCoord = coord;
}

float4 PS(float2 coord : TEXCOORD0) : COLOR {
	int keta = int(log10(max(1.0, Value))) + 1;
	float2 pixelPos = coord * PxSize;
	int i = int(pixelPos.x / PxSize.y);
	if (i >= keta) {
		return float4(0, 0, 0, 0);
	}
	int k = keta - i - 1;
	float d = fmod(floor(Value / pow(10.0, k)), 10);
    return float4(d/9, d/9, d/9, 1.0);
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
    // •`‰æ‚µ‚È‚¢
}

technique ShadowTec < string MMDPass = "shadow"; > {
    // •`‰æ‚µ‚È‚¢
}
