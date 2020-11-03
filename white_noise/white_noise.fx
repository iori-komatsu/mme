//
// white_noise: ホワイトノイズを表示するシェーダー
//

#include "../half_lambert/half_lambert.fxsub"

float Time : TIME < bool SyncInEditMode=true; >;

float Hash13(float3 p3)
{
	float3 e;
	p3  = frexp(p3, e);
	p3 += e * (1.0 / 129.0);
	p3  = frac(p3 * 1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.x + p3.y) * p3.z);
}

float4 BaseColor(float2 tex, uniform bool useTexture)
{
	float h = Hash13(float3(tex, Time));
	return float4(h, h, h, 1);
}
