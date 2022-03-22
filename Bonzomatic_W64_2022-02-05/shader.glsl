#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)
uniform float fFrameTime; // duration of the last frame, in seconds

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texPreviousFrame; // screenshot of the previous frame
uniform sampler2D texChecker;
uniform sampler2D texNoise;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

in vec2 out_texcoord;
layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

#define sat(a) clamp(a, 0., 1.)
#define fGlobalTime fGlobalTime*.25
mat2 r2d(float a)
{
  float c = cos(a);
  float s = sin(a);
  return mat2(c, -s, s, c);
}

float smin( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

vec3 ballsPositions[8];
void setup()
{
  for (int i = 0; i < 8; ++i)
  {
      float fi = float(i);
    
      vec3 sphp = 1.25*vec3(sin(fi+fGlobalTime), sin(fGlobalTime+fi*10.), cos(fi+fGlobalTime));
      ballsPositions[i] = sphp;
  }
}  
vec2 _min(vec2 a, vec2 b)
{
  if (a.x < b.x)
    return a;
  return b;
}
vec2 map(vec3 p)
{
  vec3 rep = vec3(10.);
  vec2 acc = vec2(1000., -1.);
  p = mod(p+rep*.5,rep)-rep*.5;
  for (int i = 0; i < 8; ++i)
  {
    float fi = float(i);
    
      vec3 sphp = p+ballsPositions[i];
      acc = _min(acc, vec2(length(sphp)-1.0, i));
  }
  
  acc = abs(acc)-0.2;
  float repy = .1;

  vec3 p2 = p;
  p2.y = mod(p2.y+repy*.5,repy)-repy*.5;
  
  acc = max(acc, -(abs(p2.y)-0.1));
  
  return acc;
}

vec3 getNormal(vec3 p)
{
  return -normalize(
    vec3(map(p-vec3(0.001,0,0)).x-map(p+vec3(0.001,0,0)).x,
    map(p-vec3(0.0,0.001,0)).x-map(p+vec3(0.,0.001,0)).x,
    map(p-vec3(0.0,0,0.001)).x-map(p+vec3(0.,0,0.001)).x)
  );
}

vec3 rdr(vec2 uv)
{ 
  vec3 col = vec3(0.);
  
  vec3 ro = vec3(sin(fGlobalTime)*5.0,sin(fGlobalTime*2.)*5.,-5.);
  vec3 plan = vec3(uv.x*10., uv.y*10., 1.0);
  vec3 rd = normalize(plan-ro);

  //col = rd;

  vec3 p = ro;
  //float acc = 0.0;
  vec3 acc = vec3(0.);
  for (int i =0; i < 128 && distance(p, ro) < 100; ++i)
  {
    vec2 dist = map(p);
    if (dist.x < 0.001)
    {
       col = vec3(1.);
      
      vec3 n = getNormal(p);
      col = n*.5+.5;
      vec2 tuv = vec2(atan(n.z, n.x), p.y);
       n += texture(texTex4, tuv).xyz*.5;
      n = normalize(n);
      vec3 text = texture(texTex3, tuv).xyz;
      //ballsPosition[int(dist.y)]
      col = vec3(1.)*sat(-dot(n, normalize(vec3(1.,-1.,1.))))*1.;
       break;
    }
    acc += mix(vec3(1,0,0), vec3(0.3,0.5,1), sat(length(p)-.4)) *(1.-sat(dist.x/0.5))*0.02;
    p = p + rd * dist.x;
  }
  col += vec3(1.)*acc;
  return col;
}

void main(void)
{
	vec2 uv = out_texcoord;
	uv -= 0.5;
	uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  setup();
  vec3 col = rdr(uv);

	out_color = vec4(col, 1.);
}