#include "sub/HitTexture.fxsub"

////////////////////////////////////////////////////////////////////////////////////////////////////
// �p�����[�^�錾

float Tr : CONTROLOBJECT < string name = "(self)"; string item = "Tr";>;	// ���ߓx

// ���@�ϊ��s��
float4x4 WorldViewProjMatrix      : WORLDVIEWPROJECTION;
float4x4 WorldMatrix              : WORLD;
float4x4 ViewMatrix               : VIEW;
float4x4 LightWorldViewProjMatrix : WORLDVIEWPROJECTION < string Object = "Light"; >;

float3   LightDirection    : DIRECTION < string Object = "Light"; >;
float3   CameraPosition    : POSITION  < string Object = "Camera"; >;

// �}�e���A���F
float4   MaterialDiffuse   : DIFFUSE  < string Object = "Geometry"; >;
float3   MaterialAmbient   : AMBIENT  < string Object = "Geometry"; >;
float3   MaterialEmmisive  : EMISSIVE < string Object = "Geometry"; >;
float3   MaterialSpecular  : SPECULAR < string Object = "Geometry"; >;
float    SpecularPower     : SPECULARPOWER < string Object = "Geometry"; >;
float3   MaterialToon      : TOONCOLOR;
float4   EdgeColor         : EDGECOLOR;
float4   GroundShadowColor : GROUNDSHADOWCOLOR;
// ���C�g�F
float3   LightDiffuse      : DIFFUSE   < string Object = "Light"; >;
float3   LightAmbient      : AMBIENT   < string Object = "Light"; >;
float3   LightSpecular     : SPECULAR  < string Object = "Light"; >;
static float4 DiffuseColor  = MaterialDiffuse  * float4(LightDiffuse, 1.0f);
static float3 AmbientColor  = MaterialAmbient  * LightAmbient + MaterialEmmisive;
static float3 SpecularColor = MaterialSpecular * LightSpecular;

// �e�N�X�`���ގ����[�t�l
float4   TextureAddValue   : ADDINGTEXTURE;
float4   TextureMulValue   : MULTIPLYINGTEXTURE;
float4   SphereAddValue    : ADDINGSPHERETEXTURE;
float4   SphereMulValue    : MULTIPLYINGSPHERETEXTURE;

bool     use_subtexture;    // �T�u�e�N�X�`���t���O

bool     parthf;   // �p�[�X�y�N�e�B�u�t���O
bool     transp;   // �������t���O
bool     spadd;    // �X�t�B�A�}�b�v���Z�����t���O
#define SKII1    1500
#define SKII2    8000
#define Toon     3

////////////////////////////////////////////////////////////////////////////////////////////////

float CurrentTime : TIME < bool SyncInEditMode = true; >;

// �I�u�W�F�N�g�̃e�N�X�`��
texture ObjectTexture: MATERIALTEXTURE;
sampler ObjTexSampler = sampler_state {
    texture = <ObjectTexture>;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
    MIPFILTER = LINEAR;
    ADDRESSU  = WRAP;
    ADDRESSV  = WRAP;
};

// �X�t�B�A�}�b�v�̃e�N�X�`��
texture ObjectSphereMap: MATERIALSPHEREMAP;
sampler ObjSphareSampler = sampler_state {
    texture = <ObjectSphereMap>;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
    MIPFILTER = LINEAR;
    ADDRESSU  = WRAP;
    ADDRESSV  = WRAP;
};

// �g�D�[���}�b�v�̃e�N�X�`��
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
// �֊s�`��

// ���_�V�F�[�_
float4 ColorRender_VS(float4 Pos : POSITION) : POSITION
{
    // �J�������_�̃��[���h�r���[�ˉe�ϊ�
    return mul( Pos, WorldViewProjMatrix );
}

// �s�N�Z���V�F�[�_
float4 ColorRender_PS() : COLOR
{
    // �֊s�F�œh��Ԃ�
    return EdgeColor;
}

