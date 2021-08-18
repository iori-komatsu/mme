#include "sub/HitTexture.fxsub"

////////////////////////////////////////////////////////////////////////////////////////////////////
// �O���[�o���ϐ�
////////////////////////////////////////////////////////////////////////////////////////////////////

float4x4 WorldMatrix : WORLD;
float4x4 WorldViewProjMatrix : WORLDVIEWPROJMATRIX;


////////////////////////////////////////////////////////////////////////////////////////////////////
// �V�F�[�_�֐�
////////////////////////////////////////////////////////////////////////////////////////////////////

struct VS_OUTPUT {
    float4 Pos : POSITION;
    float4 Color : COLOR0;
};

VS_OUTPUT HitTest_VS(float4 pos : POSITION, float3 normal : NORMAL) {
    VS_OUTPUT Out;

	float4 worldPos = mul(pos, WorldMatrix);
	Out.Pos = WorldPosToHitTexturePos(worldPos);
	Out.Pos.xy += HitTextureOffset;

    // �@���x�N�g����F�ɕϊ�
    float3 n = (normal + float3(1, 1, 1)) * 0.5;
    Out.Color = float4(n.x, n.y, n.z, 1);

    return Out;
}

float4 HitTest_PS(float4 pos : POSITION, float4 color : COLOR0) : COLOR0 {
    return color;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
// �e�N�j�b�N
////////////////////////////////////////////////////////////////////////////////////////////////////

technique ObjectTechnique < string MMDPass = "object"; > {
    pass DrawObject {
        CullMode = NONE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 HitTest_VS();
        PixelShader = compile ps_3_0 HitTest_PS();
    }
}

technique ObjectSSTechnique < string MMDPass = "object_ss"; > {
    pass DrawObject {
        CullMode = NONE;
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_3_0 HitTest_VS();
        PixelShader = compile ps_3_0 HitTest_PS();
    }
}

technique EdgeTechnique < string MMDPass = "edge"; > {
    // �`�悵�Ȃ�
}

technique ShadowTechnique < string MMDPass = "shadow"; > {
    // �`�悵�Ȃ�
}
