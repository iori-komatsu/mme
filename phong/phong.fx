//
// phong: フォンの反射モデルを使ったシェーディングを行う
//

// LightColor に対する AmbientColor の大きさ
static const float AmbientCoeff = 0.75;

//----------------------------------------------------------------------------------------------

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
float3   LightColor        : SPECULAR < string Object = "Light"; >;
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

//---------------------------------------------------------------------------------------------

// シャドウバッファのサンプラ。"register(s0)"なのはMMDがs0を使っているから
sampler ShadowBufferSampler : register(s0);

// 頂点シェーダ
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
    // カメラ視点のワールドビュー射影変換
    oPos = mul(pos, WorldViewProjMatrix);

    // カメラとの相対位置
    oEye = CameraPosition - mul(pos, WorldMatrix).rgb;
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

    // Lambert diffuse
	float3 diffuse = max(0, dot(normal, -LightDirection)) * baseColor / PI;

	return (specular + diffuse) * lightColor + AmbientColor * baseColor;
}

// ピクセルシェーダ
float4 BasicPS(
	float4 lightClipPos : TEXCOORD0,
	float2 tex : TEXCOORD1,
	float3 normal : TEXCOORD2,
	float3 eye : TEXCOORD3,
	uniform bool useTexture,
	uniform bool selfShadow
) : COLOR0 {
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
	if (transp) {
		baseColor.a = 0.5;
	}
	float3 lightColor = CalculateLight(lightClipPos, selfShadow);
	return float4(
		Phong(baseColor.rgb, normalize(normal), normalize(eye), lightColor),
		baseColor.a);
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
