
// shader taken from https://blog.csdn.net/qq_26722425/article/details/77341284
//边缘检测Shader + UV移动 + 渐变图遮罩 + 双Pass + EasyAR

Shader "Unlit/ScannerShader" {
	Properties{
		_MainTex("Texture", 2D) = "white" {}
	_MaskTex("MaskTex", 2D) = "white" {}
	_EdgeOnly("Edge Only", Float) = 1.0
		_EdgeColor("Edgge Color", Color) = (0,0,0,1)
		_BackgroundColor("Background Color", Color) = (1,1,1,0)
		_Thickness("Thickness", Float) = 1.0
		_SpeedFactor("Speed Factor", Float) = -0.8
	}
		SubShader
	{
		Tags{ "RenderType" = "Opaque" }
		cull off
		LOD 100
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
	{
		CGPROGRAM
#pragma vertex vert
#pragma fragment frag
# include "UnityCG.cginc"

		struct appdata {
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
	};

	struct v2f {
		float2 uv : TEXCOORD0;
		float4 vertex : SV_POSITION;
	};

	sampler2D _MainTex;
	float4 _MainTex_ST;

	v2f vert(appdata v) {
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv = TRANSFORM_TEX(v.uv, _MainTex);
		return o;
	}

	fixed4 frag(v2f i) : SV_Target
	{
		fixed4 col = tex2D(_MainTex, i.uv);
	UNITY_APPLY_FOG(i.fogCoord, col);
	return col;
	}
		ENDCG
	}

		Pass
	{
		CGPROGRAM
#pragma vertex vert
#pragma fragment frag

# include "UnityCG.cginc"

		struct appdata {
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
	};

	struct v2f {

		float2 maskuv : TEXCOORD0;
		float2 uv[9] : TEXCOORD1;
		float4 vertex : SV_POSITION;
	};

	sampler2D _MainTex;
	sampler2D _MaskTex;
	float4 _MainTex_TexelSize;
	fixed _EdgeOnly;
	fixed4 _EdgeColor;
	fixed4 _BackgroundColor;
	fixed _Thickness;
	fixed _SpeedFactor;

	fixed luminance(fixed4 color)
	{
		return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
	}

	half Sobel(v2f i) {
		const half Gx[9] = { -1, -2, -1, 0, 0, 0, 1, 2, 1 };
		const half Gy[9] = { -1, 0, 1, -2, 0, 2, -1, 0, 1 };

		half texColor;
		half edgeX = 0;
		half edgeY = 0;
		for (int it = 0; it < 9; it++)
		{
			texColor = luminance(tex2D(_MainTex, i.uv[it]));
			edgeX += texColor * Gx[it];
			edgeY += texColor * Gy[it];
		}

		
		half edge = 1 - abs(edgeX) - abs(edgeY);
		return edge;
	}

	v2f vert(appdata v) {
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);

		half2 uv = v.uv;


		// this controls the direction and speed
		//o.maskuv = v.uv + frac(fixed2(0, -0.8 *_Time.y));
		o.maskuv = v.uv + frac(fixed2(0, _SpeedFactor *_Time.y));


		// takes nine points around in a cube and eventually use the 4th in centre
		o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1, -1) * _Thickness;
		o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0, -1) * _Thickness;
		o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1, -1) * _Thickness;
		o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 0) * _Thickness;
		o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0, 0) * _Thickness;
		o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1, 0) * _Thickness;
		o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1, 1) * _Thickness;
		o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0, 1) * _Thickness;
		o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1, 1) * _Thickness;

		//o.uv = TRANSFORM_TEX(v.uv, _MainTex);
		return o;
	}

	fixed4 frag(v2f i) : SV_Target
	{
		// edge值越小，表示越可能是边缘点
		half edge = Sobel(i);

	fixed4 maskColor = tex2D(_MaskTex, i.maskuv);

	// linear interpolation between _EdgeColor and _MainTex by interpolant of edge
	// i.uv[4]是0，0偏移，等同于UV坐标
	// 边缘+彩色
	fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[4]), edge);

	// 边缘
	fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);
	
	// linear interpolation between first and second variable by interpolant third variable
	// 边缘彩色混合
	fixed4 col = lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
	// fixed4 col = lerp(withEdgeColor, tex2D(_MainTex, i.uv[4]), edge);
	
	
	// x > left border, x < right border, y > bottom border, y < top border
	if (i.uv[4].x>0.2  &&  i.uv[4].x<0.8  &&  i.uv[4].y>0.2  &&  i.uv[4].y<0.8)
		return fixed4(col.rgb, col.a* (1.0 - maskColor.r));
	return fixed4(col.rgb, 0);

	//return fixed4(col.rgb, col.a* (1.0 - maskColor.r));

	}
		ENDCG
	}
	}
}