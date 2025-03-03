Shader "Unlit/GerstnerWaveShader2"
{
    Properties
    {
        [Header(Water)]
        _WaterColor ("Water Color", Color) = (1, 1, 1, 1)
        _DisplacementMap ("Displacement Map", 2D) = "white" {}

        [Header(Tessellation)]
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
                float3 positionWS : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _DisplacementMap_ST;
                float4 _NormalMap_ST;
                float4 _BubblesTexture_ST;
                float4 _WaterColor;
                float _TessellationFactor;
            CBUFFER_END

            sampler2D _DisplacementMap;
            sampler2D _NormalMap;
            TEXTURE2D(_BubblesTexture);     SAMPLER(sampler_BubblesTexture);

            Varyings vert (Attributes input)
            {
                Varyings output = (Varyings)0;
                output.positionOS = input.positionOS;
                output.uv = TRANSFORM_TEX(input.uv, _DisplacementMap);

                float3 displacement = tex2Dlod(_DisplacementMap, float4(output.uv, 0, 0));
                input.positionOS.x += displacement.x;
                input.positionOS.y = displacement.y;
                input.positionOS.z += displacement.z;

                float3 normalOS = tex2Dlod(_NormalMap, float4(output.uv, 0, 0));

                output.positionCS = TransformObjectToHClip(input.positionOS);
                output.positionWS = TransformObjectToWorld(input.positionOS);
                output.normalWS = TransformObjectToWorldNormal(normalOS);
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
                float3 normalOS = tex2Dlod(_NormalMap, float4(input.uv, 0, 0));
                float3 normalWS = TransformObjectToWorldNormal(normalOS);

                // Blinn-Phong Model
                Light mainLight = GetMainLight();
                float3 lightColor = mainLight.color;
                float3 lightDirWS = normalize(mainLight.direction);
                float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);

                // Ambient - half-lambert
                float NdotL = max(dot(lightDirWS, normalWS), 0.0);
                float halfLambert = NdotL; // * 0.5 + 0.5;

                float3 finalColor = _WaterColor.rgb * lightColor * halfLambert;

                float3 halfwayDirWS = normalize(lightDirWS + viewDirWS);
                float NdotH = saturate(dot(normalWS, halfwayDirWS));
                float3 specularColor = float3(1.0, 1.0, 1.0) * lightColor * pow(NdotH, 64);
                finalColor += specularColor;

                return float4(finalColor, 1.0);
            }
            ENDHLSL
        }
    }
}
