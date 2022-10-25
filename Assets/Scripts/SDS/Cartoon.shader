Shader "Unlit/Cartoon"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpTex("Bump",2D) = "bump"{}
        _NormalScale("NormalScale",Range(0,3)) = 1
        _MainColor("主颜色",Color) = (1,1,1,1)
        _An("暗阈值",Range(0.01,1)) = 0.5
        _Ai("暗强度",Range(0.01,10)) = 0.2
        _In("亮阈值",Range(0.01,1)) = 0.7
        _Li("亮强度",Range(0.01,10)) = 0.2
        _OutLineWid("描边强度",Range(0,0.1)) = 0.00001
        _OutLineColor("描边颜色",Color) = (1,1,1,1)
        _CubeMap("Cube",Cube)=""{}
        _RefFactor("_RefFactor",Range(0,1)) = 0.1
        _Mellic("Mellic",Range(0,1)) = 0
        _Gloss("Gloss",Range(0,4)) = 1
        _ShadowOn("ShadowOn",int) = 0
        _ShadowFactor("Shadow",Range(0,10)) = 5
        [KeywordEnum(ON,OFF)]_ADD_LIGHT_("ADD_LIGHT",float) = 1
        _MaxRecieveLights("MaxAdditionalLights",Range(0,6)) = 4

    }
    SubShader
        {
            Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"
            }
            LOD 300

            Pass
            {
                Zwrite on

                Tags{"LightMode" = "UniversalForward" }

                HLSLPROGRAM
                
                #pragma vertex vert
                #pragma fragment frag

                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
                #pragma multi_compile _ _SHADOW_SOFT
                #pragma multi_compile _ Anti_Aliasing_ON
                #pragma shader_feature _ADD_LIGHT_ON _ADD_LIGHT_OFF
                #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#define ABS(x) x<0? -x:x


                struct appdata
                {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                    float4 normal:NORMAL;
                    float4 tangent:TANGENT;
                };

                struct v2f
                {
                    float4 uv : TEXCOORD0;
                    float4 pos : SV_POSITION;
                    float3 worldPos:TEXCOORD1;
                    float4 normal:NORMAL;
                    float3 tangent:TANGENT;
                    float3 Btangent:TEXCOORD2;
                    float3 viewDir:NORMAL1;

                };

                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
                TEXTURE2D(_BumpTex);
                SAMPLER(sampler_BumpTex);
                float4 _MainTex_ST;
                float4 _BumpTex_ST; 
                float _An;
                float _In;
                float _Ai;
                float _Li;
                real4 _MainColor;
                float _Mellic;
                samplerCUBE _CubeMap;
                float _RefFactor;
                float _ShadowFactor;
                float _Gloss;
                int _MaxRecieveLights;
                int _ShadowOn;
                float _NormalScale;
                v2f vert(appdata v)
                {
                    v2f o;
                    o.pos = TransformObjectToHClip(v.vertex);
                    o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                    o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                    o.uv.zw = TRANSFORM_TEX(v.uv, _BumpTex);
                    o.normal = float4(TransformObjectToWorldNormal(v.normal),0);
                    o.tangent = TransformObjectToWorld(v.tangent);
                    o.Btangent = cross(o.tangent, o.normal.xyz) * v.tangent.w * unity_WorldTransformParams.w;
                    o.viewDir = (_WorldSpaceCameraPos-o.worldPos);
                    return o;
                }

                real4 frag(v2f i) : SV_Target
                {

                    Light l = GetMainLight(TransformWorldToShadowCoord(i.worldPos));
                    float3 L = normalize(l.direction);
                    float3x3 T2W = { i.tangent,i.Btangent,i.normal.xyz };
                    real4 nortex = SAMPLE_TEXTURE2D(_BumpTex, sampler_BumpTex, i.uv.zw);
                    float3 normalTS = UnpackNormalScale(nortex, _NormalScale);
                    normalTS.z = pow((1 - pow(normalTS.x, 2) - pow(normalTS.y, 2)), 0.5);
                    float3 norWS = mul(normalTS, T2W);
                    float3 N = normalize(norWS);

                    float d = max(0,dot(N,L));
                    real4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv.xy);

                    if (d < _An)
                        col = col * (1 - _Ai) * _MainColor * real4(l.color,1);
                    else if (d > _In)
                        col = col * (1 + _Li) * _MainColor * real4(l.color, 1);
                    else
                        col = col * _MainColor * real4(l.color, 1);

                    float3 R = reflect(-L, N);
                    float3 V = i.viewDir;
                    float3 refDir = reflect(-V, N);
                    R = normalize(R);
                    V = normalize(V);

                    float specularScale = pow(max(0,dot(R, V)), _Gloss)* l.shadowAttenuation;
                    col.rgb += l.color * _Mellic * specularScale;

                    real4 refCol = texCUBE(_CubeMap, refDir);
                    col = lerp(col, refCol, _RefFactor);


                    float shadow = l.shadowAttenuation;
                    shadow = max(0.4, shadow);
                    
                    if(ABS(shadow-1)>0.1)
                        shadow = 1-1/pow(_ShadowFactor, shadow);

                    if (_ShadowOn == 0)
                        shadow = 1;
                    float4 maincol = col*shadow;
                    real4 addlight = (0, 0, 0, 1);

                    
                    int lights = GetAdditionalLightsCount();
                    lights = min(lights, _MaxRecieveLights);
                    for (int j = 0; j < lights; j++) {
                        Light al = GetAdditionalLight(j, i.worldPos);
                        float3 addLightDir = normalize(al.direction);
                        addlight += (0.5+dot(addLightDir, N) * 0.5) * real4(al.color, 1)*al.distanceAttenuation*al.shadowAttenuation;
                    }

                    

                    return maincol*addlight;

                }
                ENDHLSL
            }
            
            /*Pass
            {
                Name "OUTLINE"
                Cull Front
                Zwrite On

                HLSLPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                struct a2v
                {
                    float4 vertex       : POSITION;
                    float3 normal       : NORMAL;
                };

                struct v2f
                {
                    float4 pos : SV_POSITION;
                };


                float _OutLineWid;
                half4 _OutlineColor;

                v2f vert(a2v v)
                {
                    v2f o;
                    v.vertex.xyz += _OutLineWid * v.normal;
                    o.pos = TransformObjectToHClip(v.vertex);
                    return o;
                }

                real4 frag(v2f i) : SV_Target
                {
                    return _OutlineColor;
                }
                ENDHLSL
            }*/

            Pass
            {
                Name "ShadowCaster"
                Tags{"LightMode" = "ShadowCaster"}

                ZWrite On
                ZTest LEqual
                Cull[_Cull]

                HLSLPROGRAM
                // Required to compile gles 2.0 with standard srp library
                #pragma prefer_hlslcc gles
                #pragma exclude_renderers d3d11_9x
                #pragma target 2.0

                // -------------------------------------
                // Material Keywords
                #pragma shader_feature _ALPHATEST_ON

                //--------------------------------------
                // GPU Instancing
                #pragma multi_compile_instancing
                #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

                #pragma vertex ShadowPassVertex
                #pragma fragment ShadowPassFragment

                #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
                ENDHLSL
            }
        }
        Fallback "Specular"
}
