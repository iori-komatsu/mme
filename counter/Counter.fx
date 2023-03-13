#include "CounterCommon.fxsub"

//-----------------------------------------------------------------------------

void VS(
	float4 pos : POSITION,
	float2 coord : TEXCOORD0,
	out float4 oPos : POSITION,
	out float2 oCoord : TEXCOORD0
) {
	CalculatePosition(coord, oPos, oCoord);
}

float4 PS(float2 coord : TEXCOORD0) : COLOR {
	return CalculateColor(coord);
}

//-----------------------------------------------------------------------------

#define MAIN_TEC(name, mmdpass) \
	technique name < string MMDPass = mmdpass; > { \
		pass DrawObject { \
			VertexShader = compile vs_3_0 VS(); \
			PixelShader  = compile ps_3_0 PS(); \
		} \
	}

MAIN_TEC(MainTec, "object")
MAIN_TEC(MainTecBS, "object_ss")

technique EdgeTec < string MMDPass = "edge"; > {
    // •`‰æ‚µ‚È‚¢
}

technique ShadowTec < string MMDPass = "shadow"; > {
    // •`‰æ‚µ‚È‚¢
}
