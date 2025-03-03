Shader "Unlit/BilinearShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TessellationFactor ("Tessellation Factor", Range(1, 64)) = 4
    }
    SubShader
    {
        Tags { 
            "RenderType"="Opaque"
            "RenderPipeline"="UniversalPipeline"
        }
        LOD 200

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma domain domain
            #pragma hull hull
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 positionOS : TEXCOORD1;
                float displacement : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _MainTex_TexelSize;
                float _TessellationFactor;
            CBUFFER_END

            sampler2D _MainTex;

            Varyings vert (Attributes input)
            {
                Varyings output = (Varyings)0;
                output.positionOS = input.positionOS;
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);

                float2 texelSize = _MainTex_TexelSize.zw;
                float2 uvTopLeft = floor(output.uv * texelSize) / texelSize;
                float topLeft = tex2Dlod(_MainTex, float4(uvTopLeft, 0.0, 0.0)).r;
                float topRight = tex2Dlod(_MainTex, float4(uvTopLeft.x + 1.0 / texelSize.x, uvTopLeft.y, 0.0, 0.0)).r;
                float bottomLeft = tex2Dlod(_MainTex, float4(uvTopLeft.x, uvTopLeft.y + 1.0 / texelSize.y, 0.0, 0.0)).r;
                float bottomRight = tex2Dlod(_MainTex, float4(uvTopLeft.x + 1.0 / texelSize.x, uvTopLeft.y + 1.0 / texelSize.y, 0.0, 0.0)).r;
                float2 f = frac(output.uv * texelSize);
                
                output.displacement = lerp(lerp(topLeft, topRight, f.x), lerp(bottomLeft, bottomRight, f.x), f.y);
                input.positionOS.y += output.displacement;
                output.positionCS = TransformObjectToHClip(input.positionOS);

                return output;
            }

            struct TessellationFactors 
            {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            TessellationFactors HullShaderConstant(InputPatch<Varyings, 3> v)
            {
                TessellationFactors output;
                output.edge[0] = _TessellationFactor;
                output.edge[1] = _TessellationFactor;
                output.edge[2] = _TessellationFactor;
                output.inside = _TessellationFactor;
                return output;
            }

            [domain("tri")]
            [outputcontrolpoints(3)]
            [outputtopology("triangle_cw")]
            [partitioning("integer")]
            [patchconstantfunc("HullShaderConstant")]
            Varyings hull(InputPatch<Varyings, 3> patch, uint id : SV_OutputControlPointID)
            {
                return patch[id];
            }

            [domain("tri")]
            Varyings domain(TessellationFactors tessFactors, const OutputPatch<Varyings, 3> patch, float3 bary : SV_DomainLocation)
            {
                Attributes v;
                v.positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z;
                v.uv = patch[0].uv * bary.x + patch[1].uv * bary.y + patch[2].uv * bary.z;

                Varyings o = vert(v);
                return o;
            }

            float4 frag (Varyings input) : SV_Target
            {
                float displacement = input.displacement;
                return float4(displacement, displacement, displacement, 1.0);
            }
            ENDHLSL
        }
    }
}
