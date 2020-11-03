//
// white_noise: ホワイトノイズを表示するシェーダー
//

#include "../half_lambert/half_lambert.fxsub"

float Time : TIME < bool SyncInEditMode=true; >;

float  hash(float  v) { return frac(sin(v * 78.233) * 43758.5453123); }
float2 hash(float2 v) { return frac(sin(v * 78.233) * 43758.5453123); }
float3 hash(float3 v) { return frac(sin(v * 78.233) * 43758.5453123); }
float4 hash(float4 v) { return frac(sin(v * 78.233) * 43758.5453123); }

float3 hash33(float3 v)
{
	float3 e;
	v = frexp(v, e);
	v += e * (1.0 / 129.0);
	return hash(hash(hash(v.x + float3(0, 4.31265, 9.38974)) + v.y) + v.z);
}

float4 BaseColor(float2 tex, uniform bool useTexture)
{
	float3 h = hash33(float3(tex, Time).yzx);
	return float4(h, 1);
}
