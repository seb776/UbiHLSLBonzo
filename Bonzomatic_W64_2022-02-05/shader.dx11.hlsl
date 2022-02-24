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
SamplerState smp2;

cbuffer constants
{
	float fGlobalTime; // in seconds
	float2 v2Resolution; // viewport resolution (in pixels)
	float fFrameTime; // duration of the last frame, in seconds
}
#define PI 3.14159265
#define TAU (2.0*PI)
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

float sdUnevenCapsule( float2 p, float r1, float r2, float h )
{
    p.x = abs(p.x);
    float b = (r1-r2)/h;
    float a = sqrt(1.0-b*b);
    float k = dot(p,float2(-b,a));
    if( k < 0.0 ) return length(p) - r1;
    if( k > a*h ) return length(p-float2(0.0,h)) - r2;
    return dot(p, float2(a,b) ) - r1;
}

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return lerp( d2, d1, h ) - k*h*(1.0-h); }
    
float4 main( float4 position : SV_POSITION, float2 TexCoord : TEXCOORD ) : SV_TARGET
{
	float2 uv = ((TexCoord-0.5)*v2Resolution.xy)/v2Resolution.x;

  float4 color = renderShapes(uv);
    color = float4(0,0,0,0);
  
  
  float stp = TAU/5.;
  float2 uv2 = uv;
  float off = 5.;
  float angle = atan2(uv2.y, uv2.x);
  float sector = fmod(angle+TAU*4.+0.5*stp, stp)-0.5*stp;
  uv2 = float2(sin(sector), cos(sector))*length(uv2);
 // uv2.x = clamp(uv2.x, -0.5*rep, rep*0.5);
  //uv2.x = fmod(uv2.x+0.5*rep,rep)-rep*0.5;
  uv2.x += sin(uv2.y*45+fGlobalTime)*0.01;
  
  float shape2 = sdUnevenCapsule(uv2, 0.01,0.01,0.2);
  
  shape2 = opSmoothUnion(shape2, sdCircle(uv, float2(0,0), 0.1), 0.05);
  shape2 = abs(shape2)-0.005;
  //color = float4(0,0,1,0)*saturate(-shape2*1000);
  color = lerp(color, float4(0,0,1,0), saturate(-shape2*1000));
  //color += float4(1,0,0,0);
//  color += sdCircle(uv, float2(0,0), .1)*1005;
  
  float shape = sdCircle(uv, float2(0,0), 0.4*frac(fGlobalTime*0.1));
  float mask = shape;
  shape = abs(shape)-0.03;
  if (uv.x < 0.)
    color = lerp(color, float4(0,0,1,0), saturate(mask*1000));
  else
    color = lerp(color, float4(0,0,1,0), saturate(-shape*15)*saturate(-mask*1000));
//  color = lerp(color, float4(0,0,1,0), saturate(-shape*25)*saturate(-mask*1000.));
  //color = float4(1,1,1,1)*angle/PI;
    // min, max, abs, lerp, clamp / saturate distance, length
  // step smoothstep smootherstep
  // round ceil floor
   // sin, cos, tan, asin acos, atan, atan2
   // ln(a) log(a), exp(a), pow(a, b), sqrt
  // dot, cross, normalize, reflect, refract 
  // ddx, ddy, fwidth / coarce / fine 
  float3 colA = texChecker.Sample(smp2, uv*2.5*float2(1.,-1.)+float2(0.,sin(uv.x*5.+fGlobalTime)*.1)).xyz;
    float3 colB = texTex1.Sample(smp2, uv*2.5*float2(1.,-1.)+float2(0.,sin(uv.x*5.-fGlobalTime)*.1)).xyz;
  float maskbrick = saturate(pow(colB.x,5.)*10.);
color.xyz = lerp(colA, color.xyz, saturate(sin(uv.x*20.+fGlobalTime)*0.5+0.5)*(1.-maskbrick));
//  xyzw
//  rgba
//  stpq
  
  color = float4(0,0,0,0);
  float3 colBrick = texTex1.Sample(smp2, uv).xyz;
  float maskBrick = saturate(pow(colBrick.y,3.)*5.);
  float maxSize = 0.8;
  float sz = frac(fGlobalTime*0.4)*maxSize;
  
  float circle = sdCircle(uv, float2(0,0), sz);
  circle = abs(circle)-0.05;
  float3 light = float3(1,0,0);
  color.xyz = lerp(colBrick.yyy, light*saturate(-circle*50)*pow(1.-sz/maxSize,5.), maskBrick);////float3(1,1,1)*maskBrick;
  color.xyz = pow(color, float3(2.,2.,2.));
	return color;
}