//
// grayscale_oklab: 画面全体をOklab色空間を使ってグレースケールにするポストエフェクト
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

// cf. https://bottosson.github.io/posts/oklab/
float3 LinearSRGBToOklab(float3 c)
{
	const float3x3 M1 = float3x3(
		0.4122214708f, 0.5363325363f, 0.0514459929f,
		0.2119034982f, 0.6806995451f, 0.1073969566f,
		0.0883024619f, 0.2817188376f, 0.6299787005f);
	const float3x3 M2 = float3x3(
		0.2104542553f,  0.7936177850f, -0.0040720468f,
		1.9779984951f, -2.4285922050f,  0.4505937099f,
		0.0259040371f,  0.7827717662f, -0.8086757660f);
	float3 v = mul(M1, c);
	v = pow(v, 1.0/3.0);
	return mul(M2, v);
}

// cf. https://bottosson.github.io/posts/oklab/
float3 OklabToLinearSRGB(float3 c)
{
	const float3x3 M1 = float3x3(
		1.0,  0.3963377774f,  0.2158037573f,
		1.0, -0.1055613458f, -0.0638541728f,
		1.0, -0.0894841775f, -1.2914855480f);
	const float3x3 M2 = float3x3(
		 4.0767416621f, -3.3077115913f,  0.2309699292f,
		-1.2684380046f,  2.6097574011f, -0.3413193965f,
		-0.0041960863f, -0.7034186147f,  1.7076147010f);
	float3 v = mul(M1, c);
	v = v*v*v;
	return mul(M2, v);
}

float3 Grayscale(float3 c)
{
	float3 oklab = LinearSRGBToOklab(c);
	oklab.yz = float2(0, 0);
	return OklabToLinearSRGB(oklab);
}

float4 DrawBufferPS(in float2 Tex: TEXCOORD0) : COLOR
{
	float4 srgb = tex2D(ScnSamp, Tex);
	float3 color = SRGBToLinear(srgb.rgb);
	float3 gray = Grayscale(color);
	return float4(LinearToSRGB(gray), srgb.a);
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
