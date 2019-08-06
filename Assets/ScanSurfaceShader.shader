Shader "Unlit/ScanSurfaceShader"
{
    Properties
    {
		_BurstColor("Burst Color", Color) = (1,1,1,1)
		_BaseColor("Base Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
                float4 vertex : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
            };
			float4 _BurstColor;
			float4 _BaseColor;

			float3 _CursorPos;
			float3 _BurstPoint;
			float _BurstAlpha;
			float _Burstness;

			float GetBurstParam(float3 worldPos)
			{
				float rampedBurst = pow(_Burstness * 2, .5);
				float burstDist = length(worldPos - _BurstPoint) * 2;
				float distToBurst = abs(burstDist - rampedBurst);
				float ret = saturate(1 - distToBurst);
				ret = pow(ret, 2);
				ret *= 1 - pow(_BurstAlpha, 2);
				return ret;
			}

            v2f vert (appdata v)
            {
                v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

			float GetBaseGlowAlpha(float3 worldPos)
			{
				float cursorDist = length(worldPos - _CursorPos);
				float ret = 1 - saturate(cursorDist);
				ret = pow(ret, 2);
				return ret;
			}

            fixed4 frag (v2f i) : SV_Target
            {
				UNITY_SETUP_INSTANCE_ID(i);

				float burstParam = GetBurstParam(i.worldPos);
				float baseGlowAlpha = GetBaseGlowAlpha(i.worldPos);
				float4 baseColor = lerp(_BaseColor, _BurstColor, burstParam);
				float4 ret = baseColor * baseGlowAlpha;
				//return baseGlowAlpha;
				ret += burstParam * _BaseColor * _BurstAlpha;
				return ret;
            }
            ENDCG
        }
    }
}
