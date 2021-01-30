// Upgrade NOTE: commented out 'float4x4 _CameraToWorld', a built-in variable
// Upgrade NOTE: replaced '_CameraToWorld' with 'unity_CameraToWorld'

// Upgrade NOTE: commented out 'float4x4 _CameraToWorld', a built-in variable

// Upgrade NOTE: commented out 'float4x4 _CameraToWorld', a built-in variable

// Upgrade NOTE: commented out 'float4x4 _CameraToWorld', a built-in variable

Shader "Unlit/Raymarch"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_AspectRatio("Aspect Ratio", Float) = 1.33
		_TimeOffset("Time Offset", Float) = 0
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			float _AspectRatio;
			float _TimeOffset;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

			float time()
			{
				return _Time + _TimeOffset;
			}

			//edited from http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/
			float2 distToMandelbulb(float3 pos)
			{
				const float maxPow = 4;
				const float timeMul = 1;
				const float bailout = 2;
				const float maxIter = 15;
				//move forward through powers, once max power is reached, rewind to min power
				float power = 1.25 + ((time() * timeMul) % maxPow) * saturate(maxPow - ((time() * timeMul) % maxPow));
				float3 z = pos;
				float dr = 1.0;
				float r = 0.0;
				int iter;

				for (iter = 0; iter < maxIter; iter++) {
					r = length(z);

					if (r > bailout) {
						break;
					}

					// convert to polar coordinates
					float theta = acos(z.z / r);
					float phi = atan2(z.y, z.x);
					dr = pow(r, power - 1.0) * power * dr + 1.0;

					// scale and rotate the point
					float zr = pow(r, power);
					theta = theta * power;
					phi = phi * power;

					// convert back to cartesian coordinates
					z = zr * float3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta));

					z += pos;
				}
				float dist = 0.5 * log(r) * r / dr;
				return float2(iter, dist);
			}



			fixed4 marchRay(float3 origin, float3 direction)
			{
				const float MAX_ITER = 250;
				const float MIN_DIST = 0.0001f;

				fixed4 col = fixed4(0, 0, 0, 0);

				float3 pos = origin;
				for (float iter = 0; iter < MAX_ITER; iter += 1)
				{
					float2 res = distToMandelbulb(pos);
					float mandelIter = res.x;
					float dist = res.y;
					
					if (dist <= MIN_DIST)
					{
						fixed i = pow(saturate(dot(mandelIter + pos, float3(sin(mandelIter), sin(mandelIter*0.37), sin(mandelIter*1.35)))),3);
						fixed j = pow(saturate(abs(sin(distance(pos, 0) * 10))),3); 
						fixed k = pow(saturate(abs(round(frac(distance(pos,0))))),3);

						fixed r = lerp(i, j, abs(sin(time() * 3)));
						fixed g = lerp(i, k, abs(sin(time() * 3.5)));
						fixed b = lerp(j, k, abs(sin(time() * 2.6)));

						col = fixed4(r, g, b, 1) * pow(distance(pos, 0), 3);
						break;
					}
					pos += direction * dist;

					iter += 1;
				}

				return col;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float2 uv = (i.uv * 2 + float2(-1,-1))* float2(_AspectRatio, 1);
				float3 origin = _WorldSpaceCameraPos.xyz;
				float3 direction = mul(unity_CameraToWorld,normalize(float4(uv, 4, 0))).xyz;
                return marchRay(origin, direction);
            }
            ENDCG
        }
    }
}
