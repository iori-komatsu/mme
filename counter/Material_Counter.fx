#include "CounterCommon.fxsub"

#define ALBEDO_MAP_FROM 3
#define ALBEDO_MAP_UV_FLIP 0
#define ALBEDO_MAP_APPLY_SCALE 0
#define ALBEDO_MAP_APPLY_DIFFUSE 1
#define ALBEDO_MAP_APPLY_MORPH_COLOR 0
#define ALBEDO_MAP_FILE "albedo.png"

const float3 albedo = 1.0;
const float2 albedoMapLoopNum = 1.0;

#define ALBEDO_SUB_ENABLE 0
#define ALBEDO_SUB_MAP_FROM 0
#define ALBEDO_SUB_MAP_UV_FLIP 0
#define ALBEDO_SUB_MAP_APPLY_SCALE 0
#define ALBEDO_SUB_MAP_FILE "albedo.png"

const float3 albedoSub = 1.0;
const float2 albedoSubMapLoopNum = 1.0;

#define ALPHA_MAP_FROM 3
#define ALPHA_MAP_UV_FLIP 0
#define ALPHA_MAP_SWIZZLE 3
#define ALPHA_MAP_FILE "alpha.png"

const float alpha = 1.0;
const float alphaMapLoopNum = 1.0;

#define NORMAL_MAP_FROM 0
#define NORMAL_MAP_TYPE 0
#define NORMAL_MAP_UV_FLIP 0
#define NORMAL_MAP_FILE "normal.png"

const float normalMapScale = 1.0;
const float normalMapLoopNum = 1.0;

#define NORMAL_SUB_MAP_FROM 0
#define NORMAL_SUB_MAP_TYPE 0
#define NORMAL_SUB_MAP_UV_FLIP 0
#define NORMAL_SUB_MAP_FILE "normal.png"

const float normalSubMapScale = 1.0;
const float normalSubMapLoopNum = 1.0;

#define SMOOTHNESS_MAP_FROM 0
#define SMOOTHNESS_MAP_TYPE 0
#define SMOOTHNESS_MAP_UV_FLIP 0
#define SMOOTHNESS_MAP_SWIZZLE 0
#define SMOOTHNESS_MAP_APPLY_SCALE 0
#define SMOOTHNESS_MAP_FILE "smoothness.png"

const float smoothness = 0.0;
const float smoothnessMapLoopNum = 1.0;

#define METALNESS_MAP_FROM 0
#define METALNESS_MAP_UV_FLIP 0
#define METALNESS_MAP_SWIZZLE 0
#define METALNESS_MAP_APPLY_SCALE 0
#define METALNESS_MAP_FILE "metalness.png"

const float metalness = 0.0;
const float metalnessMapLoopNum = 1.0;

#define SPECULAR_MAP_FROM 0
#define SPECULAR_MAP_TYPE 0
#define SPECULAR_MAP_UV_FLIP 0
#define SPECULAR_MAP_SWIZZLE 0
#define SPECULAR_MAP_APPLY_SCALE 0
#define SPECULAR_MAP_FILE "specular.png"

const float3 specular = 0.5;
const float2 specularMapLoopNum = 1.0;

#define OCCLUSION_MAP_FROM 0
#define OCCLUSION_MAP_TYPE 0
#define OCCLUSION_MAP_UV_FLIP 0
#define OCCLUSION_MAP_SWIZZLE 0
#define OCCLUSION_MAP_APPLY_SCALE 0
#define OCCLUSION_MAP_FILE "occlusion.png"

const float occlusion = 1.0;
const float occlusionMapLoopNum = 1.0;

#define PARALLAX_MAP_FROM 0
#define PARALLAX_MAP_TYPE 0
#define PARALLAX_MAP_UV_FLIP 0
#define PARALLAX_MAP_SWIZZLE 0
#define PARALLAX_MAP_FILE "height.png"

const float parallaxMapScale = 1.0;
const float parallaxMapLoopNum = 1.0;

#define EMISSIVE_ENABLE 0
#define EMISSIVE_MAP_FROM 0
#define EMISSIVE_MAP_UV_FLIP 0
#define EMISSIVE_MAP_APPLY_SCALE 0
#define EMISSIVE_MAP_APPLY_MORPH_COLOR 0
#define EMISSIVE_MAP_APPLY_MORPH_INTENSITY 0
#define EMISSIVE_MAP_APPLY_BLINK 0
#define EMISSIVE_MAP_FILE "emissive.png"

const float3 emissive = 0.0;
const float3 emissiveBlink = 1.0;
const float  emissiveIntensity = 1.0;
const float2 emissiveMapLoopNum = 1.0;

#define CUSTOM_ENABLE 0

#define CUSTOM_A_MAP_FROM 0
#define CUSTOM_A_MAP_UV_FLIP 0
#define CUSTOM_A_MAP_COLOR_FLIP 0
#define CUSTOM_A_MAP_SWIZZLE 0
#define CUSTOM_A_MAP_APPLY_SCALE 0
#define CUSTOM_A_MAP_FILE "custom.png"

const float customA = 0.0;
const float customAMapLoopNum = 1.0;

#define CUSTOM_B_MAP_FROM 0
#define CUSTOM_B_MAP_UV_FLIP 0
#define CUSTOM_B_MAP_COLOR_FLIP 0
#define CUSTOM_B_MAP_APPLY_SCALE 0
#define CUSTOM_B_MAP_FILE "custom.png"

//-----------------------------------------------------------------------------------------

const float3 customB = 0.0;
const float2 customBMapLoopNum = 1.0;
sampler MMDSamp0 : register(s0);
sampler MMDSamp1 : register(s1);
sampler MMDSamp2 : register(s2);

float4x4 matView : VIEW;
float4x4 matWorld : WORLD;
float4x4 matWorldView : WORLDVIEW;
float4x4 matWorldViewProject : WORLDVIEWPROJECTION;

float4 MaterialDiffuse : DIFFUSE<string Object = "Geometry";>;
float4 MaterialAmbient : EMISSIVE<string Object = "Geometry";>;
float4 MaterialSpecular : SPECULAR<string Object = "Geometry";>;
float  MaterialPower : SPECULARPOWER<string Object = "Geometry";>;

float time : TIME;

// {{{ fracture.fx
#ifdef FRACTURING_ENABLED
float3 CameraPosition  : POSITION<string Object = "Camera";>;
#endif
// }}}

bool use_texture;
bool use_subtexture;
bool use_spheremap;
bool use_toon;

#if EMISSIVE_MAP_APPLY_MORPH_COLOR || ALBEDO_MAP_APPLY_MORPH_COLOR
float MorphRed   : CONTROLOBJECT<string name="(self)"; string item = "R+";>;
float MorphGreen : CONTROLOBJECT<string name="(self)"; string item = "G+";>;
float MorphBlue  : CONTROLOBJECT<string name="(self)"; string item = "B+";>;

static float3 MorphColor = float3(MorphRed, MorphGreen, MorphBlue);
#endif

#if EMISSIVE_MAP_APPLY_BLINK
float3 SmoothCurve(float3 x)
{
	return x * x * (3.0 - 2.0 * x);
}

float3 TriangleWave(float3 x)
{
	return abs(frac(x + 0.5) * 2.0 - 1.0);
}

float3 SmoothTriangleWave(float3 x)
{
	return SmoothCurve(TriangleWave(x));
}

#if EMISSIVE_MAP_APPLY_BLINK == 2
	float mBlink : CONTROLOBJECT<string name="(self)"; string item = "Blink";>;
	static float3 LightBlink = saturate(1 - SmoothTriangleWave(time * emissiveBlink * mBlink));
#else
	static float3 LightBlink = saturate(1 - SmoothTriangleWave(time * emissiveBlink));
#endif
#endif

#if EMISSIVE_MAP_APPLY_MORPH_INTENSITY
float mIntensityP : CONTROLOBJECT<string name="(self)"; string item = "Intensity+";>;
float mIntensityM : CONTROLOBJECT<string name="(self)"; string item = "Intensity-";>;

static float emissiveIntensityMin = log(50);
static float emissiveIntensityMax = log(2100);
static float LightIntensity = lerp(emissiveIntensityMin, emissiveIntensityMax, mIntensityP - mIntensityM);
#endif

#define TEXTURE_FILTER ANISOTROPIC
#define TEXTURE_MIP_FILTER ANISOTROPIC
#define TEXTURE_ANISOTROPY_LEVEL 16

