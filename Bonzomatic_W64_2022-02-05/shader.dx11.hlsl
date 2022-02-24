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

float sdBox( float2 p, float2 b )
{
    float2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float sdCircle(float2 uv, float r)
{
  return length(uv)-r;
}

float2x2 rotation(float a)
{
  float c = cos(a);
  float s = sin(a);
  return float2x2(c, -s, s, c);
}

float sdCross(float2 uv, float2 s)
{
  return min(sdBox(uv, s.xy), sdBox(uv, s.yx));
}

float4 main( float4 position : SV_POSITION, float2 TexCoord : TEXCOORD ) : SV_TARGET
{
	float2 uv = (TexCoord-0.5)*v2Resolution.xy/v2Resolution.xx;

  float4 color = float4(0,0,0,0);

  //uv = mul(uv, rotation(fGlobalTime*10));
  //clamp(valeur, 0, 1) = saturate(valeur)
  float radius = 0.1;
  float sharpness = v2Resolution.x*0.5;
  float2 uv2 = uv;
  
  uv2 = mul(uv+float2(sin(fGlobalTime), cos(fGlobalTime))*0.15, rotation(fGlobalTime));
  float rnd = 0.02;
  float shape = sdBox(uv2, float2(radius, radius)-rnd);
  shape -= rnd;
  /*shape = abs(shape)-0.03;
  shape = max(shape, -sdCircle(uv, float2(radius, radius)));
  shape = abs(shape)-0.007;
  shape = abs(shape)-0.001;*/
  float shape2 = sdCircle(uv, .1);
  float shape3 = sdBox(uv, float2(.05,.3));
  color = float4(1,1,1,1)*pow(1-saturate(shape*sharpness), 4);

  color = lerp(color, float4(1,0,0,0), 1-saturate(shape2*sharpness));
  color += float4(0,1,0,0)*(1-saturate(shape3*sharpness));
  //uv = );
  float2 uv3 = mul(uv, rotation(fGlobalTime));
  color = float4(1,1,1,1)*(saturate((atan2(uv3.y,uv3.x)/3.1415)-.5)*2.*saturate(uv3.y*sharpness))*smoothstep(0,1,1.-saturate(length(uv3)*3.));
  float th = 0.0005;
  float ca = min(abs(sdCircle(uv, .1))-th, abs(sdCircle(uv, .2))-th);
  color = lerp(color, float4(.7,.7,1.,1.), 1.-saturate(ca*sharpness));
  
  float cb = abs(sdCircle(uv, 0.25))-th*3.;
  
  cb = max(cb, sdCross(uv, float2(0.05+0.02*sin(fGlobalTime),1.0)));
  color = lerp(color, float4(1,1,1.,1.), 1.-saturate(cb*sharpness));
  
  float2 dotcoord = uv+float2(sin(fGlobalTime), cos(fGlobalTime*.3))*.1;
  float cc = sdCircle(dotcoord, 0.005);
  color = lerp(color, float4(1,.2,0.1,0), 1.-saturate(cc*sharpness));
  
  float beat = .1;
  float cd = abs(sdCircle(dotcoord, lerp(0,0.1,fmod(fGlobalTime*.05, beat)/beat)))-th;
  color = lerp(color, float4(1,.2,0.1,0), 1.-saturate(cd*sharpness));
  

/*
  color = float4(0,0,0,0);
  float2 uv4 = mul(uv, rotation(fGlobalTime));
  float cir = sdCircle(uv, 0.1);
  color = float4(1,1,1,1)*saturate(atan2(uv4.y,uv4.x)/3.1415-0.7)*3.*(1.-saturate(cir*4.));
*/

	return color;
}