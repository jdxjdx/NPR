Shader "NPR/Cel_Shader_Body_Use_RampTexture"
{
    Properties
    {
    	[Space(20)]
    	[Header(Outline)]
	    _OutlineWidth ("Outline Width", Range(0, 1)) = 0.24
        _OutLineColor ("OutLine Color", Color) = (0.5,0.5,0.5,1)
        
    	[Space(20)]
        _MainTex ("Texture", 2D) = "white" {}
    	
    	[Space(20)]
    	[Header(Diffuse)]
        _DiffuseColor("Diffuse Color", Color) = (1,1,1,1)
    	
    	[Space(20)]
    	[Header(Shadow)]
	    _ShadowColor ("Shadow Color", Color) = (0.7, 0.7, 0.8)
		_ShadowRange ("Shadow Range", Range(0.2, 1)) = 0.5
        _ShadowSmooth("Shadow Smooth", Range(0, 0.1)) = 0.05
    	_ShadowPower("Shadow Power", Range(0, 1)) = 0.8
    	
    	[Space(20)]
    	[Header(Specular)]
        _SpecularColor("Specular Color", Color) = (1,1,1,1)
        _SpecularScale("Specular Scale", Range(0, 1)) = 0.01
        _SpecularGloss("Specular Gloss", Range(8.0, 256)) = 20
    	
	    [Space(20)]
    	[Header(RimLight)]
    	[Toggle]_selected("RimLight On", Int) = 0
		_RimColor("Rim Color", Color) = (1,1,1,1)
		_RimAmount("Rim Amount", Range(0, 1)) = 0.042
		_RimThreshold("Rim Threshold", Range(0, 10)) = 6
    	
	    _Ramp("Ramp Texture", 2D) = "bump"{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        UsePass "NPR/NormalExpandOutline/OUTLINE" 
        pass
        {
            Tags {"LightMode"="ForwardBase"}

            Cull Back
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _SELECTED_ON
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            sampler2D _MainTex;float4 _MainTex_ST;
            sampler2D _Ramp;float4 _Ramp_ST;
            
            fixed4 _DiffuseColor;
            
            fixed4 _SpecularColor;
            fixed _SpecularGloss;
            fixed _SpecularScale;
            
			fixed3 _ShadowColor;
            fixed _ShadowRange;
            fixed _ShadowSmooth;
            fixed _ShadowPower;

            fixed4 _RimColor;
			fixed _RimAmount;
			fixed _RimThreshold;

            struct a2v
            {
                float4 vertex : POSITION;
                fixed3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                fixed3 worldNormal : TEXCOORD2;
            };

            v2f vert(a2v v)
	        {
	            v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
	            o.worldNormal = UnityObjectToWorldNormal(v.normal);
	            o.worldPos = mul(unity_ObjectToWorld, v.vertex);
	            o.texcoord = v.texcoord;
	            return o;
            }

            fixed4 frag(v2f i) : SV_TARGET 
	        {
                float3 normalDir = normalize(i.worldNormal);
	            float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
	            float3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
	        	float4 mainTex = tex2D(_MainTex,TRANSFORM_TEX(i.texcoord, _MainTex));
	        	
	        	//diffuse
	        	fixed3 diffuse = fixed3(0,0,0);;
	        	fixed NdotL = dot(normalDir, worldLightDir);
	        	fixed halfLambert = NdotL * 0.5 + 0.5;
	        	diffuse = mainTex.rgb * _DiffuseColor.rgb * tex2D(_Ramp, float2(halfLambert, halfLambert)).rgb;
	        	
	        	//specular
	        	fixed3 specular = fixed3(0,0,0);
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                float spec = dot(normalDir, halfDir);
                float w = fwidth(spec) * 2.0;
                spec = lerp(0, 1, smoothstep(-w, w, spec + _SpecularScale - 1)) * step(0.0001, _SpecularScale);
				specular = _SpecularColor.rgb * spec * mainTex;

				fixed3 rim = fixed3(0,0,0);
				#ifdef _SELECTED_ON
	        		float rimDot = pow(1 - dot(viewDir, normalDir), _RimThreshold);
					float rimIntensity = rimDot * NdotL;
					rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);
					rim = mainTex * rimIntensity * _RimColor.rgb;
				#endif

	        	fixed3 color = rim + specular + diffuse;
	            
                return fixed4(color * _LightColor0,1);
            }

            ENDCG
        }
    }
}
