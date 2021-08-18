#include "sub/HitTexture.fxsub"

////////////////////////////////////////////////////////////////////////////////////////////////////
// パラメータ宣言

float Tr : CONTROLOBJECT < string name = "(self)"; string item = "Tr";>;	// 透過度

// 座法変換行列
float4x4 WorldViewProjMatrix      : WORLDVIEWPROJECTION;
float4x4 WorldMatrix              : WORLD;
float4x4 ViewMatrix               : VIEW;
float4x4 LightWorldViewProjMatrix : WORLDVIEWPROJECTION < string Object = "Light"; >;

float3   LightDirection    : DIRECTION < string Object = "Light"; >;
float3   CameraPosition    : POSITION  < string Object = "Camera"; >;

// マテリアル色
float4   MaterialDiffuse   : DIFFUSE  < string Object = "Geometry"; >;
float3   MaterialAmbient   : AMBIENT  < string Object = "Geometry"; >;
float3   MaterialEmmisive  : EMISSIVE < string Object = "Geometry"; >;
float3   MaterialSpecular  : SPECULAR < string Object = "Geometry"; >;
float    SpecularPower     : SPECULARPOWER < string Object = "Geometry"; >;
float3   MaterialToon      : TOONCOLOR;
float4   EdgeColor         : EDGECOLOR;
float4   GroundShadowColor : GROUNDSHADOWCOLOR;
// ライト色
float3   LightDiffuse      : DIFFUSE   < string Object = "Light"; >;
float3   LightAmbient      : AMBIENT   < string Object = "Light"; >;
float3   LightSpecular     : SPECULAR  < string Object = "Light"; >;
static float4 DiffuseColor  = MaterialDiffuse  * float4(LightDiffuse, 1.0f);
static float3 AmbientColor  = MaterialAmbient  * LightAmbient + MaterialEmmisive;
static float3 SpecularColor = MaterialSpecular * LightSpecular;

// テクスチャ材質モーフ値
float4   TextureAddValue   : ADDINGTEXTURE;
float4   TextureMulValue   : MULTIPLYINGTEXTURE;
float4   SphereAddValue    : ADDINGSPHERETEXTURE;
float4   SphereMulValue    : MULTIPLYINGSPHERETEXTURE;

bool     use_subtexture;    // サブテクスチャフラグ

bool     parthf;   // パースペクティブフラグ
bool     transp;   // 半透明フラグ
bool     spadd;    // スフィアマップ加算合成フラグ
#define SKII1    1500
#define SKII2    8000
#define Toon     3

////////////////////////////////////////////////////////////////////////////////////////////////

float CurrentTime : TIME < bool SyncInEditMode = true; >;

// オブジェクトのテクスチャ
texture ObjectTexture: MATERIALTEXTURE;
sampler ObjTexSampler = sampler_state {
    texture = <ObjectTexture>;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
    MIPFILTER = LINEAR;
    ADDRESSU  = WRAP;
    ADDRESSV  = WRAP;
};

// スフィアマップのテクスチャ
texture ObjectSphereMap: MATERIALSPHEREMAP;
sampler ObjSphareSampler = sampler_state {
    texture = <ObjectSphereMap>;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
    MIPFILTER = LINEAR;
    ADDRESSU  = WRAP;
    ADDRESSV  = WRAP;
};

// トゥーンマップのテクスチャ
texture ObjectToonTexture: MATERIALTOONTEXTURE;
sampler ObjToonSampler = sampler_state {
    texture = <ObjectToonTexture>;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
    MIPFILTER = NONE;
    ADDRESSU  = CLAMP;
    ADDRESSV  = CLAMP;
};

////////////////////////////////////////////////////////////////////////////////////////////////

float2 ViewportSize : VIEWPORTPIXELSIZE;
static float2 ViewportOffset = float2(0.5, 0.5) / ViewportSize;

texture HitRT : OFFSCREENRENDERTARGET <
    string Description = "OffScreen RenderTarget for HitDisplay.fx";
    int Width = HITTEXTURE_SIZE;
    int Height = HITTEXTURE_SIZE;
    string Format = "A32B32G32R32F";
    float4 ClearColor = { 0, 0, 0, 1 };
    float ClearDepth = 1.0;
    bool AntiAlias = false;
    string DefaultEffect = "self=hide;*=HitTest.fx;";
