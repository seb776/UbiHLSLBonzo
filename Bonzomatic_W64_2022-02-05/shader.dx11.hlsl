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

float _sdCircle(float2 uv, float r)
{
  return length(uv)-r;
}
#define PI 3.14159265

float3 rdr(float2 uv)
{
  float3 col = float3(0,0,0);
  float sharpness = 500;
  float thickness = 0.05;
  float angle = atan2(uv.y, uv.x);
  float2 uv2 = uv;
  
  uv += float2(texNoise.Sample(smp, uv*15.+fGlobalTime).x,
  texNoise.Sample(smp, -uv*15.+fGlobalTime).x)*.04;

  float height = 0.25-0.02*asin(sin(angle*5));
  float shape = abs(_sdCircle(uv, height))-thickness;
  
  float repetition = 2.*PI/5.;
  float anglesector = angle+repetition*0.5+PI+fGlobalTime*.5;
  float id = floor(anglesector/repetition);

  float sector = fmod(anglesector,repetition)-repetition*0.5;
  uv2 = float2(sin(sector), cos(sector))*length(uv2);
    
  float shape2 = abs(uv2)-0.075;
  col = float3(1,1,1)*(1.-saturate(shape2*sharpness));

    //col = float3(1,1,1)*sector;
    shape = max(shape, -shape2);
      col = float3(1,1,1)*(1.-saturate(shape*sharpness));
  

  
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