#define SHADINGMODELID_DEFAULT    0
#define SHADINGMODELID_SKIN       1
#define SHADINGMODELID_EMISSIVE   2
#define SHADINGMODELID_ANISOTROPY 3
#define SHADINGMODELID_GLASS      4
#define SHADINGMODELID_CLOTH      5
#define SHADINGMODELID_CLEAR_COAT 6
#define SHADINGMODELID_SUBSURFACE 7
#define SHADINGMODELID_CEL        8
#define SHADINGMODELID_TONEBASED  9
#define SHADINGMODELID_MASK       10

#define MIDPOINT_8_BIT (127.0f / 255.0f)
#define MAX_FRACTIONAL_8_BIT (255.0f / 256.0f)
#define TWO_BITS_EXTRACTION_FACTOR (3.0f + MAX_FRACTIONAL_8_BIT)
#define EMISSIVE_EPSILON (2.0f / 255.0f)

#define ALPHA_THRESHOLD 0.999

shared texture Gbuffer2RT: RENDERCOLORTARGET;
shared texture Gbuffer3RT: RENDERCOLORTARGET;
shared texture Gbuffer4RT: RENDERCOLORTARGET;
shared texture Gbuffer5RT: RENDERCOLORTARGET;
shared texture Gbuffer6RT: RENDERCOLORTARGET;
shared texture Gbuffer7RT: RENDERCOLORTARGET;
shared texture Gbuffer8RT: RENDERCOLORTARGET;

#if ALBEDO_MAP_FROM == 3 || ALBEDO_SUB_MAP_FROM == 3 || ALPHA_MAP_FROM == 3 ||\
	NORMAL_MAP_FROM == 3|| NORMAL_SUB_MAP_FROM == 3||\
	SMOOTHNESS_MAP_FROM == 3 || METALNESS_MAP_FROM == 3 || SPECULAR_MAP_FROM == 3||\
	EMISSIVE_MAP_FROM == 3 || OCCLUSION_MAP_FROM == 3 ||\
	PARALLAX_MAP_FROM == 3|| CUSTOM_A_MAP_FROM == 3|| CUSTOM_B_MAP_FROM == 3
	texture DiffuseMap: MATERIALTEXTURE;
#endif

#if ALBEDO_MAP_FROM == 4 || ALBEDO_SUB_MAP_FROM == 4  || ALPHA_MAP_FROM == 4 ||\
	NORMAL_MAP_FROM == 4|| NORMAL_SUB_MAP_FROM == 4||\
	SMOOTHNESS_MAP_FROM == 4 || METALNESS_MAP_FROM == 4 || SPECULAR_MAP_FROM == 4||\
	EMISSIVE_MAP_FROM == 4 || OCCLUSION_MAP_FROM == 4 ||\
	PARALLAX_MAP_FROM == 4|| CUSTOM_A_MAP_FROM == 4|| CUSTOM_B_MAP_FROM == 4
	texture SphereMap : MATERIALSPHEREMAP;
#endif

#if ALBEDO_MAP_FROM == 5 || ALBEDO_SUB_MAP_FROM == 5 || ALPHA_MAP_FROM == 5 ||\
	NORMAL_MAP_FROM == 5|| NORMAL_SUB_MAP_FROM == 5||\
	SMOOTHNESS_MAP_FROM == 5 || METALNESS_MAP_FROM == 5 || SPECULAR_MAP_FROM == 5||\
	EMISSIVE_MAP_FROM == 5 || OCCLUSION_MAP_FROM == 5 ||\
	PARALLAX_MAP_FROM == 5|| CUSTOM_A_MAP_FROM == 5|| CUSTOM_B_MAP_FROM == 5
	texture ToonMap : MATERIALTOONTEXTURE;
#endif

#if ALBEDO_MAP_FROM == 6 || ALBEDO_SUB_MAP_FROM == 6 || ALPHA_MAP_FROM == 6 ||\
	NORMAL_MAP_FROM == 6|| NORMAL_SUB_MAP_FROM == 6||\
	SMOOTHNESS_MAP_FROM == 6 || METALNESS_MAP_FROM == 6 || SPECULAR_MAP_FROM == 6||\
	EMISSIVE_MAP_FROM == 6 || OCCLUSION_MAP_FROM == 6 ||\
	PARALLAX_MAP_FROM == 6|| CUSTOM_A_MAP_FROM == 6|| CUSTOM_B_MAP_FROM == 6
	shared texture2D DummyScreenTex : RENDERCOLORTARGET;
#endif

#if ALBEDO_MAP_FROM >= 1 && ALBEDO_MAP_FROM <= 8
	#if ALBEDO_MAP_FROM == 1
		texture AlbedoMap<string ResourceName = ALBEDO_MAP_FILE;>;
	#elif ALBEDO_MAP_FROM == 2
		texture AlbedoMap : ANIMATEDTEXTURE<string ResourceName = ALBEDO_MAP_FILE;>;
	#endif
	sampler AlbedoMapSamp = sampler_state
	{
#if ALBEDO_MAP_FROM == 3 || ALBEDO_MAP_FROM == 7 || ALBEDO_MAP_FROM == 8
		texture = DiffuseMap;
#elif ALBEDO_MAP_FROM == 4
		texture = SphereMap;
#elif ALBEDO_MAP_FROM == 5
		texture = ToonMap;
#elif ALBEDO_MAP_FROM == 6
		texture = DummyScreenTex;
#else
		texture = AlbedoMap;
#endif
		MAXANISOTROPY = TEXTURE_ANISOTROPY_LEVEL;
		MINFILTER = TEXTURE_FILTER; MAGFILTER = TEXTURE_FILTER; MIPFILTER = TEXTURE_MIP_FILTER;
		ADDRESSU = WRAP; ADDRESSV = WRAP;
	};
#endif

#if ALBEDO_SUB_MAP_FROM >= 1 && ALBEDO_SUB_MAP_FROM <= 6
	#if ALBEDO_SUB_MAP_FROM == 1
		texture AlbedoSubMap<string ResourceName = ALBEDO_SUB_MAP_FILE;>;
	#elif ALBEDO_SUB_MAP_FROM == 2
		texture AlbedoSubMap : ANIMATEDTEXTURE<string ResourceName = ALBEDO_SUB_MAP_FILE;>;
	#endif
	sampler AlbedoSubMapSamp = sampler_state
	{
#if ALBEDO_SUB_MAP_FROM == 3
		texture = DiffuseMap;
#elif ALBEDO_SUB_MAP_FROM == 4
		texture = SphereMap;
#elif ALBEDO_SUB_MAP_FROM == 5
		texture = ToonMap;
#elif ALBEDO_SUB_MAP_FROM == 6
		texture = DummyScreenTex;
#else
		texture = AlbedoSubMap;
#endif
		MAXANISOTROPY = TEXTURE_ANISOTROPY_LEVEL;
		MINFILTER = TEXTURE_FILTER; MAGFILTER = TEXTURE_FILTER; MIPFILTER = TEXTURE_MIP_FILTER;
		ADDRESSU = WRAP; ADDRESSV = WRAP;
	};
#endif

#if ALPHA_MAP_FROM >= 1 && ALPHA_MAP_FROM <= 6
	#if ALPHA_MAP_FROM == 1
		texture AlphaMap<string ResourceName = ALPHA_MAP_FILE;>;
	#elif ALPHA_MAP_FROM == 2
		texture AlphaMap : ANIMATEDTEXTURE<string ResourceName = ALPHA_MAP_FILE;>;
	#endif
	sampler AlphaMapSamp = sampler_state
	{
#if ALPHA_MAP_FROM == 3
		texture = DiffuseMap;
#elif ALPHA_MAP_FROM == 4
		texture = SphereMap;
#elif ALPHA_MAP_FROM == 5
		texture = ToonMap;
#elif ALPHA_MAP_FROM == 6
		texture = DummyScreenTex;
#else
		texture = AlphaMap;
#endif
		MAXANISOTROPY = TEXTURE_ANISOTROPY_LEVEL;
		MINFILTER = TEXTURE_FILTER; MAGFILTER = TEXTURE_FILTER; MIPFILTER = TEXTURE_MIP_FILTER;
		ADDRESSU = WRAP; ADDRESSV = WRAP;
	};
#endif

