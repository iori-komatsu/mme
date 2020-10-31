//
// grayscale: 画面全体をグレースケールにするポストエフェクト
//

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

float2 ViewportSize : VIEWPORTPIXELSIZE;
static float2 ViewportOffset = float2(0.5, 0.5) / ViewportSize;

//-----------------------------------------------------------------------------

void DrawBufferVS(
	in float4 Pos : POSITION,
	in float4 Tex : TEXCOORD0,
	out float4 oPos : POSITION,
	out float2 oTex : TEXCOORD0)
{
	oPos = Pos;
	oTex = Tex.xy + ViewportOffset;
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

float Grayscale(float3 c)
{
	return dot(float3(0.2126, 0.7152, 0.0722), c);
}

float4 DrawBufferPS(in float2 Tex: TEXCOORD0) : COLOR
{   
	float4 srgb = tex2D(ScnSamp, Tex);
	float3 color = SRGBToLinear(srgb.rgb);
	float gray = Grayscale(color);
	return float4(LinearToSRGB(float3(gray, gray, gray)), srgb.a);
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
		"Pass=DrawBuffer;"
	;
> {
	pass DrawBuffer < string Script= "Draw=Buffer;"; > {
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_3_0 DrawBufferVS();
		PixelShader  = compile ps_3_0 DrawBufferPS();
	}
}
