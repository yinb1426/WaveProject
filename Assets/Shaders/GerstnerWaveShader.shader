Shader "Unlit/GerstnerWaveShader"
{
    Properties
    {
        [Header(Waves)]
        _WaveA ("WaveA (Direction(dx, dy), Steepness, WaveLength)", Vector) = (-1.0, 0.0, 0.35, 1.43)
        _WaveB ("WaveB", Vector) = (-0.3, 0.2, 0.5, 0.21)
        _WaveC ("WaveC", Vector) = (0.2, -1.0, 0.1, 2.5)
        _WaveD ("WaveD", Vector) = (-0.5, -0.1, 0.18, 0.03)
        _WaveE ("WaveE", Vector) = (-2.03, -15, 0.15, 1.5)
        _WaveF ("WaveF", Vector) = (1, -7, 0.25, 0.1)
        _WaveG ("WaveG", Vector) = (-0.2, -0.4, 0.2, 0.2)
        _WaveH ("WaveH", Vector) = (-2, 5, 0.4, 0.4)
        _WaveI ("WaveI", Vector) = (3, -5, 0.2, 0.6)
        _WaveJ ("WaveJ", Vector) = (0.2, 0.4, 0.3, 0.4)
        _WaveK ("WaveK", Vector) = (2, 3, 0.4, 4)
        _WaveL ("WaveL", Vector) = (0.4, -0.6, 0.1, 7)


        [Header(Water)]
        _WaterColor ("Water Color", Color) = (1, 1, 1, 1)

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

            #define PI 3.14159265359

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
                float4 _WaveA;
                float4 _WaveB;
                float4 _WaveC;
                float4 _WaveD;
                float4 _WaveE;
                float4 _WaveF;
                float4 _WaveG;
                float4 _WaveH;
                float4 _WaveI;
                float4 _WaveJ;
                float4 _WaveK;
                float4 _WaveL;
                float4 _WaterColor;
                float _TessellationFactor;
            CBUFFER_END

            void GetGerstnerWave(float4 wave, float2 positionXZ, inout float3 position, inout float3 binormal, inout float3 tangent)
            {
                float k = 2 * PI / wave.w;
                float w = sqrt(9.81 * k);       // Phase Speed
                float a = wave.z / k;           // Amplitude
                float2 d = normalize(wave.xy);  // Direction
                float2 p = positionXZ;          // Position(xz)
                float value = k * dot(d, p) - w * _Time.y;

                // Position
                position.x += d.x * a * cos(value);
                position.z += d.y * a * cos(value);
                position.y += a * sin(value);

                // Binormal
                binormal.x += -d.x * d.y * a * k * sin(value);
                binormal.y += d.y * a * k * cos(value);
                binormal.z += -d.y * d.y * a * k * sin(value);

                // Tangent
                tangent.x += -d.x * d.x * a * k * sin(value);
                tangent.y += d.x * a * k * cos(value);
                tangent.z += -d.x * d.y * a * k * sin(value);
            }

            Varyings vert (Attributes input)
            {
                Varyings output = (Varyings)0;
                output.positionOS = input.positionOS;
                output.uv = input.uv;

                float3 positionOS = (float3)0;
                float3 binormalOS = (float3)0;
                float3 tangentOS = (float3)0;

                GetGerstnerWave(_WaveA, input.positionOS.xz, positionOS, binormalOS, tangentOS);
                GetGerstnerWave(_WaveB, input.positionOS.xz, positionOS, binormalOS, tangentOS);
                GetGerstnerWave(_WaveC, input.positionOS.xz, positionOS, binormalOS, tangentOS);
                GetGerstnerWave(_WaveD, input.positionOS.xz, positionOS, binormalOS, tangentOS);
                GetGerstnerWave(_WaveE, input.positionOS.xz, positionOS, binormalOS, tangentOS);
                GetGerstnerWave(_WaveF, input.positionOS.xz, positionOS, binormalOS, tangentOS);
                GetGerstnerWave(_WaveG, input.positionOS.xz, positionOS, binormalOS, tangentOS);
                GetGerstnerWave(_WaveH, input.positionOS.xz, positionOS, binormalOS, tangentOS);
                GetGerstnerWave(_WaveI, input.positionOS.xz, positionOS, binormalOS, tangentOS);
                GetGerstnerWave(_WaveJ, input.positionOS.xz, positionOS, binormalOS, tangentOS);
                GetGerstnerWave(_WaveK, input.positionOS.xz, positionOS, binormalOS, tangentOS);
                GetGerstnerWave(_WaveL, input.positionOS.xz, positionOS, binormalOS, tangentOS);

                // Position
                input.positionOS.x += positionOS.x;
                input.positionOS.y = positionOS.y;
                input.positionOS.z += positionOS.z;

                // Normal
                binormalOS = float3(binormalOS.x, binormalOS.y, 1.0 + binormalOS.z);
                tangentOS = float3(1.0 + tangentOS.x, tangentOS.y, tangentOS.z);
                float3 normalOS = normalize(cross(binormalOS, tangentOS));

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
                // Blinn-Phong Model
                Light mainLight = GetMainLight();
                float3 lightColor = mainLight.color;
                float3 lightDirWS = normalize(mainLight.direction);
                float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);

                // Ambient - half-lambert
                float NdotL = max(dot(lightDirWS, input.normalWS), 0.0);
                float halfLambert = NdotL; // * 0.5 + 0.5;

                float3 finalColor = _WaterColor.rgb * lightColor * halfLambert;

                float3 halfwayDirWS = normalize(lightDirWS + viewDirWS);
                float NdotH = saturate(dot(input.normalWS, halfwayDirWS));
                float3 specularColor = float3(1.0, 1.0, 1.0) * lightColor * pow(NdotH, 64);
                finalColor += specularColor;

                return float4(finalColor, 1.0);
            }
            ENDHLSL
        }
    }
}
