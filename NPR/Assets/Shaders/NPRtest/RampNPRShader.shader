﻿Shader "NPR/RampNPRShader"
{
    Properties
    {
	    _OutlineWidth ("Outline Width", Range(0.01, 1)) = 0.24
        _OutLineColor ("OutLine Color", Color) = (0.5,0.5,0.5,1)
        
        _MainTex ("Texture", 2D) = "white" {}
        _DiffuseColor("Diffuse Color", Color) = (1,1,1,1)
        
	    _Ramp("Ramp Texture", 2D) = "bump"{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        UsePass "NPR/NormalExpandOutline_1/OUTLINE" 
        pass
        {
            Tags {"LightMode"="ForwardBase"}

            Cull Back
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            sampler2D _MainTex;float4 _MainTex_ST;
            sampler2D _Ramp;float4 _Ramp_ST;
            
            fixed4 _DiffuseColor;
            float4 _Color;
           

            struct a2v
            {
                float4 vertex : POSITION;
                fixed3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;//纹理坐标
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 texcoord : TEXCOORD0;//纹理坐标
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

	        	fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * mainTex.rgb;

	        	fixed NDotL = dot(normalDir, worldLightDir);

	        	fixed halfLambert = NDotL*0.5 + 0.5;

	        	fixed3 diffuse = mainTex.rgb * _LightColor0.rgb * _DiffuseColor.rgb * tex2D(_Ramp, float2(halfLambert, halfLambert)).rgb;

	        	fixed3 color = ambient + diffuse;
	            
                return fixed4(color,1);
            }

            ENDCG
        }
    }
}