// �֊s�`��p�e�N�j�b�N
technique EdgeTec < string MMDPass = "edge"; > {
    pass DrawEdge {
        VertexShader = compile vs_2_0 ColorRender_VS();
        PixelShader  = compile ps_2_0 ColorRender_PS();
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////
// �e�i��Z���t�V���h�E�j�`��

// ���_�V�F�[�_
float4 Shadow_VS(float4 Pos : POSITION) : POSITION
{
    // �J�������_�̃��[���h�r���[�ˉe�ϊ�
    return mul( Pos, WorldViewProjMatrix );
}

// �s�N�Z���V�F�[�_
float4 Shadow_PS() : COLOR
{
    // �n�ʉe�F�œh��Ԃ�
    return GroundShadowColor;
}

// �e�`��p�e�N�j�b�N
technique ShadowTec < string MMDPass = "shadow"; > {
    pass DrawShadow {
        VertexShader = compile vs_2_0 Shadow_VS();
        PixelShader  = compile ps_2_0 Shadow_PS();
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////
// �I�u�W�F�N�g�`��i�Z���t�V���h�EOFF�j

struct VS_OUTPUT {
    float4 Pos        : POSITION;    // �ˉe�ϊ����W
    float2 Tex        : TEXCOORD1;   // �e�N�X�`��
    float3 Normal     : TEXCOORD2;   // �@��
    float3 Eye        : TEXCOORD3;   // �J�����Ƃ̑��Έʒu
    float2 SpTex      : TEXCOORD4;   // �X�t�B�A�}�b�v�e�N�X�`�����W
    float4 Color      : COLOR0;      // �f�B�t���[�Y�F
    float3 Specular   : COLOR1;      // �X�y�L�����F
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

// ���_�V�F�[�_
VS_OUTPUT Basic_VS(float4 Pos : POSITION, float3 Normal : NORMAL, float2 Tex : TEXCOORD0, float2 Tex2 : TEXCOORD1)
{
    VS_OUTPUT Out = (VS_OUTPUT)0;

    // �J�������_�̃��[���h�r���[�ˉe�ϊ�
    Out.Pos = mul( Pos, WorldViewProjMatrix );

    // �J�����Ƃ̑��Έʒu
    Out.Eye = CameraPosition - mul( Pos, WorldMatrix );
    // ���_�@��
    Out.Normal = normalize( mul( Normal, (float3x3)WorldMatrix ) );

    // �f�B�t���[�Y�F�{�A���r�G���g�F �v�Z
    Out.Color.rgb = AmbientColor;
    Out.Color.rgb += max(0,dot( Out.Normal, -LightDirection )) * DiffuseColor.rgb;
    Out.Color.a = DiffuseColor.a;
    Out.Color = saturate( Out.Color );

    // �e�N�X�`�����W
    Out.Tex = Tex;

    // �X�y�L�����F�v�Z
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
    // ���������̏ꍇ
    if (ctime < 0.1 || all(prev == float4(1, 1, 1, 1)) || Tr > 0.5) {
        color = float4(curr.r, 0, curr.b, 1);
    }
    // ���������łȂ��A���ݓ��܂�Ă���A�ߋ��ɓ��܂�Ă��Ȃ��ꍇ
    else if (length(curr.rgb) > 0.5 && (ptime < 0.01 || abs(ctime - ptime) >= RESET_INTERVAL)) {
        color = float4(curr.r, ctime, curr.b, 1);
    }
    // �ߋ��ɓ��܂�Ă����ꍇ�A�܂��͌��ݓ��܂�Ă��Ȃ��ꍇ
    else {
        color = prev;
    }

    return color;
}

// �s�N�Z���V�F�[�_
float4 Basic_PS(VS_OUTPUT IN) : COLOR0
{
	float2 uv = float2(IN.Tex.x, 1.0 - IN.Tex.y);
    float4 t = tex2D(HitHistory1Sampler, uv);
    float4 color = float4(t.r, t.g / 50, t.b, 1);
    return color;
}

// �I�u�W�F�N�g�`��p�e�N�j�b�N
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
// �Z���t�V���h�E�pZ�l�v���b�g

struct VS_ZValuePlot_OUTPUT {
    float4 Pos : POSITION;              // �ˉe�ϊ����W
    float4 ShadowMapTex : TEXCOORD0;    // Z�o�b�t�@�e�N�X�`��
};

// ���_�V�F�[�_
VS_ZValuePlot_OUTPUT ZValuePlot_VS( float4 Pos : POSITION )
{
    VS_ZValuePlot_OUTPUT Out = (VS_ZValuePlot_OUTPUT)0;

    // ���C�g�̖ڐ��ɂ�郏�[���h�r���[�ˉe�ϊ�������
    Out.Pos = mul( Pos, LightWorldViewProjMatrix );

    // �e�N�X�`�����W�𒸓_�ɍ��킹��
    Out.ShadowMapTex = Out.Pos;

    return Out;
}

// �s�N�Z���V�F�[�_
float4 ZValuePlot_PS( float4 ShadowMapTex : TEXCOORD0 ) : COLOR
{
    // R�F������Z�l���L�^����
    return float4(ShadowMapTex.z/ShadowMapTex.w,0,0,1);
}

// Z�l�v���b�g�p�e�N�j�b�N
technique ZplotTec < string MMDPass = "zplot"; > {
    pass ZValuePlot {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_2_0 ZValuePlot_VS();
        PixelShader  = compile ps_2_0 ZValuePlot_PS();
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////
// �I�u�W�F�N�g�`��i�Z���t�V���h�EON�j

// �V���h�E�o�b�t�@�̃T���v���B"register(s0)"�Ȃ̂�MMD��s0���g���Ă��邩��
sampler DefSampler : register(s0);

struct BufferShadow_OUTPUT {
    float4 Pos      : POSITION;     // �ˉe�ϊ����W
    float4 ZCalcTex : TEXCOORD0;    // Z�l
    float2 Tex      : TEXCOORD1;    // �e�N�X�`��
    float3 Normal   : TEXCOORD2;    // �@��
    float3 Eye      : TEXCOORD3;    // �J�����Ƃ̑��Έʒu
    float2 SpTex    : TEXCOORD4;     // �X�t�B�A�}�b�v�e�N�X�`�����W
    float4 Color    : COLOR0;       // �f�B�t���[�Y�F
};

// ���_�V�F�[�_
BufferShadow_OUTPUT BufferShadow_VS(float4 Pos : POSITION, float3 Normal : NORMAL, float2 Tex : TEXCOORD0, float2 Tex2 : TEXCOORD1)
{
    BufferShadow_OUTPUT Out = (BufferShadow_OUTPUT)0;

    // �J�������_�̃��[���h�r���[�ˉe�ϊ�
    Out.Pos = mul( Pos, WorldViewProjMatrix );

    // �J�����Ƃ̑��Έʒu
    Out.Eye = CameraPosition - mul( Pos, WorldMatrix );
    // ���_�@��
    Out.Normal = normalize( mul( Normal, (float3x3)WorldMatrix ) );
    // ���C�g���_�ɂ�郏�[���h�r���[�ˉe�ϊ�
    Out.ZCalcTex = mul( Pos, LightWorldViewProjMatrix );

    // �f�B�t���[�Y�F�{�A���r�G���g�F �v�Z
    Out.Color.rgb = AmbientColor;
    Out.Color.rgb += max(0,dot( Out.Normal, -LightDirection )) * DiffuseColor.rgb;
    Out.Color.a = DiffuseColor.a;
    Out.Color = saturate( Out.Color );

    // �e�N�X�`�����W
    Out.Tex = Tex;

    return Out;
}

// �s�N�Z���V�F�[�_
float4 BufferShadow_PS(BufferShadow_OUTPUT IN) : COLOR
{
    float4 Color = tex2D(HitSampler, IN.Tex);
    return Color;
}

/*
// �I�u�W�F�N�g�`��p�e�N�j�b�N
technique MainTecBS0  < string MMDPass = "object_ss"; > {
    pass DrawObject {
        VertexShader = compile vs_3_0 BufferShadow_VS();
        PixelShader  = compile ps_3_0 BufferShadow_PS();
    }
}
*/

///////////////////////////////////////////////////////////////////////////////////////////////


