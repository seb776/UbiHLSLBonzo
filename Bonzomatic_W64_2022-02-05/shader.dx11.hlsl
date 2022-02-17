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

float4 renderShapes(float2 uv)
{
  uv.x += sin(uv.y*25.+fGlobalTime)*0.1;
  float2 ouv = uv;
  float4 col = float4(0.,0.,0.,0.);
  
  //if (uv.x > -0.1 && uv.x < 0.1)
  if (abs(uv.x) < 0.1 && abs(uv.y) < 0.1) 
  {  
    col = float4(1.,1.,1.,1.)*0.5;
  }
  float2 uv2 = uv;

  uv2 += float2(sin(fGlobalTime)*.2,0.1);
  if (abs(uv2.x) < 0.1 && abs(uv2.y) < 0.1) 
  {  
    col += float4(0.,0.,1.,1.);
  } 
  float2 uv3 = ouv+float2(-0.1,-0.1);    
  if (abs(ouv.x) < 0.1 && abs(ouv.y) < 0.1) 
  {  
    col += float4(1.,0.,0.,1.);
  } 
   
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
   // ln(a) log(a), exp(a), pow(a, b)
  // dot, cross, normalize, reflect, refract 
  // ddx, ddy, fwidth / coarce / fine  
  
	return color;
}