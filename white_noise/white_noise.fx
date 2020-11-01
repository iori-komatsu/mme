//
// white_noise: ホワイトノイズを表示するシェーダー
//

#include "../half_lambert/half_lambert.fxsub"

float Time : TIME < bool SyncInEditMode=true; >;

float Hash13(float3 p3)
{
	float x = dot(p3, float3(49.97, 163.6, 12.21));
	return frac(sin(x) * 43758.5453123);
}

float4 BaseColor(float2 tex, uniform bool useTexture)
{
	float h = Hash13(float3(tex, fmod(Time, 31)));
	return float4(h, h, h, 1);
}
