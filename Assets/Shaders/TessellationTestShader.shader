Shader "Unlit/TessellationTestShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        [Header(Tessellation)]
        _TessellationFactor ("Tessellation Factor", Range(1, 64)) = 4.0
    }
    SubShader
    {
        Tags { 
            "RenderType"="Opaque"
            "RenderPipeline"="UniversalPipeline"
        }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma domain domain
            #pragma hull hull
            #pragma fragment frag

            #pragma target 4.6

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
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;

                float _TessellationFactor;
            CBUFFER_END

            TEXTURE2D(_MainTex);          SAMPLER(sampler_MainTex);

            Varyings vert (Attributes input)
            {
                Varyings output = (Varyings)0;
                output.positionCS = TransformObjectToHClip(input.positionOS);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                output.positionOS = input.positionOS;
                return output;
            }

            struct TessellationFactors
            {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            // 输出细分常量
            TessellationFactors HullShaderConstant(InputPatch<Varyings, 3> v)
            {
                TessellationFactors output;
                output.edge[0] = _TessellationFactor;
                output.edge[1] = _TessellationFactor;
                output.edge[2] = _TessellationFactor;
                output.inside = _TessellationFactor;
                return output;
            }

            [domain("tri")] // 确定处理的图元是三角形
            [outputcontrolpoints(3)] // 确定输出3个控制点，即三角形3个顶点
            [outputtopology("triangle_cw")] // 输出的三角形拓扑结构是顺时针排列
            [partitioning("integer")] // 使用整数分区
            [patchconstantfunc("HullShaderConstant")] // 使用HullShaderConstant计算细分常量
            Varyings hull(InputPatch<Varyings, 3> patch, uint id : SV_OutputControlPointID)
            {
                return patch[id];
            }

            [domain("tri")] // 确定处理的图元是三角形
            Varyings domain(TessellationFactors tessFactors, const OutputPatch<Varyings, 3> patch, float3 bary : SV_DomainLocation)
            {
                // 对细分点做插值操作
                Attributes v;
                v.positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z;
                v.uv = patch[0].uv * bary.x + patch[1].uv * bary.y + patch[2].uv * bary.z;

                // 对新的插值点过VS，提供给之后的着色器
                Varyings o = vert(v);
                return o;
            }

            float4 frag (Varyings input) : SV_Target
            {
                float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                return col;
            }
            ENDHLSL
        }
    }
}
