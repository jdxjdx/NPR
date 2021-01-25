Shader "NPR/Cel_Shader_Hair"
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
    	
        //使用称为ilmTexture的贴图对角色明暗区域实现手绘风格的控制
    	//其中G绿通道控制漫反射的阴影阈值，R红通道控制高光强度，B蓝通道控制高光范围
    	_IlmTex ("IlmTex", 2D) = "white" {}
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
            sampler2D _IlmTex; float4 _IlmTex_ST;
            
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
	        	float4 ilmTex = tex2D(_IlmTex,TRANSFORM_TEX(i.texcoord, _IlmTex));
	        	
	        	//diffuse
	        	fixed3 diffuse = fixed3(0,0,0);;
	        	fixed NdotL = dot(normalDir, worldLightDir);
	        	fixed halfLambert = NdotL * 0.5 + 0.5;
				half ramp = saturate(_ShadowRange  - halfLambert);
				ramp = smoothstep(0, _ShadowSmooth, ramp);
	        	diffuse = lerp(mainTex, _ShadowColor * mainTex * (1 - _ShadowPower), ramp) * _DiffuseColor.rgb;
	        	
	        	//specular
	        	fixed3 specular = fixed3(0,0,0);
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				fixed NdotH = saturate(dot(normalDir, halfDir));
				fixed SpecularIntensity = pow(NdotH, _SpecularGloss);
	        	fixed specularRange = step(1 -  _SpecularScale, SpecularIntensity);
				specular = mainTex * ilmTex.g * _SpecularColor.rgb * specularRange;

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