#if NORMAL_MAP_FROM >= 1 && NORMAL_MAP_FROM <= 6
	#if NORMAL_MAP_FROM == 1
		texture NormalMap<string ResourceName = NORMAL_MAP_FILE;>;
	#elif NORMAL_MAP_FROM == 2
		texture NormalMap : ANIMATEDTEXTURE<string ResourceName = NORMAL_MAP_FILE;>;
	#endif
	sampler NormalMapSamp = sampler_state
	{
#if NORMAL_MAP_FROM == 3
		texture = DiffuseMap;
#elif NORMAL_MAP_FROM == 4
		texture = SphereMap;
#elif NORMAL_MAP_FROM == 5
		texture = ToonMap;
#elif NORMAL_MAP_FROM == 6
		texture = DummyScreenTex;
#else
		texture = NormalMap;
#endif
		MAXANISOTROPY = TEXTURE_ANISOTROPY_LEVEL;
		MINFILTER = TEXTURE_FILTER; MAGFILTER = TEXTURE_FILTER; MIPFILTER = TEXTURE_MIP_FILTER;
		ADDRESSU = WRAP; ADDRESSV = WRAP;
	};
#endif

#if NORMAL_SUB_MAP_FROM >= 1 && NORMAL_SUB_MAP_FROM <= 6
	#if NORMAL_SUB_MAP_FROM == 1
		texture NormalSubMap<string ResourceName = NORMAL_SUB_MAP_FILE;>;
	#elif NORMAL_SUB_MAP_FROM == 2
		texture NormalSubMap : ANIMATEDTEXTURE<string ResourceName = NORMAL_SUB_MAP_FILE;>;
	#endif
	sampler NormalSubMapSamp = sampler_state
	{
#if NORMAL_SUB_MAP_FROM == 3
		texture = DiffuseMap;
#elif NORMAL_SUB_MAP_FROM == 4
		texture = SphereMap;
#elif NORMAL_SUB_MAP_FROM == 5
		texture = ToonMap;
#elif NORMAL_SUB_MAP_FROM == 6
		texture = DummyScreenTex;
#else
		texture = NormalSubMap;
#endif
		MAXANISOTROPY = TEXTURE_ANISOTROPY_LEVEL;
		MINFILTER = TEXTURE_FILTER; MAGFILTER = TEXTURE_FILTER; MIPFILTER = TEXTURE_MIP_FILTER;
		ADDRESSU = WRAP; ADDRESSV = WRAP;
	};
#endif

#if SMOOTHNESS_MAP_FROM >= 1 && SMOOTHNESS_MAP_FROM <= 6
	#if SMOOTHNESS_MAP_FROM == 1
		texture SmoothnessMap<string ResourceName = SMOOTHNESS_MAP_FILE;>;
	#elif SMOOTHNESS_MAP_FROM == 2
		texture SmoothnessMap : ANIMATEDTEXTURE<string ResourceName = SMOOTHNESS_MAP_FILE;>;
	#endif
	sampler SmoothnessMapSamp = sampler_state
	{
#if SMOOTHNESS_MAP_FROM == 3
		texture = DiffuseMap;
#elif SMOOTHNESS_MAP_FROM == 4
		texture = SphereMap;
#elif SMOOTHNESS_MAP_FROM == 5
		texture = ToonMap;
#elif SMOOTHNESS_MAP_FROM == 6
		texture = DummyScreenTex;
#else
		texture = SmoothnessMap;
#endif
		MAXANISOTROPY = TEXTURE_ANISOTROPY_LEVEL;
		MINFILTER = TEXTURE_FILTER; MAGFILTER = TEXTURE_FILTER; MIPFILTER = TEXTURE_MIP_FILTER;
		ADDRESSU = WRAP; ADDRESSV = WRAP;
	};
#endif

#if METALNESS_MAP_FROM >= 1 && METALNESS_MAP_FROM <= 6
	#if METALNESS_MAP_FROM == 1
		texture MetalnessMap<string ResourceName = METALNESS_MAP_FILE;>;
	#elif METALNESS_MAP_FROM == 2
		texture MetalnessMap : ANIMATEDTEXTURE<string ResourceName = METALNESS_MAP_FILE;>;
	#endif
	sampler MetalnessMapSamp = sampler_state
	{
#if METALNESS_MAP_FROM == 3
		texture = DiffuseMap;
#elif METALNESS_MAP_FROM == 4
		texture = SphereMap;
#elif METALNESS_MAP_FROM == 5
		texture = ToonMap;
#elif METALNESS_MAP_FROM == 6
		texture = DummyScreenTex;
#else
		texture = MetalnessMap;
#endif
		MAXANISOTROPY = TEXTURE_ANISOTROPY_LEVEL;
		MINFILTER = TEXTURE_FILTER; MAGFILTER = TEXTURE_FILTER; MIPFILTER = TEXTURE_MIP_FILTER;
		ADDRESSU = WRAP; ADDRESSV = WRAP;
	};
#endif

#if SPECULAR_MAP_FROM >= 1 && SPECULAR_MAP_FROM <= 6
	#if SPECULAR_MAP_FROM == 1
		texture SpecularMap<string ResourceName = SPECULAR_MAP_FILE;>;
	#elif SPECULAR_MAP_FROM == 2
		texture SpecularMap : ANIMATEDTEXTURE<string ResourceName = SPECULAR_MAP_FILE;>;
	#endif
	sampler SpecularMapSamp = sampler_state
	{
#if SPECULAR_MAP_FROM == 3
		texture = DiffuseMap;
#elif SPECULAR_MAP_FROM == 4
		texture = SphereMap;
#elif SPECULAR_MAP_FROM == 5
		texture = ToonMap;
#elif SPECULAR_MAP_FROM == 6
		texture = DummyScreenTex;
#else
		texture = SpecularMap;
#endif
		MAXANISOTROPY = TEXTURE_ANISOTROPY_LEVEL;
		MINFILTER = TEXTURE_FILTER; MAGFILTER = TEXTURE_FILTER; MIPFILTER = TEXTURE_MIP_FILTER;
		ADDRESSU = WRAP; ADDRESSV = WRAP;
	};
#endif

#if OCCLUSION_MAP_FROM >= 1 && OCCLUSION_MAP_FROM <= 6
	#if OCCLUSION_MAP_FROM == 1
		texture OcclusionMap<string ResourceName = OCCLUSION_MAP_FILE;>;
	#elif OCCLUSION_MAP_FROM == 2
		texture OcclusionMap : ANIMATEDTEXTURE<string ResourceName = OCCLUSION_MAP_FILE;>;
	#endif
	sampler OcclusionMapSamp = sampler_state
	{
#if OCCLUSION_MAP_FROM == 3
		texture = DiffuseMap;
#elif OCCLUSION_MAP_FROM == 4
		texture = SphereMap;
#elif OCCLUSION_MAP_FROM == 5
		texture = ToonMap;
#elif OCCLUSION_MAP_FROM == 6
		texture = DummyScreenTex;
#else
		texture = OcclusionMap;
#endif
		MAXANISOTROPY = TEXTURE_ANISOTROPY_LEVEL;
		MINFILTER = TEXTURE_FILTER; MAGFILTER = TEXTURE_FILTER; MIPFILTER = TEXTURE_MIP_FILTER;
		ADDRESSU = WRAP; ADDRESSV = WRAP;
	};
#endif

#if PARALLAX_MAP_FROM >= 1 && PARALLAX_MAP_FROM <= 6
	#if PARALLAX_MAP_FROM == 1
		texture ParallaxMap<string ResourceName = PARALLAX_MAP_FILE;>;
	#elif PARALLAX_MAP_FROM == 2
		texture ParallaxMap : ANIMATEDTEXTURE<string ResourceName = PARALLAX_MAP_FILE;>;
	#endif
	sampler ParallaxMapSamp = sampler_state
	{
#if PARALLAX_MAP_FROM == 3
		texture = DiffuseMap;
#elif PARALLAX_MAP_FROM == 4
		texture = SphereMap;
#elif PARALLAX_MAP_FROM == 5
		texture = ToonMap;
#elif PARALLAX_MAP_FROM == 6
		texture = DummyScreenTex;
#else
		texture = ParallaxMap;
#endif
		MAXANISOTROPY = TEXTURE_ANISOTROPY_LEVEL;
		MINFILTER = TEXTURE_FILTER; MAGFILTER = TEXTURE_FILTER; MIPFILTER = TEXTURE_MIP_FILTER;
		ADDRESSU = WRAP; ADDRESSV = WRAP;
	};
#endif

