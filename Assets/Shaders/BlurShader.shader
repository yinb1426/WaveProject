Shader "Unlit/BlurShader"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        _BlurRadius ("Blur Radius", Float) = 25
        _BlurIteration ("Blur Iteration", Float) = 1
        _SpatialWeight ("Spatial Weight", Float) = 10
        _TonalWeight ("Tonal Weight", Float) = 0.1

    }
    SubShader
    {
        Pass
        {
            Tags { 
                "RenderType"="Opaque"
                "RenderPipeline"="UniversalPipeline"
            }
            LOD 200

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _MainTex_TexelSize;

                float _BlurRadius;
                int _BlurIteration;
                float _SpatialWeight;
                float _TonalWeight;                
            CBUFFER_END

            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);

            float GaussianWeight(float d, float sigma)
            {
                return 1.0 / (sigma * sqrt(2.0 * PI)) * exp(-(d * d) / (2.0 * sigma * sigma));
            }

            float4 GaussianWeight(float4 d, float sigma) 
            {
                return 1.0 / (sigma * sqrt(2.0 * PI)) * exp(-(d * d) / (2.0 * sigma * sigma));
            }

            float4 BilateralWeight(float2 currentUV, float2 centerUV, float4 currentColor, float4 centerColor)
            {
                float spacialDifference = length(centerUV - currentUV);
                float4 tonalDifference = centerColor - currentColor;
                return GaussianWeight(spacialDifference, _SpatialWeight) * GaussianWeight(tonalDifference, _TonalWeight);
            }

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS);
                output.positionCS = positionInputs.positionCS;
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                float4 numerator = float4(0, 0, 0, 0);
                float4 denominator = float4(0, 0, 0, 0);

                float4 centerColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);

                for(int iii = -1 * _BlurIteration; iii <= _BlurIteration; iii++)
                {
                    for(int jjj = -1 * _BlurIteration; jjj <= _BlurIteration; jjj++)
                    {
                        float2 offset = float2(iii, jjj) * _BlurRadius;
                        float2 currentUV = input.uv + offset * _MainTex_TexelSize.xy;
                        float4 currentColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, currentUV);

                        float4 weight = BilateralWeight(currentUV, input.uv, currentColor, centerColor);
                        numerator += currentColor * weight;
                        denominator += weight;                        
                    }
                }
                return numerator / denominator;
            }

            ENDHLSL
        }
    }
}
