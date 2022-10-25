// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// create by JiepengTan 2018-04-12  email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/Voronoi"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TileNum ("TileNum", Range(1,100)) = 5
        _DiffuseRatio("_Diffuse",Range(0,10))=1
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" }
        
        LOD 200

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase 
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
			#include "AutoLight.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal:NORMAL;
                SHADOW_COORDS(2)
            };
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _TileNum ;
            sampler2D _NoiseTex; 
            float _R;
            float _Ra;
            float _DiffuseRatio;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal=mul(float4(v.normal,0),unity_WorldToObject).xyz;
                TRANSFER_SHADOW(o);
                return o;
            }
            
            float4 hash4(float2 p)
            {
                float t1 = 1.0 + dot(p, float2(37.0, 17.0));    
                float t2 = 2.0 + dot(p, float2(11.0, 47.0));    
                float t3 = 3.0 + dot(p, float2(41.0, 29.0));    
                float t4 = 4.0 + dot(p, float2(23.0, 31.0));    
                return frac(sin(float4(t1, t2, t3, t4)) * 103.0);
            }
            float4 wnoise(float2 p,float time) {
                float2 n = floor(p);
                float2 f = frac(p);

                float2 dx=ddx(p);
                float2 dy=ddy(p);
           
                float4 col;
                float wg;
                float2 m = float2(0.,0.);
                for (int i = -1;i<=1;i++) {
                    for (int j = -1;j<=1;j++) {
                        
                        float2 g = float2(i, j);
                       
                       float4 o=hash4(g+n);


                        //o = 0.5+0.5*sin(time+6.28*o);
                        float2 r = g-f+o.xy;
                        float d = dot(r, r);
                        float w=exp(-d*5);
                        col+=tex2D(_MainTex,abs(sin(p*o.zw+o.xy)),dx,dy)*w;
                        wg+=w;
                    }
                }
                return col/wg;
            }
            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = _TileNum * i.uv;
                float time = _Time.y;
                float4 val = wnoise(uv,time);
                fixed shadow = SHADOW_ATTENUATION(i);
                float3 normalDir=normalize(i.normal);
                float3 lightDir=normalize(_WorldSpaceLightPos0.xyz);
                float3 diffuse=_LightColor0.rgb*_DiffuseRatio*max(0,dot(normalDir,lightDir));
                float4 color=float4(diffuse,1.0)+UNITY_LIGHTMODEL_AMBIENT;



                return float4((color*val).xyz,1)*shadow;
            }           
            ENDCG
        }

        Pass{
            Cull front
        }
        Pass 
		{
            //此pass就是 从默认的fallBack中找到的 "LightMode" = "ShadowCaster" 产生阴影的Pass
			Tags { "LightMode" = "ShadowCaster" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing // allow instanced shadow pass for most of the shaders
			#include "UnityCG.cginc"

			struct v2f {
				V2F_SHADOW_CASTER;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f vert( appdata_base v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}

			float4 frag( v2f i ) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG

		}
    }
    FallBack"Diffuse"
}

