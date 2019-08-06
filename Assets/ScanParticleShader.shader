Shader "Unlit/ScanParticleShader"
{
	Properties
	{
		_BurstColor("Burst Color", Color) = (1,1,1,1)
		_BaseColor("Base Color", Color) = (1,1,1,1)
	}
	SubShader
	{
		Pass
		{
			ZWrite Off
			Blend One One
			CGPROGRAM
			#pragma vertex vert  
			#pragma fragment frag
			#pragma target 5.0

			#include "UnityCG.cginc"

			struct ScanParticle
			{
				float3 CurrentPos;
				float3 Normal;
				float Lifetime;
				float RandomX;
				float RandomY;
			};

			StructuredBuffer<ScanParticle> _DynamicData;
			StructuredBuffer<float3> _QuadPoints;

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 quadPoint : TEXCOORD1;
				float lifespan : TEXCOORD2;
				float4 color : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			}; 

			float _CardSize;
			float4x4 _MasterTransform;
			float4 _BurstColor;
			float4 _BaseColor;
			float _Speed;
			float _Lifespan;
			float3 _FingerPos;
			float _Burstness;
			float3 _BurstPoint;
			float _BurstAlpha;

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

			float GetParticleSize(float burstParam, float lifetime)
			{
				float lifespan = lifetime / _Lifespan;
				lifespan = 1 - pow(abs(lifespan - .5) * 2, 2);
				float burstSize = _CardSize * burstParam;
				float baseSize = _CardSize / 4;
				float ret = max(burstSize, baseSize) *lifespan;
				ret *= 0.01;
				return ret;
			}

			float4 GetPos(float burstParam, float3 worldPos, float3 normal)
			{
				float3 burstOffset = normal * burstParam;
				burstOffset *= .2;
				float3 newPos = worldPos + burstOffset;
				return float4(newPos, 1);
			}

			float4 GetColor(float burstParam)
			{
				return lerp(_BaseColor, _BurstColor, burstParam);
			}

			struct appdata
			{
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			v2f vert(appdata v, uint id : SV_VertexID, uint inst : SV_InstanceID)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				o.quadPoint = _QuadPoints[id];

				ScanParticle scanParticle = _DynamicData[inst];

				float burstParam = GetBurstParam(scanParticle.CurrentPos);

				float cardSize = GetParticleSize(burstParam, scanParticle.Lifetime);
				float3 finalQuadPoint = o.quadPoint * cardSize;
				float4 worldPos = GetPos(burstParam, scanParticle.CurrentPos, scanParticle.Normal);
				o.lifespan = scanParticle.Lifetime;
				o.color = GetColor(burstParam);
				o.pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_V, worldPos) + float4(finalQuadPoint, 0));
				return o;
			}

			fixed4 frag(v2f i) : COLOR
			{
				UNITY_SETUP_INSTANCE_ID(i);

				float distToCenter = saturate(length(i.quadPoint) * 2);
				float alpha = 1 - distToCenter;
				alpha = saturate(alpha * 10);
				return i.color * alpha;
			}
			ENDCG
		}
	}
}