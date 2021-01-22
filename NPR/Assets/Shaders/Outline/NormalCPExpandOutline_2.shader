Shader "NPR/NormalExpandOutline_2"
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
               
                //将顶点坐标作为方向矢量，转换到投影空间，以此为基础偏移
                //没有断裂
                o.pos = UnityObjectToClipPos(v.vertex.xyz);
                float3 normal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, v.normal));
                float2 offset = TransformViewToProjection(normal.xy);
                o.pos.xy += offset * o.pos.z * _OutlineWidth;
                
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
