Shader "Hidden/scan"

{

	Properties

	{

	  [HideInInspector] _MainTex("MainTex",2D) = "white"{}

	  [HDR]_colorX("ColorX",Color) = (1,1,1,1)

	  [HDR]_colorY("ColorY",Color) = (1,1,1,1)

	  [HDR]_ColorZ("ColorZ",Color) = (1,1,1,1)

	  [HDR]_ColorEdge("ColorEdge",Color) = (1,1,1,1)

	  _width("Width",float) = 0.02

	  _Spacing("Spacing",float) = 1

	  _Speed("Speed",float) = 1



	}

		SubShader

	  {

		  Tags{

		  "RenderPipeline" = "UniversalRenderPipeline"

		  }

		  Cull Off ZWrite Off ZTest Always

		  HLSLINCLUDE

		  #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

		  CBUFFER_START(UnityPerMaterial)

		  float4 _MainTex_ST;

		  CBUFFER_END

		  real4 _colorX;

		  real4 _colorY;

		  real4 _ColorZ;

		  real4 _ColorEdge;

		  float _width;

		  float _Spacing;

		  float _Speed;

		  TEXTURE2D(_MainTex);

		  SAMPLER(sampler_MainTex);

		  TEXTURE2D(_CameraDepthTexture);

		  SAMPLER(sampler_CameraDepthTexture);



		  float4x4 Matrix;

		   struct a2v

		   {

			   float4 positionOS:POSITION;

			   float2 texcoord:TEXCOORD;

		   };

		   struct v2f

		   {

			   float4 positionCS:SV_POSITION;

			   float2 texcoord:TEXCOORD;

			   float3 Dirction:TEXCOORD1;

		   };

		  ENDHLSL

		  pass

		  {

			  HLSLPROGRAM

			  #pragma vertex VERT

			  #pragma fragment FRAG

			  v2f VERT(a2v i)

			  {

				  v2f o;

				  o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

				  o.texcoord = i.texcoord;

				  int t = 0;

				  if (i.texcoord.x < 0.5 && i.texcoord.y < 0.5)

				  t = 0;

				  else if (i.texcoord.x > 0.5 && i.texcoord.y < 0.5)

				  t = 1;

				  else if (i.texcoord.x > 0.5 && i.texcoord.y > 0.5)

				  t = 2;

				  else

				  t = 3;

				  o.Dirction = Matrix[t].xyz;

				  return o;

			  }

			  real4 FRAG(v2f i) :SV_TARGET

			  {

				  real4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.texcoord);

				  half depth = LinearEyeDepth(SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,i.texcoord).x,_ZBufferParams).x;

				  
				  float3 WSpos = _WorldSpaceCameraPos + depth * i.Dirction + float3(0.1,0.1,0.1);//得到世界坐标

				  //return real4(frac(WSpos),1);

				  float3 Line = step(1 - _width,frac(WSpos / _Spacing));//线框

				  //return real4(Line,1);

				  float4 Linecolor = Line.x * _colorX + Line.y * _colorY + Line.z * _ColorZ;//给线框上色

				  return Linecolor + tex;



			  }



			  ENDHLSL

		  }

	  }

} 