#if EMISSIVE_MAP_FROM >= 1 && EMISSIVE_MAP_FROM <= 6
	#if EMISSIVE_MAP_FROM == 1
		texture EmissiveMap<string ResourceName = EMISSIVE_MAP_FILE;>;
	#elif EMISSIVE_MAP_FROM == 2
		texture EmissiveMap : ANIMATEDTEXTURE<string ResourceName = EMISSIVE_MAP_FILE;>;
	#endif
	sampler EmissiveMapSamp = sampler_state
	{
#if EMISSIVE_MAP_FROM == 3
		texture = DiffuseMap;
#elif EMISSIVE_MAP_FROM == 4
		texture = SphereMap;
#elif EMISSIVE_MAP_FROM == 5
		texture = ToonMap;
#elif EMISSIVE_MAP_FROM == 6
		texture = DummyScreenTex;
#else
		texture = EmissiveMap;
#endif
		MAXANISOTROPY = TEXTURE_ANISOTROPY_LEVEL;
		MINFILTER = TEXTURE_FILTER; MAGFILTER = TEXTURE_FILTER; MIPFILTER = TEXTURE_MIP_FILTER;
		ADDRESSU = WRAP; ADDRESSV = WRAP;
	};
#endif

#if CUSTOM_ENABLE && CUSTOM_A_MAP_FROM >= 1 && CUSTOM_A_MAP_FROM <= 6
	#if CUSTOM_A_MAP_FROM == 1
		texture CustomAMap<string ResourceName = CUSTOM_A_MAP_FILE;>;
	#elif CUSTOM_A_MAP_FROM == 2
		texture CustomAMap : ANIMATEDTEXTURE<string ResourceName = CUSTOM_A_MAP_FILE;>;
	#endif
	sampler CustomAMapSamp = sampler_state
	{
#if CUSTOM_A_MAP_FROM == 3
		texture = DiffuseMap;
#elif CUSTOM_A_MAP_FROM == 4
		texture = SphereMap;
#elif CUSTOM_A_MAP_FROM == 5
		texture = ToonMap;
#elif CUSTOM_A_MAP_FROM == 6
		texture = DummyScreenTex;
#else
		texture = CustomAMap;
#endif
		MAXANISOTROPY = TEXTURE_ANISOTROPY_LEVEL;
		MINFILTER = TEXTURE_FILTER; MAGFILTER = TEXTURE_FILTER; MIPFILTER = TEXTURE_MIP_FILTER;
		ADDRESSU = WRAP; ADDRESSV = WRAP;
	};
#endif

#if CUSTOM_ENABLE && CUSTOM_B_MAP_FROM >= 1 && CUSTOM_B_MAP_FROM <= 6
	#if CUSTOM_B_MAP_FROM == 1
		texture CustomBMap<string ResourceName = CUSTOM_B_MAP_FILE;>;
	#elif CUSTOM_B_MAP_FROM == 2
		texture CustomBMap : ANIMATEDTEXTURE<string ResourceName = CUSTOM_B_MAP_FILE;>;
	#endif
	sampler CustomBMapSamp = sampler_state
	{
#if CUSTOM_B_MAP_FROM == 3
		texture = DiffuseMap;
#elif CUSTOM_B_MAP_FROM == 4
		texture = SphereMap;
#elif CUSTOM_B_MAP_FROM == 5
		texture = ToonMap;
#elif CUSTOM_B_MAP_FROM == 6
		texture = DummyScreenTex;
#else
		texture = CustomBMap;
#endif
		MAXANISOTROPY = TEXTURE_ANISOTROPY_LEVEL;
		MINFILTER = TEXTURE_FILTER; MAGFILTER = TEXTURE_FILTER; MIPFILTER = TEXTURE_MIP_FILTER;
		ADDRESSU = WRAP; ADDRESSV = WRAP;
	};
#endif

struct MaterialParam
{
	float3 normal;
	float3 albedo;
	float3 specular;
	float3 emissive;
	float smoothness;
	float metalness;
	float emissiveIntensity;
	float alpha;
	float visibility;
	float customDataA;
	float3 customDataB;
	int lightModel;
};

struct GbufferParam
{
	float4 buffer1 : COLOR0;
	float4 buffer2 : COLOR1;
	float4 buffer3 : COLOR2;
	float4 buffer4 : COLOR3;
};

float3 EncodeNormal(float3 normal)
{
	float p = sqrt(-normal.z * 8 + 8);
	float2 enc = normal.xy / p + 0.5f;
	float2 enc255 = enc * 255;
	float2 residual = floor(frac(enc255) * 16);
	return float3(floor(enc255), residual.x * 16 + residual.y) / 255;
}

float luminance(float3 rgb)
{
	return dot(rgb, float3(0.299, 0.587, 0.114));
}

float srgb2linear(float rgb)
{
	return pow(max(abs(rgb), 1e-5), 2.2);
}

float3 srgb2linear(float3 rgb)
{
	return pow(max(abs(rgb), 1e-5), 2.2);
}

float4 srgb2linear(float4 c)
{
	return float4(srgb2linear(c.rgb), c.a);
}

float3 rgb2ycbcr(float3 col)
{
	col = sqrt(col);
	float3 encode;
	encode.x = dot(float3(0.299, 0.587, 0.114),   col.rgb);
	encode.y = dot(float3(-0.1687, -0.3312, 0.5), col.rgb) * MIDPOINT_8_BIT + MIDPOINT_8_BIT;
	encode.z = dot(float3(0.5, -0.4186, -0.0813), col.rgb) * MIDPOINT_8_BIT + MIDPOINT_8_BIT;
	return encode;
}

float3 ColorSynthesis(float3 diffuse, float3 m)
{
	float3 melanin = diffuse * luminance(diffuse);
	return diffuse * lerp(1.0, melanin, m);
}

#if NORMAL_MAP_FROM || NORMAL_SUB_MAP_FROM
float3 ComputeTangentBinormalNormal(float3 N, float3 P, float2 coord, float3 tangentNormal)
{
	float3 dp1 = ddx(P);
	float3 dp2 = ddy(P);
	float2 duv1 = ddx(coord);
	float2 duv2 = ddy(coord);

	float3x3 M = float3x3(dp1, dp2, N);
	float2x3 I = float2x3(cross(M[1], M[2]), cross(M[2], M[0]));
	float3 T = mul(float2(duv1.x, duv2.x), I);
	float3 B = mul(float2(duv1.y, duv2.y), I);

	float scaleT = 1.0f / (dot(T, T) + 1e-6);
	float scaleB = 1.0f / (dot(B, B) + 1e-6);

	float3x3 tbnTransform;
	tbnTransform[0] = normalize(T * scaleT);
	tbnTransform[1] = -normalize(B * scaleB);
	tbnTransform[2] = N;

	return normalize(mul(tangentNormal, tbnTransform));
}

float3 RNMBlendUnpacked(float3 n1, float3 n2)
{
	n1 += float3( 0,  0, 1);
	n2 *= float3(-1, -1, 1);
	return normalize(n1 * dot(n1, n2) / n1.z - n2);
}

#if NORMAL_MAP_TYPE == 2 || NORMAL_SUB_MAP_TYPE == 2
float3 PerturbNormalLQ(float3 N, float3 P, float height)
{
	float3 dp1 = ddx(P);
	float3 dp2 = ddy(P);

	float3x3 M = float3x3(dp1, dp2, N);
	float2x3 I = float2x3(cross(M[1], M[2]), cross(M[2], M[0]));

	float det = dot(dp1, I[0]);

	float slope1 = ddx(height);
	float slope2 = ddy(height);

	float3 surf = sign(det) * mul(float2(slope1, slope2), I);
	return normalize(abs(det) * N - surf);
}
#endif

#if NORMAL_MAP_TYPE == 3 || NORMAL_SUB_MAP_TYPE == 3
float3 PerturbNormalHQ(sampler source, float2 coord, float center)
{
	float2 duv1 = ddx (coord);
	float2 duv2 = ddy (coord);

	float2 uv1 = coord + duv1;
	float2 uv2 = coord + duv2;

	float right = tex2D(source, uv1).x;
	float bottom = tex2D(source, uv2).x;

	float slope1 = right - center;
	float slope2 = center - bottom;

	return normalize(float3(slope1, slope2, 10.0));
}
#endif
#endif

