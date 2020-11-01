//
// half_lambert: 拡散光のモデルとして Half Lambert を使ったシェーダー
//

#include "half_lambert.fxsub"

float4 BaseColor(float2 tex, uniform bool useTexture)
{
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
	return baseColor;
}
