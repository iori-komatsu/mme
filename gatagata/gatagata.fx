//
// gatagata: モデルをガタガタにします
//

static const float MaxPerturbWidth = 1.0;
static const float Scale = 0.1;

// LightColor に対する AmbientColor の大きさ
static const float AmbientCoeff = 0.1;

//---------------------------------------------------------------------------------------------

// 座法変換行列
float4x4 WorldViewProjMatrix      : WORLDVIEWPROJECTION;
float4x4 WorldMatrix              : WORLD;
float4x4 ViewMatrix               : VIEW;
float4x4 LightWorldViewProjMatrix : WORLDVIEWPROJECTION < string Object = "Light"; >;

float3   LightDirection    : DIRECTION < string Object = "Light"; >;
float3   CameraPosition    : POSITION  < string Object = "Camera"; >;

// マテリアル色
float3   MaterialAmbient   : AMBIENT  < string Object = "Geometry"; >;
float4   MaterialDiffuse   : DIFFUSE  < string Object = "Geometry"; >;
float3   MaterialSpecular  : SPECULAR < string Object = "Geometry"; >;
float    SpecularPower     : SPECULARPOWER < string Object = "Geometry"; >;
// ライト色
float3   LightAmbient        : AMBIENT < string Object = "Light"; >;
static float3 LightColor = LightAmbient * 4;
static float3 AmbientColor = LightColor * AmbientCoeff;

// テクスチャ材質モーフ値
float4   TextureAddValue   : ADDINGTEXTURE;
float4   TextureMulValue   : MULTIPLYINGTEXTURE;

bool     parthf;   // パースペクティブフラグ
bool     transp;   // 半透明フラグ
#define SKII1    1500
#define SKII2    8000

// オブジェクトのテクスチャ
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

// シャドウバッファのサンプラ。"register(s0)"なのはMMDがs0を使っているから
sampler ShadowBufferSampler : register(s0);

//---------------------------------------------------------------------------------------------

// Hash without Sine (MIT License)
// https://www.shadertoy.com/view/4djSRW
float3 Hash33(float3 p3)
{
	p3 = frac(p3 * float3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yxz + 33.33);
	return frac((p3.xxy + p3.yxx) * p3.zyx);
}

// 頂点シェーダ
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
	float3 perturb = (2 * Hash33(pos.xyz) - 1) * MaxPerturbWidth;

	pos.xyz += perturb;

	// カメラ視点のワールドビュー射影変換
	oPos = mul(pos, WorldViewProjMatrix);

	// ワールド座標
	oWorldPos = mul(pos, WorldMatrix).xyz;
	// 頂点法線
	oNormal = normalize(mul(normal, (float3x3)WorldMatrix));

	if (selfShadow) {
		// ライト視点によるワールドビュー射影変換
		oLightClipPos = mul(pos, LightWorldViewProjMatrix);
	}

	// テクスチャ座標
	oTexCoord = texCoord;
}

float3 CalculateLight(
	float4 lightClipPos,
	uniform bool selfShadow
) {
	if (!selfShadow) {
		return LightColor;
	}

	// シャドウマップの座標に変換
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
		// セルフシャドウ mode2
		comp = 1 - saturate(lightDepth * SKII2 * shadowMapCoord.y - 0.3);
	} else {
		// セルフシャドウ mode1
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
	// Phong specular
	float3 halfVector = normalize(eye + -LightDirection);
	float3 specular = pow(max(0, dot(halfVector, normal)), SpecularPower) * MaterialSpecular;

	// Half Lambert diffuse
	const float Z = 3.0 / (4.0 * PI);
	float diffuseLight = dot(normal, -LightDirection) * 0.5 + 0.5;
	float3 diffuse = Z * diffuseLight * diffuseLight * baseColor;

	return (specular + diffuse) * lightColor + AmbientColor * baseColor;
}

float4 BaseColor(float2 tex, uniform bool useTexture)
{
	float4 baseColor = float4(MaterialAmbient, MaterialDiffuse.a);
	if (useTexture) {
		float4 texColor = tex2D(ObjectTextureSampler, tex);
		// テクスチャ材質モーフ
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

	// world空間におけるu軸とv軸の方向を求める
	float3 u = normalize(uv2.y * p1 - uv1.y * p2);
	float3 v = normalize(uv1.x * p2 - uv2.x * p1);

	// uとvをnormalを法線とする平面に射影して tangent vector と binormal vector を得る
	float3 tangent  = normalize(u - dot(u, normal) * normal);
	float3 binormal = normalize(v - dot(v, normal) * normal);

	return normalize(tangentNormal.x * tangent + tangentNormal.y * binormal + tangentNormal.z * normal);
}

float Hash31(float3 p) {
	float t = dot(p, float3(17, 1527, 113));
	return frac(sin(t) * 43758.5453123);
}

float ValueNoise(float3 src) {
    float3 i = floor(src);
    float3 f = frac(src);

    float v1 = Hash31(i + float3(0.0, 0.0, 0.0));
    float v2 = Hash31(i + float3(1.0, 0.0, 0.0));
    float v3 = Hash31(i + float3(0.0, 1.0, 0.0));
    float v4 = Hash31(i + float3(1.0, 1.0, 0.0));
    float v5 = Hash31(i + float3(0.0, 0.0, 1.0));
    float v6 = Hash31(i + float3(1.0, 0.0, 1.0));
    float v7 = Hash31(i + float3(0.0, 1.0, 1.0));
    float v8 = Hash31(i + float3(1.0, 1.0, 1.0));

    float3 a = f * f * f * (10.0 + f * (-15.0 + f * 6.0));

    return 2.0 * lerp(
        lerp(lerp(v1, v2, a.x), lerp(v3, v4, a.x), a.y),
        lerp(lerp(v5, v6, a.x), lerp(v7, v8, a.x), a.y),
        a.z
    ) - 1.0;
}

float FBM(float3 src) {
    const int NUM_OCTAVES = 4;
    float f = 0.25;
    float a = 1.0;
    float ret = 0.0;
    for (int i = 0; i < NUM_OCTAVES; ++i) {
        ret += a * ValueNoise(f * src);
        f *= 2.0;
        a *= 0.5;
    }
    const float s = (1.0 - pow(0.5, float(NUM_OCTAVES))) * 2.0;
    return ret / s;
}

float3 RandomUnitVector(float3 p) {
	float r1 = FBM(p);
	float r2 = FBM(p + float3(42, 12, 91)) * TAU;
	float theta = acos(1 - r1 * 0.2);
	float phi = r2;
	return float3(sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta));
}

// ピクセルシェーダ
float4 MainPS(
	float4 lightClipPos : TEXCOORD0,
	float2 tex : TEXCOORD1,
	float3 normal : TEXCOORD2,
	float3 worldPos : TEXCOORD3,
	uniform bool useTexture,
	uniform bool selfShadow
) : COLOR0 {
	float3 tangentNormal = RandomUnitVector(worldPos * 0.1 / Scale);
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