#if PARALLAX_MAP_FROM
float GetParallaxOcclusionHeight(sampler heightMap, float2 coord)
{
#if PARALLAX_MAP_SWIZZLE == 1
	return tex2D(heightMap, coord).g;
#elif PARALLAX_MAP_SWIZZLE == 2
	return tex2D(heightMap, coord).b;
#elif PARALLAX_MAP_SWIZZLE == 3
	return tex2D(heightMap, coord).a;
#else
	return tex2D(heightMap, coord).r;
#endif
}

float3 ParallaxOcclusionDirection(float3 normal, float3 worldPos, float2 coord)
{
	float3 viewNormal = mul(normal, (float3x3)matWorldView);
	float3 viewPosition = mul(float4(worldPos, 1), matWorldView).xyz;
	float3 viewdir = normalize(-viewPosition);

	float3 dp1 = ddx(viewPosition);
	float3 dp2 = ddy(viewPosition);

	float2 duv1 = ddx(coord);
	float2 duv2 = ddy(coord);

	float3x3 M = float3x3(dp1, dp2, viewNormal);
	float2x3 I = float2x3(cross(M[1], M[2]), cross(M[2], M[0]));

	float2 proj = mul(I, viewdir) / dot(dp1, I[0]);

	float3 direction;
	direction.xy = duv1 * proj.x + duv2 * proj.y;
	direction.z = dot(viewNormal, viewdir);

	return direction;
}

float2 ParallaxOcclusionMap(sampler heightMap, float2 coord, float3 V, int numSteps, float parallaxScale)
{
	float step = 1.0 / numSteps;
	float2 delta = parallaxScale * V.xy / (-V.z * numSteps);

	float curLayerHeight = 0;
	float curHeight = GetParallaxOcclusionHeight(heightMap, coord);
	float2 curTexcoord = coord;

	[unroll]
	for (int i = 0; i < numSteps; i++)
	{
		if (curHeight <= curLayerHeight)
			break;

		curLayerHeight += step;
		curTexcoord -= delta;
		curHeight = GetParallaxOcclusionHeight(heightMap, curTexcoord);
	}

	float2 deltaTexcoord = delta * 0.5;
	float deltaHeight = step * 0.5;

	curTexcoord += deltaTexcoord;
	curLayerHeight -= deltaHeight;

	[unroll]
	for (int j = 0; j < 5; j++)
	{
		deltaTexcoord *= 0.5;
		deltaHeight *= 0.5;

		curHeight = GetParallaxOcclusionHeight(heightMap, curTexcoord);

		if (curHeight > curLayerHeight)
		{
			curTexcoord -= deltaTexcoord;
			curLayerHeight += deltaHeight;
		}
		else
		{
			curTexcoord += deltaTexcoord;
			curLayerHeight -= deltaHeight;
		}
	}

	return curTexcoord;
}
#endif

float SmoothnessToRoughness(float smoothness)
{
	return (1.0f - smoothness) * (1.0f - smoothness);
}

float RoughnessToSmoothness(float roughness)
{
	return 1.0f - sqrt(roughness);
}

float ShininessToSmoothness(float spec)
{
	return 1.0f - pow(max(0, 2.0 / (spec + 2)), 0.125);
}

GbufferParam EncodeGbuffer(MaterialParam material, float linearDepth)
{
	GbufferParam gbuffer;
	gbuffer.buffer1.xyz = material.albedo * (1 - material.metalness);
	gbuffer.buffer1.w = material.smoothness;

	material.normal = mul(material.normal, (float3x3)matWorldView);
	material.normal = normalize(material.normal);

	gbuffer.buffer2.xyz = EncodeNormal(material.normal);
	gbuffer.buffer2.w = material.customDataA;

	gbuffer.buffer3.xyz = lerp(material.specular, max(0.02, material.albedo), material.metalness);
	gbuffer.buffer3.w = 0;

#if CUSTOM_ENABLE || EMISSIVE_ENABLE
	if (material.lightModel != SHADINGMODELID_DEFAULT)
	{
#if EMISSIVE_ENABLE
		material.customDataB = material.emissive;
#elif CUSTOM_ENABLE != SHADINGMODELID_GLASS
		material.customDataB *= (1 - material.metalness);
#endif
		gbuffer.buffer3 = float4(luminance(gbuffer.buffer3.xyz), material.customDataB);
	}
#endif

	gbuffer.buffer4 = float4(linearDepth, material.emissiveIntensity, material.visibility, material.lightModel);
	gbuffer.buffer4.w += material.alpha * MAX_FRACTIONAL_8_BIT;

	return gbuffer;
}

float3 GetMainNormal(float3 N, float3 P, float2 coord)
{
#if NORMAL_MAP_FROM
	#if NORMAL_MAP_UV_FLIP == 1
		coord.x = 1 - coord.x;
	#elif NORMAL_MAP_UV_FLIP == 2
		coord.y = 1 - coord.y;
	#elif NORMAL_MAP_UV_FLIP == 3
		coord = 1 - coord;
	#endif

	#if NORMAL_MAP_FROM == 3
		float3 tangentNormal = use_texture ? tex2D(NormalMapSamp, coord * normalMapLoopNum).rgb * 2 - 1 : float3(0, 0, 1);
	#elif NORMAL_MAP_FROM == 4
		float3 tangentNormal = use_spheremap ? tex2D(NormalMapSamp, coord * normalMapLoopNum).rgb * 2 - 1 : float3(0, 0, 1);
	#elif NORMAL_MAP_FROM == 5
		float3 tangentNormal = use_toon ? tex2D(NormalMapSamp, coord * normalMapLoopNum).rgb * 2 - 1 : float3(0, 0, 1);
	#elif NORMAL_MAP_FROM == 7 || NORMAL_MAP_FROM == 8 || NORMAL_MAP_FROM == 9
		#error Unsupported options 7, 8, 9.
	#else
		float3 tangentNormal = tex2D(NormalMapSamp, coord * normalMapLoopNum).rgb * 2 - 1;
	#endif

	#if NORMAL_MAP_TYPE == 1
		tangentNormal.z = sqrt(1.0 - tangentNormal.x * tangentNormal.x - tangentNormal.y * tangentNormal.y);
	#elif NORMAL_MAP_TYPE == 3
		tangentNormal = PerturbNormalHQ(NormalMapSamp, coord * normalMapLoopNum, tangentNormal.x);
	#elif NORMAL_MAP_TYPE == 2
		tangentNormal = PerturbNormalLQ(N, P, tangentNormal.x * normalMapScale);
		#if NORMAL_SUB_MAP_FROM
			#error Unsupported bump map (Low Quality) with second normal map. Please set NORMAL_SUB_MAP_FROM to 0.
		#endif
	#endif

	#if NORMAL_MAP_TYPE != 2
		tangentNormal.rg *= normalMapScale;
		tangentNormal = normalize(tangentNormal);
	#endif

	return tangentNormal;
#else
	return float3(0, 0, 1);
#endif
}

float3 GetSubNormal(float3 N, float3 P, float2 coord)
{
#if NORMAL_SUB_MAP_FROM
	#if NORMAL_SUB_MAP_UV_FLIP == 1
		coord.x = 1 - coord.x;
	#elif NORMAL_SUB_MAP_UV_FLIP == 2
		coord.y = 1 - coord.y;
	#elif NORMAL_SUB_MAP_UV_FLIP == 3
		coord = 1 - coord;
	#endif

	#if NORMAL_SUB_MAP_FROM == 3
		float3 tangentNormal = use_texture ? tex2D(NormalSubMapSamp, coord * normalSubMapLoopNum).rgb : float3(0, 0, 1);
	#elif NORMAL_SUB_MAP_FROM == 4
		float3 tangentNormal = use_spheremap ? tex2D(NormalSubMapSamp, coord * normalSubMapLoopNum).rgb : float3(0, 0, 1);
	#elif NORMAL_SUB_MAP_FROM == 5
		float3 tangentNormal = use_toon ? tex2D(NormalSubMapSamp, coord * normalSubMapLoopNum).rgb : float3(0, 0, 1);
	#elif NORMAL_SUB_MAP_FROM == 7 || NORMAL_SUB_MAP_FROM == 8 || NORMAL_SUB_MAP_FROM == 9
		#error Unsupported options 7, 8, 9.
	#else
		float3 tangentNormal = tex2D(NormalSubMapSamp, coord * normalSubMapLoopNum).rgb;
	#endif

	#if NORMAL_SUB_MAP_TYPE != 4
		tangentNormal = tangentNormal * 2 - 1;
	#endif

	#if NORMAL_SUB_MAP_TYPE == 1
		tangentNormal.z = sqrt(1.0 - tangentNormal.x * tangentNormal.x - tangentNormal.y * tangentNormal.y);
	#elif NORMAL_SUB_MAP_TYPE == 3
		tangentNormal = PerturbNormalHQ(NormalSubMapSamp, coord * normalSubMapLoopNum, tangentNormal.x);
	#elif NORMAL_SUB_MAP_TYPE == 2
		tangentNormal = PerturbNormalLQ(N, P, tangentNormal.x * normalSubMapScale);
		#if NORMAL_MAP_FROM
			#error Unsupported bump map (Low Quality) with second normal map. Please set NORMAL_MAP_FROM to 0.
		#endif
	#endif

	#if NORMAL_SUB_MAP_TYPE != 2
		tangentNormal.rg *= normalSubMapScale;
		tangentNormal = normalize(tangentNormal);
	#endif

	return tangentNormal;
#else
	return float3(0, 0, 1);
#endif
}

