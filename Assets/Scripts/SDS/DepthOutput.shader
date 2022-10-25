Shader "Hidden/DepthOutput"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

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
                real4 col : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                real4 col : COLOR;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = v.uv;
                o.col = v.col;
                return o;
            }

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);
       

            half Luminance(half3 rgb) {
                return dot(rgb, half3(0.2126, 0.7152, 0.0722));
            }

            real4 frag(v2f i) : SV_Target
            {
                real4 tex = SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,i.uv);
            return tex;
            }
            ENDHLSL
        }
    }
}