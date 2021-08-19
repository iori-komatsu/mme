#include "sub/HitTexture.fxsub"

float4x4 WorldMatrix : WORLD;

void HitTestVS(
	float4 pos : POSITION,
	out float4 oPos : POSITION
) {
	float4 worldPos = mul(pos, WorldMatrix);
	oPos = WorldPosToHitTexturePos(worldPos);
}

float4 HitTestPS() : COLOR {
    return float4(0.5, 0, 0, 1);
}

#define DEFINE_TEC(name, mmdpass) \
	technique name < string MMDPass = mmdpass; > { \
		pass DrawObject { \
			CullMode = NONE; \
			AlphaBlendEnable = FALSE; \
			VertexShader = compile vs_3_0 HitTestVS(); \
			PixelShader = compile ps_3_0 HitTestPS(); \
		} \
	}

DEFINE_TEC(MainTec, "object")
DEFINE_TEC(MainTecSS, "object_ss")

technique EdgeTechnique < string MMDPass = "edge"; > {
    // •`‰æ‚µ‚È‚¢
}

technique ShadowTechnique < string MMDPass = "shadow"; > {
    // •`‰æ‚µ‚È‚¢
}