float3 GetNormal(float3 N, float3 P, float2 coord)
{
#if NORMAL_MAP_UV_FLIP == 4
	N.x *= -1;
#endif
#if NORMAL_MAP_FROM || NORMAL_SUB_MAP_FROM
	#if NORMAL_MAP_FROM && NORMAL_SUB_MAP_FROM && (NORMAL_MAP_TYPE == 4 || NORMAL_SUB_MAP_TYPE == 4)
		#error "Unsupported option"
	#endif

	#if NORMAL_MAP_FROM
		float3 tangentNormal1 = GetMainNormal(N, P, coord);
	#endif

	#if NORMAL_SUB_MAP_FROM
		float3 tangentNormal2 = GetSubNormal(N, P, coord);
	#endif

	#if NORMAL_MAP_FROM && NORMAL_SUB_MAP_FROM
		float3 tangentNormal = RNMBlendUnpacked(tangentNormal1, tangentNormal2);
	#elif NORMAL_MAP_FROM
		float3 tangentNormal = tangentNormal1;
	#else
		float3 tangentNormal = tangentNormal2;
	#endif

	#if (NORMAL_MAP_FROM && (NORMAL_MAP_TYPE == 2 || NORMAL_MAP_TYPE == 4)) || (NORMAL_SUB_MAP_FROM && (NORMAL_SUB_MAP_TYPE == 2 || NORMAL_SUB_MAP_TYPE == 4))
		return tangentNormal;
	#else
		#if NORMAL_MAP_UV_FLIP == 1
			coord.x = 1 - coord.x;
		#elif NORMAL_MAP_UV_FLIP == 2
			coord.y = 1 - coord.y;
		#elif NORMAL_MAP_UV_FLIP == 3
			coord = 1 - coord;
		#endif
		return ComputeTangentBinormalNormal(N, P, coord, tangentNormal);
	#endif
#else
	return N;
#endif
}

float GetSmoothness(float2 coord)
{
#if SMOOTHNESS_MAP_FROM
	#if SMOOTHNESS_MAP_UV_FLIP == 1
		coord.x = 1 - coord.x;
	#elif SMOOTHNESS_MAP_UV_FLIP == 2
		coord.y = 1 - coord.y;
	#elif SMOOTHNESS_MAP_UV_FLIP == 3
		coord = 1 - coord;
	#endif

	#if SMOOTHNESS_MAP_FROM == 3
		float4 smoothnessValues = use_texture ? tex2D(SmoothnessMapSamp, coord * smoothnessMapLoopNum) : 0;
	#elif SMOOTHNESS_MAP_FROM == 4
		float4 smoothnessValues = use_spheremap ? tex2D(SmoothnessMapSamp, coord * smoothnessMapLoopNum) : 0;
	#elif SMOOTHNESS_MAP_FROM == 5
		float4 smoothnessValues = use_toon ? tex2D(SmoothnessMapSamp, coord * smoothnessMapLoopNum) : 0;
	#elif SMOOTHNESS_MAP_FROM == 7
		float4 smoothnessValues = MaterialAmbient;
	#elif SMOOTHNESS_MAP_FROM == 8
		float4 smoothnessValues = MaterialSpecular;
	#elif SMOOTHNESS_MAP_FROM == 9
		float4 smoothnessValues = ShininessToSmoothness(MaterialPower);
	#else
		float4 smoothnessValues = tex2D(SmoothnessMapSamp, coord * smoothnessMapLoopNum);
	#endif

	#if SMOOTHNESS_MAP_SWIZZLE == 1
		float smoothnessValue = smoothnessValues.g;
	#elif SMOOTHNESS_MAP_SWIZZLE == 2
		float smoothnessValue = smoothnessValues.b;
	#elif SMOOTHNESS_MAP_SWIZZLE == 3
		float smoothnessValue = smoothnessValues.a;
	#else
		float smoothnessValue = smoothnessValues.r;
	#endif

	#if SMOOTHNESS_MAP_TYPE == 1
		smoothnessValue = RoughnessToSmoothness(smoothnessValue);
	#elif SMOOTHNESS_MAP_TYPE == 2
		smoothnessValue = 1 - smoothnessValue;
	#endif

	#if SMOOTHNESS_MAP_APPLY_SCALE == 1
		smoothnessValue *= smoothness;
	#elif SMOOTHNESS_MAP_APPLY_SCALE == 2
		smoothnessValue = pow(smoothnessValue, smoothness);
	#endif

	return saturate(smoothnessValue);
#else
	return smoothness;
#endif
}

float GetMetalness(float2 coord)
{
#if METALNESS_MAP_FROM
	#if METALNESS_MAP_UV_FLIP == 1
		coord.x = 1 - coord.x;
	#elif METALNESS_MAP_UV_FLIP == 2
		coord.y = 1 - coord.y;
	#elif METALNESS_MAP_UV_FLIP == 3
		coord = 1 - coord;
	#endif

	#if METALNESS_MAP_FROM == 3
		float4 metalnessValues = use_texture ? tex2D(MetalnessMapSamp, coord * metalnessMapLoopNum) : 0;
	#elif METALNESS_MAP_FROM == 4
		float4 metalnessValues = use_spheremap ? tex2D(MetalnessMapSamp, coord * metalnessMapLoopNum) : 0;
	#elif METALNESS_MAP_FROM == 5
		float4 metalnessValues = use_toon ? tex2D(MetalnessMapSamp, coord * metalnessMapLoopNum) : 0;
	#elif METALNESS_MAP_FROM == 7
		float4 metalnessValues = MaterialAmbient;
	#elif METALNESS_MAP_FROM == 8
		float4 metalnessValues = MaterialSpecular;
	#elif METALNESS_MAP_FROM == 9
		float4 metalnessValues = ShininessToSmoothness(MaterialPower);
	#else
		float4 metalnessValues = tex2D(MetalnessMapSamp, coord * metalnessMapLoopNum);
	#endif

	#if METALNESS_MAP_SWIZZLE == 1
		float metalnessValue = metalnessValues.g;
	#elif METALNESS_MAP_SWIZZLE == 2
		float metalnessValue = metalnessValues.b;
	#elif METALNESS_MAP_SWIZZLE == 3
		float metalnessValue = metalnessValues.a;
	#else
		float metalnessValue = metalnessValues.r;
	#endif

	#if METALNESS_MAP_APPLY_SCALE == 1
		metalnessValue *= metalness;
	#elif METALNESS_MAP_APPLY_SCALE == 2
		metalnessValue = pow(metalnessValue, metalness);
	#endif

	return saturate(metalnessValue);
#else
	return metalness;
#endif
}

