Shader "NPR/NormalExpandOutline"
{
    Properties
    {
	    _OutlineWidth ("Outline Width", Range(0.01, 1)) = 0.24
        _OutLineColor ("OutLine Color", Color) = (0.5,0.5,0.5,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        pass
        {
            Tags {"LightMode"="ForwardBase"}

            Cull Back
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float4 vert(appdata_base v): SV_POSITION
	        {
                return UnityObjectToClipPos(v.vertex);
            }

            half4 frag() : SV_TARGET 
	        {
                return half4(1,1,1,1);
            }

            ENDCG
        }

        Pass
	    {
	        Name "OUTLINE"
	        
	        Tags {"LightMode"="ForwardBase"}
			 
            Cull Front
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            half _OutlineWidth;
            half4 _OutLineColor;

            struct a2v 
	        {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
	        {
                float4 pos : SV_POSITION;
            };

            v2f vert (a2v v) 
	        {
                v2f o;
               
                //方法一：将法线转换到投影空间，在投影阶段进行偏移
                //有断裂
            	float4 pos = mul(UNITY_MATRIX_MV, v.vertex);
                float3 normal = mul(UNITY_MATRIX_MV, v.normal);
            	//调整法线z坐标，防止遮挡正面渲染
	             normal.z = -0.5;
	             pos = pos + float4(normalize(normal), 0) * _OutlineWidth * 0.02;
	             o.pos = mul(UNITY_MATRIX_P, pos);
                
                return o;
            }

            half4 frag(v2f i) : SV_TARGET 
	        {
                return _OutLineColor;
            }
            ENDCG
        }
    }
}
