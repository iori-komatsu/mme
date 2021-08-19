#include "sub/HitTexture.fxsub"

float CurrentTime : TIME < bool SyncInEditMode = true; >;
float4x4 ViewProjMatrix : VIEWPROJECTION;

float2 ViewportSize : VIEWPORTPIXELSIZE;
static const float2 ViewportOffset = float2(0.5, 0.5) / ViewportSize;

float  mVisualize : CONTROLOBJECT<string name = "(self)"; string item = "Visualize";>;
float  mReset     : CONTROLOBJECT<string name = "(self)"; string item = "Reset";>;

// ���ݓ��܂�Ă���ꏊ�������_�����O����e�N�X�`��
texture2D HitRT : OFFSCREENRENDERTARGET <
    string Description = "GatagataEx HitTest";
    string Format = "R32F";
	int2   Dimensions = {HitTextureSize, HitTextureSize};
	int    Miplevels = 1;
    float4 ClearColor = {0, 0, 0, 1};
    float  ClearDepth = 1.0;
    bool   AntiAlias = false;
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

// ���܂łɓ��܂ꂽ���Ƃ�����ꏊ��ێ����Ă����e�N�X�`��
shared texture2D HitHistory : RENDERCOLORTARGET <
    string Format = "R32F";
	int2 Dimensions = {HitTextureSize, HitTextureSize};
>;
texture2D HitHistoryDepthBuffer : RENDERDEPTHSTENCILTARGET <
	int2 Dimensions = {HitTextureSize, HitTextureSize};
>;
sampler HitHistorySampler = sampler_state {
    Texture = (HitHistory);
    ADDRESSU = BORDER;
    ADDRESSV = BORDER;
    MAGFILTER = NONE;
    MINFILTER = NONE;
    MIPFILTER = NONE;
};

// HitHistory ���X�V����Ƃ��̍�Ɨp�̃e�N�X�`��
texture2D HitHistoryTemp : RENDERCOLORTARGET <
    string Format = "R32F";
	int2 Dimensions = {HitTextureSize, HitTextureSize};
>;
texture2D HitHistoryTempDepthBuffer : RENDERDEPTHSTENCILTARGET <
	int2 Dimensions = {HitTextureSize, HitTextureSize};
>;
sampler HitHistoryTempSampler = sampler_state {
    Texture = (HitHistoryTemp);
    ADDRESSU = BORDER;
    ADDRESSV = BORDER;
    MAGFILTER = NONE;
    MINFILTER = NONE;
    MIPFILTER = NONE;
};

float4 Black = float4(0, 0, 0, 1);

//-----------------------------------------------------------------------------

void CopyVS(
	float4 pos : POSITION,
	float2 coord : TEXCOORD0,
	out float4 oPos : POSITION,
	out float2 oCoord : TEXCOORD0
) {
	oPos = pos;
	oCoord = coord + float2(0.5, 0.5) / HitTextureSize;
}

float4 CopyPS(float2 coord : TEXCOORD0) : COLOR {
    return tex2D(HitHistorySampler, coord);
}

float4 UpdateHistoryPS(float2 coord : TEXCOORD0) : COLOR {
    float prev = tex2D(HitHistoryTempSampler, coord).r;

	float hit = 0;
	for (int dx = -2; dx <= 2; dx++) {
		for (int dy = -2; dy <= 2; dy++) {
			if (abs(dx) + abs(dy) <= 2) {
				float2 uv = coord + float2(dx, dy) / HitTextureSize;
				hit += tex2D(HitSampler, uv).r;
			}
		}
	}

    float c;
    // �ŏ��̃t���[���ł��邩���Z�b�g����Ă��邩������Ԃ̏ꍇ
	// (�e�N�X�`���͏��������ꂽ�Ƃ��͔��ɂȂ��Ă�����ۂ�)
    if (CurrentTime < 0.01 || mReset >= 0.5 || prev == 1.0) {
        c = 0;
    }
    // ���ݓ������Ă���ꍇ
    else if (hit > 0.01) {
        c = 0.5;
    }
    // �������Ă��Ȃ��ꍇ
    else {
        c = prev;
    }

    return float4(c, 0, 0, 1);
}

//-----------------------------------------------------------------------------

void VisualizeVS(
	float4 pos : POSITION,
	float2 coord : TEXCOORD0,
	out float4 oPos : POSITION,
	out float2 oCoord : TEXCOORD0
) {
	if (mVisualize < 0.5) {
		// Visualize ���I�t�̏ꍇ�͕`�悳��Ȃ��Ƃ���֔�΂�
		oPos = float4(0, 0, 2, 1);
		oCoord = float2(0, 0);
	} else {
		float4 modelPos = pos.xzyw;
		modelPos.xz *= PlaneSize * 0.5;
		modelPos.xyz += mCenter;
		oPos = mul(modelPos, ViewProjMatrix);
		oCoord = coord + ViewportOffset;
	}
}

float4 VisualizePS(float2 coord : TEXCOORD0) : COLOR {
	float2 uv = float2(1 - coord.x, coord.y);
	float hit = tex2D(HitHistorySampler, uv).r;
    return float4(hit, 0, 0, 1);
}

//-----------------------------------------------------------------------------

#define DEFINE_TEC(tecname, mmdpass) \
	technique tecname < string MMDPass = mmdpass; > { \
		pass Copy < \
			string Script = \
				"RenderColorTarget0=HitHistoryTemp;" \
				"RenderDepthStencilTarget=HitHistoryTempDepthBuffer;" \
				"SetClearColor=Black;" \
				"Clear=Depth;" \
				"Draw=Geometry;" \
			; \
		> { \
			VertexShader = compile vs_3_0 CopyVS(); \
			PixelShader  = compile ps_3_0 CopyPS(); \
		} \
	\
		pass UpdateHistory < \
			string Script = \
				"RenderColorTarget0=HitHistory;" \
				"RenderDepthStencilTarget=HitHistoryDepthBuffer;" \
				"SetClearColor=Black;" \
				"Clear=Depth;" \
				"Draw=Geometry;" \
				"RenderColorTarget0=;" \
				"RenderDepthStencilTarget=;" \
			; \
		> { \
			VertexShader = compile vs_3_0 CopyVS(); \
			PixelShader  = compile ps_3_0 UpdateHistoryPS(); \
		} \
	\
		pass DrawObject { \
			VertexShader = compile vs_3_0 VisualizeVS(); \
			PixelShader  = compile ps_3_0 VisualizePS(); \
		} \
	}

DEFINE_TEC(MainTec, "object")
DEFINE_TEC(MainTecSS, "object_ss")

technique EdgeTechnique < string MMDPass = "edge"; > {
    // �`�悵�Ȃ�
}

technique ShadowTechnique < string MMDPass = "shadow"; > {
    // �`�悵�Ȃ�
}