float3 GetSpecular(float2 coord)
{
#if SPECULAR_MAP_FROM
	#if CUSTOM_ENABLE && SPECULAR_MAP_TYPE <= 1
		#error Unsupported material, When CUSTOM_ENABLE > 0 and specular map has multiple channels (RGB), Please set CUSTOM_ENABLE to 0
	#endif

	#if SPECULAR_MAP_UV_FLIP == 1
		coord.x = 1 - coord.x;
	#elif SPECULAR_MAP_UV_FLIP == 2
		coord.y = 1 - coord.y;
	#elif SPECULAR_MAP_UV_FLIP == 3
		coord = 1 - coord;
	#endif

	#if SPECULAR_MAP_FROM == 3
		float4 specularColor = use_texture ? tex2D(SpecularMapSamp, coord * specularMapLoopNum) : 0.5;
	#elif SPECULAR_MAP_FROM == 4
		float4 specularColor = use_spheremap ? tex2D(SpecularMapSamp, coord * specularMapLoopNum) : 0.5;
	#elif SPECULAR_MAP_FROM == 5
		float4 specularColor = use_toon ? tex2D(SpecularMapSamp, coord * specularMapLoopNum) : 0.5;
	#elif SPECULAR_MAP_FROM == 7
		float4 specularColor = MaterialAmbient;
	#elif SPECULAR_MAP_FROM == 8
		float4 specularColor = MaterialSpecular;
	#elif SPECULAR_MAP_FROM == 9
		#error Unsupported options 9.
	#else
		float4 specularColor = tex2D(SpecularMapSamp, coord * specularMapLoopNum);
	#endif

	#if SPECULAR_MAP_TYPE == 2 || SPECULAR_MAP_TYPE == 3
		#if SPECULAR_MAP_SWIZZLE == 1
			specularColor = specularColor.g;
		#elif SPECULAR_MAP_SWIZZLE == 2
			specularColor = specularColor.b;
		#elif SPECULAR_MAP_SWIZZLE == 3
			specularColor = specularColor.a;
		#else
			specularColor = specularColor.r;
		#endif
	#endif

	#if SPECULAR_MAP_TYPE == 1 || SPECULAR_MAP_TYPE == 3
		specularColor = 0.16 * specularColor * specularColor;
	#else
		specularColor = 0.08 * specularColor;
	#endif

	#if SPECULAR_MAP_APPLY_SCALE == 1
		specularColor.rgb *= specular;
	#elif SPECULAR_MAP_APPLY_SCALE == 2
		specularColor.rgb = pow(specularColor.rgb, specular);
	#endif

	return clamp(specularColor.rgb, 0.01, 1.0);
#else
	#if SPECULAR_MAP_TYPE == 1 || SPECULAR_MAP_TYPE == 3
		return saturate(0.16 * specular * specular);
	#elif SPECULAR_MAP_TYPE == 4
		return saturate(specular);
	#else
		return saturate(0.08 * specular);
	#endif
#endif
}

float GetOcclusion(float2 coord)
{
#if OCCLUSION_MAP_FROM
	#if OCCLUSION_MAP_UV_FLIP == 1
		coord.x = 1 - coord.x;
	#elif OCCLUSION_MAP_UV_FLIP == 2
		coord.y = 1 - coord.y;
	#elif OCCLUSION_MAP_UV_FLIP == 3
		coord = 1 - coord;
	#endif

	#if OCCLUSION_MAP_FROM == 3
		float4 occlusionValues = use_texture ? tex2D(OcclusionMapSamp, coord * occlusionMapLoopNum) : 1;
	#elif OCCLUSION_MAP_FROM == 4
		float4 occlusionValues = use_spheremap ? tex2D(OcclusionMapSamp, coord * occlusionMapLoopNum) : 1;
	#elif OCCLUSION_MAP_FROM == 5
		float4 occlusionValues = use_toon ? tex2D(OcclusionMapSamp, coord * occlusionMapLoopNum) : 1;
	#elif OCCLUSION_MAP_FROM == 7
		float4 occlusionValues = MaterialAmbient;
	#elif OCCLUSION_MAP_FROM == 8
		float4 occlusionValues = MaterialSpecular;
	#elif OCCLUSION_MAP_FROM == 9
		#error Unsupported options 9.
	#else
		float4 occlusionValues = tex2D(OcclusionMapSamp, coord * occlusionMapLoopNum);
	#endif

	#if OCCLUSION_MAP_SWIZZLE == 1
		float occlusionValue = occlusionValues.g;
	#elif OCCLUSION_MAP_SWIZZLE == 2
		float occlusionValue = occlusionValues.b;
	#elif OCCLUSION_MAP_SWIZZLE == 3
		float occlusionValue = occlusionValues.a;
	#else
		float occlusionValue = occlusionValues.r;
	#endif

	#if OCCLUSION_MAP_TYPE == 1 || OCCLUSION_MAP_TYPE == 3
		occlusionValue = srgb2linear(occlusionValue);
	#endif

	#if OCCLUSION_MAP_APPLY_SCALE == 1
		occlusionValue *= occlusion;
	#elif OCCLUSION_MAP_APPLY_SCALE == 2
		occlusionValue = pow(occlusionValue, occlusion);
	#endif

	return saturate(occlusionValue);
#else
	return saturate(occlusion);
#endif
}

float3 GetEmissiveColor(float2 coord)
{
#if EMISSIVE_ENABLE
	#if EMISSIVE_MAP_UV_FLIP == 1
		coord.x = 1 - coord.x;
	#elif EMISSIVE_MAP_UV_FLIP == 2
		coord.y = 1 - coord.y;
	#elif EMISSIVE_MAP_UV_FLIP == 3
		coord = 1 - coord;
	#endif

	#if EMISSIVE_MAP_FROM == 1 || EMISSIVE_MAP_FROM == 2 || EMISSIVE_MAP_FROM == 6
		float4 emissiveTexCol = tex2D(EmissiveMapSamp, coord * emissiveMapLoopNum);
		float3 emissiveColor = lerp(0, emissiveTexCol.rgb, emissiveTexCol.a);
	#elif EMISSIVE_MAP_FROM == 3
		float4 emissiveTexCol = use_texture ? tex2D(EmissiveMapSamp, coord * emissiveMapLoopNum) : 0;
		float3 emissiveColor = lerp(0, emissiveTexCol.rgb, emissiveTexCol.a);
	#elif EMISSIVE_MAP_FROM == 4
		float4 emissiveTexCol = use_spheremap ? tex2D(EmissiveMapSamp, coord * emissiveMapLoopNum) : 0;
		float3 emissiveColor = lerp(0, emissiveTexCol.rgb, emissiveTexCol.a);
	#elif EMISSIVE_MAP_FROM == 5
		float4 emissiveTexCol = use_toon ? tex2D(EmissiveMapSamp, coord * emissiveMapLoopNum) : 0;
		float3 emissiveColor = lerp(0, emissiveTexCol.rgb, emissiveTexCol.a);
	#elif EMISSIVE_MAP_FROM == 7
		float3 emissiveColor = MaterialAmbient.rgb;
	#elif EMISSIVE_MAP_FROM == 8
		float3 emissiveColor = MaterialSpecular.rgb;
	#elif EMISSIVE_MAP_FROM == 9
		#error Unsupported options 9.
	#else
		float3 emissiveColor = emissive;
	#endif

	emissiveColor = srgb2linear(emissiveColor);

	#if EMISSIVE_MAP_APPLY_SCALE
		emissiveColor *= emissive.rgb;
	#endif

	#if EMISSIVE_MAP_APPLY_MORPH_COLOR
		emissiveColor *= MorphColor;
	#endif

	#if EMISSIVE_MAP_APPLY_BLINK
		emissiveColor *= LightBlink;
	#endif

	return emissiveColor;
#else
	return 0;
#endif
}

float GetEmissiveIntensity()
{
#if EMISSIVE_ENABLE
	#if EMISSIVE_MAP_APPLY_MORPH_INTENSITY
		return emissiveIntensity * LightIntensity;
	#else
		return emissiveIntensity;
	#endif
#else
	return 0;
#endif
}

