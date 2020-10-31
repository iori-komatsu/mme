//
// basic_fog: 単純なフォグエフェクト
//

// Si: フォグの濃さ
float Scale : CONTROLOBJECT < string name = "(self)"; string item = "Si"; >;

// X: フォグの色相 (0～1)
// Y: フォグの彩度 (0～1)
// Z: フォグの明度 (0～1; 大きいほど暗くなる)
float3 XYZ : CONTROLOBJECT < string name = "(self)"; string item = "XYZ"; >;

//-----------------------------------------------------------------------------

float3 HSVToRGB(float3 c)
{
	const float4 K = float4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
	float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

float3 SRGBToLinear(float3 rgb)
{
	const float ALPHA = 0.055f;
	return rgb < 0.04045f
		? rgb / 12.92f
		: pow((max(rgb, 1e-5) + ALPHA) / (1 + ALPHA), 2.4f);
}

float3 LinearToSRGB(float3 srgb)
{
	srgb = max(6.10352e-5, srgb);
	return min(
		srgb * 12.92,
		pow(max(srgb, 0.00313067), 1.0/2.4) * 1.055 - 0.055
	);
}

//-----------------------------------------------------------------------------

float Script : STANDARDSGLOBAL <
	string ScriptOutput = "color";
	string ScriptClass = "scene";
	string ScriptOrder = "postprocess";
> = 0.8;

texture DepthBuffer : RENDERDEPTHSTENCILTARGET <
	float2 ViewPortRatio = {1.0, 1.0};
>;
texture ScnMap : RENDERCOLORTARGET <
	float2 ViewPortRatio = {1.0, 1.0};
>;
sampler ScnSamp = sampler_state {
	texture = <ScnMap>;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = NONE;
	AddressU = CLAMP;
	AddressV = CLAMP;
};

texture DepthMap : OFFSCREENRENDERTARGET <
	string Description = "DepthMap for basic_fox.fx";
	float4 ClearColor = {0, 0, 0, 1};
	float ClearDepth = 1.0;
	string Format = "D3DFMT_R32F";
	bool AntiAlias = false;
	int MipLevels = 1;
	string DefaultEffect =
		"self = hide;"
		"* = depth.fxsub";
>;
sampler DepthSamp = sampler_state {
	texture = <DepthMap>;
	AddressU = CLAMP;
	AddressV = CLAMP;
	Filter = NONE;
};

float2 ViewportSize : VIEWPORTPIXELSIZE;
static float2 ViewportOffset = float2(0.5, 0.5) / ViewportSize;

static float  FogCoeff = 0.01 * Scale;
static float3 FogColor = HSVToRGB(saturate(float3(XYZ.xy, 1.0 - XYZ.z)));

//-----------------------------------------------------------------------------

void FogVS(
	in float4 pos : POSITION,
	in float4 tex : TEXCOORD0,
	out float4 oPos : POSITION,
	out float2 oTex : TEXCOORD0
) {
	oPos = pos;
	oTex = tex.xy + ViewportOffset;
}

float3 Fog(float3 c, float depth)
{
	float alpha = exp(-FogCoeff * depth);
	return lerp(FogColor, c, alpha);
}

float4 FogPS(in float2 coord : TEXCOORD0) : COLOR
{
	float depth = tex2D(DepthSamp, coord).r;
	float4 srgb = tex2D(ScnSamp, coord);
	float3 color = SRGBToLinear(srgb.rgb);
	float3 oColor = Fog(color, depth);
	return float4(LinearToSRGB(oColor), srgb.a);
}

//-----------------------------------------------------------------------------

float4 ClearColor = {1, 1, 1, 0};
float  ClearDepth = 1.0;

technique PostEffect <
	string Script =
		"RenderColorTarget0=ScnMap;"
		"RenderDepthStencilTarget=DepthBuffer;"
		"ClearSetColor=ClearColor;"
		"ClearSetDepth=ClearDepth;"
		"Clear=Color;"
		"Clear=Depth;"
		"ScriptExternal=Color;"
		"RenderColorTarget0=;"
		"RenderDepthStencilTarget=;"
		"Pass=DrawFog;"
	;
> {
	pass DrawFog < string Script= "Draw=Buffer;"; > {
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_3_0 FogVS();
		PixelShader  = compile ps_3_0 FogPS();
	}
}
