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
#define PI 3.14159265

float _sdCircle(float2 uv, float r)
{
  return length(uv)-r;
}
// Thanks Inigo Quilez !
float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return lerp( d2, d1, h ) - k*h*(1.0-h); }
    
float _sqr(float2 uv, float2 s)
{
  float2 l = abs(uv)-s;
  return max(l.x, l.y);
}

float _spaceshipfly(float2 uv)
{
  float base = length(uv*float2(2.,1.)-float2(0,-.1))-0.25;
  return max(base, -(length(uv*float2(2.,1.)-float2(0,-.2))-0.25));
}

float _spaceshipbody(float2 uv)
{
  float r = 0.35;
  float acc = 1000.;
  float2 ouv = uv;
  uv.x = abs(uv.x)+.01;
  acc = min(acc, length(uv*float2(3.,1.))-r);

  return acc;
}
#define pal(a, b, c, d, f) (a+b*cos(2.*PI*(c*f+d)))

float3 rdr(float2 uv)
{
  float3 col = float3(0,0,0);
  float sharpness = 500;
  
  // Wings
  float shapefly = _spaceshipfly(uv-float2(0.,-.3));
  col = .2*float3(1,1,1)*(1.-saturate(shapefly*sharpness));

  // Ship's body
  float ship = _spaceshipbody(uv);
  col = lerp(col, float3(1.,1.,1.)*saturate(abs(uv.x)*5.),(1.-saturate(ship*sharpness)));
  
  // Mask and background
  float lavamask = max(ship, abs(uv.y)-.2);
  col = lerp(col, float3(0,0,1),(1.-saturate(lavamask*sharpness)));
  
  // Bubbles
  float bubbles = 10000.; // Default distance
  for (int i = 0; i < 8; ++i)
  {
    float2 coords = uv+float2(sin(i*10+fGlobalTime*0.1)*0.05,sin(i+fGlobalTime*0.25)*.2);
    float bubble = length(coords)-0.04;
    bubbles = opSmoothUnion(bubbles, bubble, 0.1);
  }
  bubbles = max(bubbles, lavamask);
  float3 colbubble = pal(.5,.5,1.,float3(.8,.2,.6), bubbles*10.5);

  col = lerp(col, colbubble,(1.-saturate(bubbles*sharpness)));
  
  col += colbubble*(1.-saturate(bubbles*20.));
  
  return col;
}

float4 main( float4 position : SV_POSITION, float2 TexCoord : TEXCOORD ) : SV_TARGET
{
	float2 uv = TexCoord;
	uv -= 0.5;
	uv /= float2(v2Resolution.y / v2Resolution.x, 1);

  float3 col = rdr(uv);
  
	return float4(col, 1.);
}