>;
sampler HitSampler = sampler_state {
    Texture = (HitRT);
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
    MAGFILTER = NONE;
    MINFILTER = NONE;
    MIPFILTER = NONE;
};

shared texture HitHistory1RT : RENDERCOLORTARGET <
    int Width = HITTEXTURE_SIZE;
    int Height = HITTEXTURE_SIZE;
    string Format = "A32B32G32R32F";
>;
texture HitHistory1DepthBuffer : RENDERDEPTHSTENCILTARGET <
    int Width = HITTEXTURE_SIZE;
    int Height = HITTEXTURE_SIZE;
>;
sampler HitHistory1Sampler = sampler_state {
    Texture = (HitHistory1RT);
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
    MAGFILTER = NONE;
    MINFILTER = NONE;
    MIPFILTER = NONE;
};

texture HitHistory2RT : RENDERCOLORTARGET <
    int Width = HITTEXTURE_SIZE;
    int Height = HITTEXTURE_SIZE;
    string Format = "A32B32G32R32F";
>;
texture HitHistory2DepthBuffer : RENDERDEPTHSTENCILTARGET <
    int Width = HITTEXTURE_SIZE;
    int Height = HITTEXTURE_SIZE;
>;
sampler HitHistory2Sampler = sampler_state {
    Texture = (HitHistory2RT);
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
    MAGFILTER = NONE;
    MINFILTER = NONE;
    MIPFILTER = NONE;
};

float4 Black = float4(0, 0, 0, 1);


////////////////////////////////////////////////////////////////////////////////////////////////
// 輪郭描画

// 頂点シェーダ
float4 ColorRender_VS(float4 Pos : POSITION) : POSITION
{
    // カメラ視点のワールドビュー射影変換
    return mul( Pos, WorldViewProjMatrix );
}

// ピクセルシェーダ
float4 ColorRender_PS() : COLOR
{
    // 輪郭色で塗りつぶし
    return EdgeColor;
}

