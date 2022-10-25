Shader "Unlit/Glass"
{
    Properties
    {
        _BumpTex ("Bump", 2D) = "bump" {}
        _Color("Color",Color) = (1,1,1,1)
        _NormalScale("NormalScale",Range(0,3)) = 1
        _Factor("Factor",Range(1,10000)) = 1
    }
    SubShader
    {
        Tags { 
            "RenderType" = "Opaque"
            "Queue" = "Transparent"
        }
        LOD 300

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"



            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 tangent:TANGENT;
                float4 normal:NORMAL;

            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
                float3 tangent:TANGET;
                float3 btangent:TEXCOORD1;
                float4 scrUV:TEXCOORD2;
                float3 worldPos:TEXCOORD3;
                float4 vertex : SV_POSITION;
            };

            TEXTURE2D(_BumpTex);
            SAMPLER(sampler_BumpTex);
            float4 _BumpTex_ST;
            float _NormalScale;
            real4 _Color;
            float4 _CameraColorTexture_TexelSize;
            SAMPLER(_CameraColorTexture);
            float _Factor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.scrUV = ComputeScreenPos(o.vertex);
                o.normal = normalize(TransformObjectToWorldNormal(v.normal));
                o.tangent = normalize(TransformObjectToWorldDir(v.tangent));
                o.btangent = cross(o.tangent, v.tangent.xyz) * v.tangent.w * unity_WorldTransformParams.w;
                o.worldPos = TransformWorldToObject(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _BumpTex);
                return o;
            }

            real4 frag(v2f i) : SV_Target
            {
                real4 normal = SAMPLE_TEXTURE2D(_BumpTex,sampler_BumpTex,i.uv)*_Color;
                float3 nor = UnpackNormalScale(normal, _NormalScale);


                float3x3 T2W = {i.tangent,i.btangent,i.normal};
                nor = mul(nor, T2W);
                float2 bias = nor.xy * _CameraColorTexture_TexelSize*_Factor;


                real4 col = tex2D(_CameraColorTexture,i.scrUV.xy/i.scrUV.w+bias);

                return col;
            }
            ENDHLSL
        }
    }
}
