Shader "Unlit/SSRShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _StepSize ("Step Size", Float) = 0.3
        _StepCount ("Step Count", Int) = 10
        _Thickness ("Thickness", Float) = 15.0
    }
    SubShader
    {
        Tags {
            "Queue"="Geometry"
            "RenderType"="Opaque"
            "RenderPipeline"="UniversalPipeline" 
        }
        LOD 200
        ZWrite Off
        ZTest Always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 viewVector : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _CameraNormalsTexture_ST;
                float4 _CameraDepthTexture_ST;

                float _StepSize;
                int _StepCount;
                float _Thickness;
            CBUFFER_END

            TEXTURE2D(_MainTex);                SAMPLER(sampler_MainTex);
            TEXTURE2D(_CameraNormalsTexture);   SAMPLER(sampler_CameraNormalsTexture);
            TEXTURE2D(_CameraOpaqueTexture);    SAMPLER(sampler_CameraOpaqueTexture);
            
            samplerCUBE unity_Skybox_Cubemap;

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS);
                output.positionCS = positionInputs.positionCS;
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);

                float3 screenPos = float3(output.uv * 2.0 - 1.0, -1);
                float3 farPos = screenPos * _ProjectionParams.z;
                output.viewVector = mul(unity_CameraInvProjection, farPos.xyzz).xyz;
                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                // 深度图重建世界坐标
                float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, input.uv).r;
                depth = Linear01Depth(depth, _ZBufferParams);
                float3 positionVS = input.viewVector * depth;
                float3 positionWS = mul(unity_CameraToWorld, float4(positionVS, 1)).xyz;

                float3 normalWS = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, input.uv).rgb;
                float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - positionWS);
                float3 reflectDirWS = normalize(reflect(-viewDirWS, normalWS));

                float3 finalColor = (float3)0;

                UNITY_LOOP
                for(int iii = 0; iii < _StepCount; iii++)
                {
                    float3 newPositionWS = positionWS + reflectDirWS * _StepSize * (float)iii;
                    float4 newPositionCS = mul(UNITY_MATRIX_VP, newPositionWS); // TransformWorldToHClip(newPositionWS);
                    float2 uv = float2(newPositionCS.x, newPositionCS.y * _ProjectionParams.x) / newPositionCS.w * 0.5 + 0.5;  
                    float newDepth = newPositionCS.w;  
                    float rawDepth = LinearEyeDepth(SampleSceneDepth(uv), _ZBufferParams);
                    if(rawDepth < newDepth && newDepth < rawDepth + _Thickness)
                    {
                        finalColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, uv).rgb;
                        break;
                    }
                }

                return float4(finalColor, 1.0);
            }
            ENDHLSL
        }
    }
}
