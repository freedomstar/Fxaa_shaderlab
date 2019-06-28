Shader "Freedom/FreedomFxaa"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		FXAA_REDUCE("FXAA_REDUCE",Range(0.001,8))=0.0001
		FXAA_SPAN_MAX("FXAA_SPAN_MAX",Range(0.1,15))=8
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				half2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				half2 v_rgbNW: TEXCOORD1;
				half2 v_rgbNE: TEXCOORD2;
				half2 v_rgbSW: TEXCOORD3;
				half2 v_rgbSE: TEXCOORD4;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _MainTex_TexelSize; 
		    half  FXAA_REDUCE;
			half  FXAA_SPAN_MAX;
			
			float4 fxaa(sampler2D tex, float2 uv,float2 v_rgbNW, float2 v_rgbNE, float2 v_rgbSW, float2 v_rgbSE) 
			{
				float4 color;
				half3 rgbNW = tex2D(tex, v_rgbNW).xyz;
				half3 rgbNE = tex2D(tex, v_rgbNE).xyz;
				half3 rgbSW = tex2D(tex, v_rgbSW).xyz;
				half3 rgbSE = tex2D(tex, v_rgbSE).xyz;
				half3 luma = half3(0.299, 0.587, 0.114);
				half lumaNW = dot(rgbNW, luma);
				half lumaNE = dot(rgbNE, luma);
				half lumaSW = dot(rgbSW, luma);
				half lumaSE = dot(rgbSE, luma);
				half2 dir;
				dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
				dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));
				dir = min(half2(FXAA_SPAN_MAX, FXAA_SPAN_MAX), max(half2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),dir*FXAA_REDUCE)) * _MainTex_TexelSize.xy;
				float3 rgbA = 0.5 * (tex2D(tex, uv + dir * 0.05).xyz +tex2D(tex, uv + dir * (-0.05)).xyz);
				float3 rgbB = rgbA * 0.5 + 0.25 * (tex2D(tex, uv + dir * -0.5).xyz + tex2D(tex, uv + dir * 0.5).xyz);
				color = float4(rgbB, 1);
				return color;
			}

			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.v_rgbNW= o.uv + (fixed2(-1.0,-1.0)*_MainTex_TexelSize.xy);
				o.v_rgbNE= o.uv + (fixed2(1.0, -1.0)*_MainTex_TexelSize.xy);
				o.v_rgbSW= o.uv + (fixed2(-1.0, 1.0)*_MainTex_TexelSize.xy);
				o.v_rgbSE= o.uv + (fixed2(1.0, 1.0)*_MainTex_TexelSize.xy);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				return fxaa(_MainTex, i.uv, i.v_rgbNW, i.v_rgbNE, i.v_rgbSW, i.v_rgbSE);
			}
			ENDCG
		}
	}
}
