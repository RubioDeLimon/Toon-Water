Shader "RubioDeLimon/CartoonWater" {
    Properties{
		// Main
        [Header(Main)]_Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo (RGB)", 2D) = "white" {}
		_FoamTex ("Foam", 2D) = "white" {}
    	_Glossiness("Smoothness", Range(0,1)) = 0.5
        _Metallic("Metallic", Range(0,1)) = 0.0
		_ScrollX ("Scroll X", Range(-5,5)) = 1
		_ScrollY ("Scroll Y", Range(-5,5)) = 1
		// Shoreline
		[Header(Shoreline)]
        _BlendColor("Blend Color", Color) = (1,1,1,1)
        _InvFade("Soft Factor", Range(0.01,3.0)) = 1.0
        _FadeLimit("Fade Limit", Range(0.00,1.0)) = 0.3
		// Waves
		[Header(Waves)]
		_Freq ("Frequency", Range(0,5)) = 3
		_Speed ("Speed", Range(0,100)) = 10
		_Amp ("Amplitude", Range(0,1)) = 0.5
    }

    SubShader{
        Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard vertex:vert alpha:fade nolightmap

        // Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

        sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
			float4 screenPos;
			float eyeDepth;
			float4 vertColor;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
		fixed4 _BlendColor;
		sampler2D_float _CameraDepthTexture;
		float4 _CameraDepthTexture_TexelSize;
		sampler2D _FoamTex;
		float _ScrollX;
		float _ScrollY;

		float _Freq;
		float _Speed;
		float _Amp;

		float _FadeLimit;
		float _InvFade;

		void vert(inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			COMPUTE_EYEDEPTH(o.eyeDepth);
			float t = _Time * _Speed;
			float waveHeight = sin(t + v.vertex.x * _Freq) * _Amp + sin(t*2 + v.vertex.x * _Freq*2) * _Amp;
			float waveHeightz = sin(t + v.vertex.z * _Freq) * _Amp + sin(t*2 + v.vertex.z * _Freq*2) * _Amp;
			v.vertex.y = v.vertex.y + waveHeight + waveHeightz;
			v.normal = normalize(float3(v.normal.x + waveHeight, v.normal.y, v.normal.z));
			o.vertColor = waveHeight +2;
		}

		void surf(Input IN, inout SurfaceOutputStandard o) {
			_ScrollX *= _Time;
			_ScrollY *= _Time;
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex + float2(_ScrollX, _ScrollY)) * _Color;
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;

			float rawZ = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos));
			float sceneZ = LinearEyeDepth(rawZ);
			float partZ = IN.eyeDepth;

			float fade = 1.0;
			if (rawZ > 0.0) // Make sure the depth texture exists
				fade = saturate(_InvFade * (sceneZ - partZ));
			//o.Alpha = c.a * fade; //(original line)
			//the rest are lines I've input
			o.Alpha = 1;

			//float3 water = (tex2D (_MainTex, IN.uv_MainTex + float2(_ScrollX, _ScrollY))).rgb;
			float3 foam = (tex2D (_FoamTex, IN.uv_MainTex + float2(_ScrollX/2.0, _ScrollY/2.0))).rgb;
			
			if(fade<_FadeLimit)
			o.Albedo = c.rgb * fade + _BlendColor * (1 - fade);

			o.Albedo += (foam/8);
			o.Alpha = _Color.a;
    	}
    	ENDCG
    }
}