float GetCustomDataA(float2 coord)
{
#if CUSTOM_ENABLE
	float customData = customA;

	#if CUSTOM_A_MAP_FROM
		#if CUSTOM_A_MAP_UV_FLIP == 1
			coord.x = 1 - coord.x;
		#elif CUSTOM_A_MAP_UV_FLIP == 2
			coord.y = 1 - coord.y;
		#elif CUSTOM_A_MAP_UV_FLIP == 3
			coord = 1 - coord;
		#endif

		#if CUSTOM_A_MAP_FROM == 3
			float4 customValues = use_texture ? tex2D(CustomAMapSamp, coord * customAMapLoopNum) : 0;
		#elif CUSTOM_A_MAP_FROM == 4
			float4 customValues = use_spheremap ? tex2D(CustomAMapSamp, coord * customAMapLoopNum) : 0;
		#elif CUSTOM_A_MAP_FROM == 5
			float4 customValues = use_toon ? tex2D(CustomAMapSamp, coord * customAMapLoopNum) : 0;
		#elif CUSTOM_A_MAP_FROM == 7
			float4 customValues = MaterialAmbient;
		#elif CUSTOM_A_MAP_FROM == 8
			float4 customValues = MaterialSpecular;
		#elif CUSTOM_A_MAP_FROM == 9
			#error Unsupported options 9.
		#else
			float4 customValues = tex2D(CustomAMapSamp, coord * customAMapLoopNum);
		#endif

		#if CUSTOM_A_MAP_SWIZZLE == 1
			customData = customValues.g;
		#elif CUSTOM_A_MAP_SWIZZLE == 2
			customData = customValues.b;
		#elif CUSTOM_A_MAP_SWIZZLE == 3
			customData = customValues.a;
		#else
			customData = customValues.r;
		#endif

		#if CUSTOM_A_MAP_APPLY_SCALE == 1
			customData *= customA;
		#elif CUSTOM_A_MAP_APPLY_SCALE == 2
			customData = pow(customData, customA);
		#endif
	#endif

	#if CUSTOM_ENABLE == SHADINGMODELID_CLEAR_COAT
		#if CUSTOM_A_MAP_COLOR_FLIP
			return RoughnessToSmoothness(customData);
		#else
			return customData;
		#endif
	#else
		#if CUSTOM_A_MAP_COLOR_FLIP
			return 1 - customData;
		#else
			return customData;
		#endif
	#endif
#else
	return 0.0f;
#endif
}

float3 GetCustomDataB(float2 coord)
{
#if CUSTOM_ENABLE
	float3 customData = srgb2linear(customB);

	#if CUSTOM_B_MAP_FROM
		#if CUSTOM_B_MAP_UV_FLIP == 1
			coord.x = 1 - coord.x;
		#elif CUSTOM_B_MAP_UV_FLIP == 2
			coord.y = 1 - coord.y;
		#elif CUSTOM_B_MAP_UV_FLIP == 3
			coord = 1 - coord;
		#endif

		#if CUSTOM_B_MAP_FROM == 3
			customData = use_texture ? tex2D(CustomBMapSamp, coord * customBMapLoopNum).rgb : 0;
		#elif CUSTOM_B_MAP_FROM == 4
			customData = use_spheremap ? tex2D(CustomBMapSamp, coord * customBMapLoopNum).rgb : 0;
		#elif CUSTOM_B_MAP_FROM == 5
			customData = use_toon ? tex2D(CustomBMapSamp, coord * customBMapLoopNum) : 0;
		#elif CUSTOM_B_MAP_FROM == 7
			customData = MaterialAmbient;
		#elif CUSTOM_B_MAP_FROM == 8
			customData = MaterialSpecular;
		#elif CUSTOM_B_MAP_FROM == 9
			#error Unsupported options 9.
		#else
			customData = tex2D(CustomBMapSamp, coord * customBMapLoopNum).rgb;
		#endif

		#if CUSTOM_B_MAP_FROM && CUSTOM_B_MAP_TYPE == 0
			customData = srgb2linear(customData);
		#endif

		#if CUSTOM_B_MAP_COLOR_FLIP
			customData = 1 - customData;
		#endif

		#if CUSTOM_B_MAP_APPLY_SCALE == 1
			customData *= customB;
		#elif CUSTOM_B_MAP_APPLY_SCALE == 2
			customData = pow(customData, customB);
		#endif
	#endif

	return saturate(customData);
#else
	return 0.0;
#endif
}

float GetLightMode(MaterialParam material)
{
#if CUSTOM_ENABLE
	#if CUSTOM_ENABLE >= SHADINGMODELID_MASK
		#error Unsupported option Shading Material ID
	#endif
	#if EMISSIVE_ENABLE
		return any(saturate(material.emissive - EMISSIVE_EPSILON)) ? SHADINGMODELID_EMISSIVE : CUSTOM_ENABLE;
	#else
		return CUSTOM_ENABLE;
	#endif
#else
	return any(saturate(material.emissive - EMISSIVE_EPSILON)) ? SHADINGMODELID_EMISSIVE : SHADINGMODELID_DEFAULT;
#endif
}

void MaterialVS(
	in float4 Position : POSITION,
	in float3 Normal : NORMAL,
	in float2 Texcoord1 : TEXCOORD0,
	out float3 oNormal   : TEXCOORD0,
	out float2 oTexcoord1 : TEXCOORD1,
	out float4 oWorldPos  : TEXCOORD3,
	out float4 oPosition  : POSITION)
{
	oNormal = Normal;
	CalculatePosition(Texcoord1, oPosition, oTexcoord1);
	oWorldPos = float4(Position.xyz, oPosition.w);
}

GbufferParam MaterialPS(
	in float3 normal   : TEXCOORD0,
	in float2 coord0   : TEXCOORD1,
	in float4 worldPos : TEXCOORD3)
{
	normal = normalize(normal);
	float4 color = CalculateColor(coord0);

	float alpha = color.a;
	clip(alpha - ALPHA_THRESHOLD);

	MaterialParam material;
	material.albedo = color.rgb;
	material.normal = GetNormal(normal, worldPos.xyz, coord0);
	material.smoothness = GetSmoothness(coord0);
	material.metalness = GetMetalness(coord0);
	material.specular = GetSpecular(coord0);
	material.customDataA = GetCustomDataA(coord0);
	material.customDataB = GetCustomDataB(coord0);
	material.emissive = GetEmissiveColor(coord0);
	material.emissiveIntensity = GetEmissiveIntensity();
#if OCCLUSION_MAP_TYPE == 2 || OCCLUSION_MAP_TYPE == 3
	material.visibility = GetOcclusion(coord1);
#else
	material.visibility = GetOcclusion(coord0);
#endif
	material.lightModel = GetLightMode(material);
	material.alpha = 1;

	return EncodeGbuffer(material, 0);
}

GbufferParam Material2PS(
	in float3 normal   : TEXCOORD0,
	in float2 coord0   : TEXCOORD1,
	in float4 worldPos : TEXCOORD3)
{
	normal = normalize(normal);
	float4 color = CalculateColor(coord0);

	float alpha = color.a;
	clip(alpha - 0.01);

	MaterialParam material;
	material.albedo = color.rgb;
	material.normal = GetNormal(normal, worldPos.xyz, coord0);
	material.smoothness = GetSmoothness(coord0);
	material.metalness = GetMetalness(coord0);
	material.specular = GetSpecular(coord0);
	material.customDataA = GetCustomDataA(coord0);
	material.customDataB = GetCustomDataB(coord0);
	material.emissive = GetEmissiveColor(coord0);
	material.emissiveIntensity = GetEmissiveIntensity();
#if OCCLUSION_MAP_TYPE == 2 || OCCLUSION_MAP_TYPE == 3
	material.visibility = GetOcclusion(coord1);
#else
	material.visibility = GetOcclusion(coord0);
#endif
	material.lightModel = GetLightMode(material);
#if ALPHA_MAP_FROM == 2
	material.alpha = alpha;
#else
	material.alpha = alpha > ALPHA_THRESHOLD ? 0 : alpha;
#endif

	return EncodeGbuffer(material, 0);
}

#define OBJECT_TEC(name, mmdpass)\
	technique name<string MMDPass = mmdpass;\
	string Script =\
		"RenderColorTarget0=;"\
		"RenderColorTarget1=Gbuffer2RT;"\
		"RenderColorTarget2=Gbuffer3RT;"\
		"RenderColorTarget3=Gbuffer4RT;"\
		"Pass=DrawObject;"\
		"RenderColorTarget0=Gbuffer5RT;"\
		"RenderColorTarget1=Gbuffer6RT;"\
		"RenderColorTarget2=Gbuffer7RT;"\
		"RenderColorTarget3=Gbuffer8RT;"\
		"Pass=DrawAlphaObject;"\
	;>{\
		pass DrawObject {\
			AlphaTestEnable = false; AlphaBlendEnable = false;\
			VertexShader = compile vs_3_0 MaterialVS();\
			PixelShader  = compile ps_3_0 MaterialPS();\
		}\
		pass DrawAlphaObject {\
			AlphaTestEnable = false; AlphaBlendEnable = false;\
			VertexShader = compile vs_3_0 MaterialVS();\
			PixelShader  = compile ps_3_0 Material2PS();\
		}\
	}

OBJECT_TEC(MainTec0, "object")
OBJECT_TEC(MainTecBS0, "object_ss")

technique EdgeTec<string MMDPass = "edge";>{}
technique ShadowTech<string MMDPass = "shadow";>{}
technique ZplotTec<string MMDPass = "zplot";>{}
