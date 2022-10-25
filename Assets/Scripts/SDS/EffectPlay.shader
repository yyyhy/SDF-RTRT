Shader "Unlit/EffectPlay"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Frame("Frame",Range(30,60)) = 30
        _Tile("Tile",Vector) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };


            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;
            float2 _Tile;
            int _Frame;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            real4 frag(v2f i) : SV_Target
            {
                float2 uv;
            uv.x = i.uv.x / _Tile.x + frac(floor(_Time.y*_Frame) / _Tile.x);
            uv.y = i.uv.y / _Tile.y + frac(floor(_Time.y * _Frame * _Time.x) / _Time.y);

            return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
            }
            ENDHLSL
        }
    }
}