// 輪郭描画用テクニック
technique EdgeTec < string MMDPass = "edge"; > {
    pass DrawEdge {
        VertexShader = compile vs_2_0 ColorRender_VS();
        PixelShader  = compile ps_2_0 ColorRender_PS();
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////
// 影（非セルフシャドウ）描画

// 頂点シェーダ
float4 Shadow_VS(float4 Pos : POSITION) : POSITION
{
    // カメラ視点のワールドビュー射影変換
    return mul( Pos, WorldViewProjMatrix );
}

// ピクセルシェーダ
float4 Shadow_PS() : COLOR
{
    // 地面影色で塗りつぶし
    return GroundShadowColor;
}

// 影描画用テクニック
technique ShadowTec < string MMDPass = "shadow"; > {
    pass DrawShadow {
        VertexShader = compile vs_2_0 Shadow_VS();
        PixelShader  = compile ps_2_0 Shadow_PS();
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////
// オブジェクト描画（セルフシャドウOFF）

struct VS_OUTPUT {
    float4 Pos        : POSITION;    // 射影変換座標
    float2 Tex        : TEXCOORD1;   // テクスチャ
    float3 Normal     : TEXCOORD2;   // 法線
    float3 Eye        : TEXCOORD3;   // カメラとの相対位置
    float2 SpTex      : TEXCOORD4;   // スフィアマップテクスチャ座標
    float4 Color      : COLOR0;      // ディフューズ色
    float3 Specular   : COLOR1;      // スペキュラ色
};

VS_OUTPUT FullScreen_VS(float4 Pos : POSITION, float3 Normal : NORMAL, float2 Tex : TEXCOORD0, float2 Tex2 : TEXCOORD1)
{
    VS_OUTPUT Out = (VS_OUTPUT)0;

    float4x4 view = MatrixLookAtLH(float3(0, 0, 0), float3(0, -1, 0), float3(0, 0, 1));
    float4x4 proj = MatrixOrthoLH(PLANE_WIDTH / 10, PLANE_HEIGHT / 10, -10, 10);

    Out.Pos = mul(mul(Pos, view), proj);
    Out.Tex = Tex + ViewportOffset;
    Out.Color = float4(1, 1, 1, 1);

    return Out;
}

// 頂点シェーダ
VS_OUTPUT Basic_VS(float4 Pos : POSITION, float3 Normal : NORMAL, float2 Tex : TEXCOORD0, float2 Tex2 : TEXCOORD1)
{
    VS_OUTPUT Out = (VS_OUTPUT)0;

    // カメラ視点のワールドビュー射影変換
    Out.Pos = mul( Pos, WorldViewProjMatrix );

    // カメラとの相対位置
    Out.Eye = CameraPosition - mul( Pos, WorldMatrix );
    // 頂点法線
    Out.Normal = normalize( mul( Normal, (float3x3)WorldMatrix ) );

    // ディフューズ色＋アンビエント色 計算
    Out.Color.rgb = AmbientColor;
    Out.Color.rgb += max(0,dot( Out.Normal, -LightDirection )) * DiffuseColor.rgb;
    Out.Color.a = DiffuseColor.a;
    Out.Color = saturate( Out.Color );

    // テクスチャ座標
    Out.Tex = Tex;

    // スペキュラ色計算
    float3 HalfVector = normalize( normalize(Out.Eye) + -LightDirection );
    Out.Specular = pow( max(0,dot( HalfVector, Out.Normal )), SpecularPower ) * SpecularColor;

    return Out;
}

float4 CopyHitHistory_PS(VS_OUTPUT IN) : COLOR0
{
    return tex2D(HitHistory1Sampler, IN.Tex);
}

float4 UpdateHitHistory_PS(VS_OUTPUT IN) : COLOR0
{
    float4 prev = tex2D(HitHistory2Sampler, IN.Tex);
    float ptime = prev.g;

    float4 curr = float4(0, 0, 0, 1);
    for (int y = -1; y <= 1; ++y) {
        curr = max(curr, tex2D(HitSampler, IN.Tex + float2(0, y) / ViewportSize));
    }
    for (int x = -1; x <= 1; ++x) {
        curr = max(curr, tex2D(HitSampler, IN.Tex + float2(x, 0) / ViewportSize));
    }

    float ctime = CurrentTime;

    float4 color;
    // 未初期化の場合
    if (ctime < 0.1 || all(prev == float4(1, 1, 1, 1)) || Tr > 0.5) {
        color = float4(curr.r, 0, curr.b, 1);
    }
    // 未初期化でなく、現在踏まれており、過去に踏まれていない場合
    else if (length(curr.rgb) > 0.5 && (ptime < 0.01 || abs(ctime - ptime) >= RESET_INTERVAL)) {
        color = float4(curr.r, ctime, curr.b, 1);
    }
    // 過去に踏まれていた場合、または現在踏まれていない場合
    else {
        color = prev;
    }

    return color;
}

// ピクセルシェーダ
float4 Basic_PS(VS_OUTPUT IN) : COLOR0
{
	float2 uv = float2(IN.Tex.x, 1.0 - IN.Tex.y);
    float4 t = tex2D(HitHistory1Sampler, uv);
    float4 color = float4(t.r, t.g / 50, t.b, 1);
    return color;
}

// オブジェクト描画用テクニック
technique MainTec0 < string MMDPass = "object"; > {
    pass CopyHistory <
        string Script =
            "RenderColorTarget0=HitHistory2RT;"
            "RenderDepthStencilTarget=HitHistory2DepthBuffer;"
            "SetClearColor=Black;"
            "Clear=Color;"
            "Clear=Depth;"
            "Draw=Geometry;"
        ;
    > {
        VertexShader = compile vs_3_0 FullScreen_VS();
        PixelShader  = compile ps_3_0 CopyHitHistory_PS();
    }

    pass UpdateHistory <
        string Script =
            "RenderColorTarget0=HitHistory1RT;"
            "RenderDepthStencilTarget=HitHistory1DepthBuffer;"
            "SetClearColor=Black;"
            "Clear=Color;"
            "Clear=Depth;"
            "Draw=Geometry;"
            "RenderColorTarget0=;"
            "RenderDepthStencilTarget=;"
        ;
    > {
        VertexShader = compile vs_3_0 FullScreen_VS();
        PixelShader  = compile ps_3_0 UpdateHitHistory_PS();
    }

    pass DrawObject {
        VertexShader = compile vs_3_0 Basic_VS();
        PixelShader  = compile ps_3_0 Basic_PS();
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////
// セルフシャドウ用Z値プロット

struct VS_ZValuePlot_OUTPUT {
    float4 Pos : POSITION;              // 射影変換座標
    float4 ShadowMapTex : TEXCOORD0;    // Zバッファテクスチャ
};

// 頂点シェーダ
VS_ZValuePlot_OUTPUT ZValuePlot_VS( float4 Pos : POSITION )
{
    VS_ZValuePlot_OUTPUT Out = (VS_ZValuePlot_OUTPUT)0;

    // ライトの目線によるワールドビュー射影変換をする
    Out.Pos = mul( Pos, LightWorldViewProjMatrix );

    // テクスチャ座標を頂点に合わせる
    Out.ShadowMapTex = Out.Pos;

    return Out;
}

// ピクセルシェーダ
float4 ZValuePlot_PS( float4 ShadowMapTex : TEXCOORD0 ) : COLOR
{
    // R色成分にZ値を記録する
    return float4(ShadowMapTex.z/ShadowMapTex.w,0,0,1);
}

// Z値プロット用テクニック
technique ZplotTec < string MMDPass = "zplot"; > {
    pass ZValuePlot {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_2_0 ZValuePlot_VS();
        PixelShader  = compile ps_2_0 ZValuePlot_PS();
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////
// オブジェクト描画（セルフシャドウON）

// シャドウバッファのサンプラ。"register(s0)"なのはMMDがs0を使っているから
sampler DefSampler : register(s0);

struct BufferShadow_OUTPUT {
    float4 Pos      : POSITION;     // 射影変換座標
    float4 ZCalcTex : TEXCOORD0;    // Z値
    float2 Tex      : TEXCOORD1;    // テクスチャ
    float3 Normal   : TEXCOORD2;    // 法線
    float3 Eye      : TEXCOORD3;    // カメラとの相対位置
    float2 SpTex    : TEXCOORD4;     // スフィアマップテクスチャ座標
    float4 Color    : COLOR0;       // ディフューズ色
};

// 頂点シェーダ
BufferShadow_OUTPUT BufferShadow_VS(float4 Pos : POSITION, float3 Normal : NORMAL, float2 Tex : TEXCOORD0, float2 Tex2 : TEXCOORD1)
{
    BufferShadow_OUTPUT Out = (BufferShadow_OUTPUT)0;

    // カメラ視点のワールドビュー射影変換
    Out.Pos = mul( Pos, WorldViewProjMatrix );

    // カメラとの相対位置
    Out.Eye = CameraPosition - mul( Pos, WorldMatrix );
    // 頂点法線
    Out.Normal = normalize( mul( Normal, (float3x3)WorldMatrix ) );
    // ライト視点によるワールドビュー射影変換
    Out.ZCalcTex = mul( Pos, LightWorldViewProjMatrix );

    // ディフューズ色＋アンビエント色 計算
    Out.Color.rgb = AmbientColor;
    Out.Color.rgb += max(0,dot( Out.Normal, -LightDirection )) * DiffuseColor.rgb;
    Out.Color.a = DiffuseColor.a;
    Out.Color = saturate( Out.Color );

    // テクスチャ座標
    Out.Tex = Tex;

    return Out;
}

// ピクセルシェーダ
float4 BufferShadow_PS(BufferShadow_OUTPUT IN) : COLOR
{
    float4 Color = tex2D(HitSampler, IN.Tex);
    return Color;
}

/*
// オブジェクト描画用テクニック
technique MainTecBS0  < string MMDPass = "object_ss"; > {
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_VS();
        PixelShader  = compile ps_3_0 BufferShadow_PS();
    }
}
*/

///////////////////////////////////////////////////////////////////////////////////////////////


