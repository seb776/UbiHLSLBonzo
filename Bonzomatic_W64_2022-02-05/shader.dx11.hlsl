Texture2D texChecker;
Texture2D texNoise;
Texture2D texTex1;
Texture2D texTex2;
Texture2D texTex3;
Texture2D texTex4;
Texture1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
Texture1D texFFTSmoothed; // this one has longer falloff and less harsh transients
Texture1D texFFTIntegrated; // this is continually increasing
Texture2D texPreviousFrame; // screenshot of the previous frame
SamplerState smp;

cbuffer constants
{
	float fGlobalTime; // in seconds
	float2 v2Resolution; // viewport resolution (in pixels)
	float fFrameTime; // duration of the last frame, in seconds
}

float2x2 rotation(float a)
{
  float s = sin(a);
  float c = cos(a);
  return float2x2(c, -s, s, c);
}

float sdCircle(float2 uv, float2 pos, float rad)
{
  return distance(uv, pos) - rad;
}
float sdBox(float2 p, float2 b )
{
    float2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}
float4 renderShapes(float2 uv)
{
  float2 ouv = uv;
  float4 col = float4(0.,0.,0.,0.);
  
  float2 rep = float2(0.15,0.15);
  
  uv += float2(10.,10.);
  float2 id = floor((uv+rep*0.5)/rep);

  uv = fmod(uv+rep*0.5,rep)-rep*0.5;
  
  float dist = sdBox(uv, float2(0.05,0.05));
  
  
  dist = min(dist, sdCircle(uv, float2(0.2,0.), 0.2));
  
  dist = abs(dist)-0.005;
  dist = min(dist, abs(sdCircle(uv, float2(0.2,0.3), 0.2))-.05);
  
  float4 rgb = lerp(float4(1.,.1,0.1,1.), float4(0.,.1,1.,1.), saturate(sin(id.y*100.+fGlobalTime+id.x*500.)));
  col = rgb*saturate(-dist*v2Resolution.x/2.0);
  //*saturate(-dist*v2Resolution.x*0.5);
  return col;
}

float4 main( float4 position : SV_POSITION, float2 TexCoord : TEXCOORD ) : SV_TARGET
{
	float2 uv = ((TexCoord-0.5)*v2Resolution.xy)/v2Resolution.x;

  float4 color = renderShapes(uv);
    
    // min, max, abs, lerp, clamp / saturate distance, length
  // step smoothstep smootherstep
  // round ceil floor
   // sin, cos, tan, asin acos, atan, atan2
   // ln(a) log(a), exp(a), pow(a, b), sqrt
  // dot, cross, normalize, reflect, refract 
  // ddx, ddy, fwidth / coarce / fine  
  
	return color;
}