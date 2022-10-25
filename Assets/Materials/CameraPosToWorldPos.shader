Shader "Custom/CameraPosToWorldPos" {
 Properties {
        _MainTex ("Base (RGB)", 2D) = "white" {}
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 200
        Pass{
            CGPROGRAM
            #include "UnityCG.cginc"
            #pragma vertex vert_img
            #pragma fragment frag
            sampler2D _CameraDepthTexture;
            float4 GetWorldPositionFromDepthValue( float2 uv, float linearDepth ) 
            {
                float camPosZ = _ProjectionParams.y + (_ProjectionParams.z - _ProjectionParams.y) * linearDepth;
                float height = 2 * camPosZ / unity_CameraProjection._m11;
                float width = _ScreenParams.x / _ScreenParams.y * height;
                float camPosX = width * uv.x - width / 2;
                float camPosY = height * uv.y - height / 2;
                float4 camPos = float4(camPosX, camPosY, camPosZ, 1.0);
                return mul(unity_CameraToWorld, camPos);
            }
            float4 frag( v2f_img o ) : COLOR
            {
                float rawDepth =  SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, o.uv );
                float linearDepth = Linear01Depth(rawDepth);
                float4 worldpos = GetWorldPositionFromDepthValue( o.uv, linearDepth );
                return float4( worldpos.xyz / 255.0 , 1.0 ) ;  
            }
            ENDCG
        }
    }
}
