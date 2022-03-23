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
uniform sampler2D texTex360;


in vec2 out_texcoord;
layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

#define sat(a) clamp(a, 0., 1.)

float hash11(float seed)
{
  return fract(sin(seed*123.456)*123.456);
}
float _seed;
float rand()
{
  _seed += 1;
  return hash11(_seed);
}

vec3 getCam(vec2 uv, vec3 rd)
{
  vec3 r = normalize(cross(rd, vec3(0,1,0)));
  vec3 u = normalize(cross(rd, r));
  return normalize(rd+uv.x*r+uv.y*u);
}

float _cube(vec3 p, vec3 s)
{
  vec3 l = abs(p)-s;
  return max(l.x, max(l.y, l.z));
}

mat2 r2d(float a) { float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }
vec2 _min(vec2 a, vec2 b)
{
  if (a.x < b.x)
    return a;
  return b;
}
vec2 map(vec3 p)
{
  vec2 acc = vec2(100000.,-1.);

  float shape = _cube(p, vec3(.5));
  
  acc = _min(acc, vec2(shape, 0.));
  
  acc = _min(acc, vec2(-_cube(p-vec3(0.,-6.5,0.), vec3(7.)), 0.));
  return acc;
}
#define PI 3.14159265
vec3 getNormal(vec3 p)
{
  vec2 e = vec2(0.01,0.);
  return -normalize(vec3(
    map(p-e.xyy).x-map(p+e.xyy).x,
    map(p-e.yxy).x-map(p+e.yxy).x,
    map(p-e.yyx).x-map(p+e.yyx).x
  ));
  
  return normalize(p);
}

vec3 getEnv(vec3 rd)
{
  vec2 uv = vec2(atan(rd.z, rd.x)/PI, -acos(rd.y)/PI);
  return pow(texture(texTex360, uv).xyz, vec3(1./2.2));
}

vec4 trace(vec3 ro, vec3 rd, int steps, float maxdist)
{
  vec3 p = ro;
  for (int i = 0 ; i < 128 && distance(p, ro) < maxdist; ++i)
  {
    vec2 res = map(p);
    if (res.x < 0.01)
    {
      return vec4(res.x, distance(p, ro), res.y, float(i));
    }
    p += rd*res.x;
  }
  return vec4(-1.);
}

vec3 rdr(vec2 uv)
{
  vec3 col = vec3(0.);
  
  vec3 ro = vec3(sin(fGlobalTime*.25)*5.,0.,cos(fGlobalTime*.25)*5.);
  vec3 ta = vec3(0,0,0);
  vec3 rd = normalize(ta-ro);
  rd = getCam(uv, rd);
  col = getEnv(rd);
  vec4 res = trace(ro, rd, 256,20.);
  if (res.y > 0)
  {
    vec3 p = ro+rd*res.y;
    vec3 n= getNormal(p);
    
    float ao = pow(1.-sat(res.w/128.),.4);
    float distao = 1.5;
    ao = sat(map(p+n*0.5*distao).x/distao);
    col = mix(vec3(1.),(n*.5+.5),.25);
    col *= sat(ao+0.7);

  }

  
  return col;
}

void main(void)
{
	vec2 uv = (out_texcoord-.5)*(v2Resolution.xy/v2Resolution.xx);
  _seed = texture(texTex2, uv).x+fGlobalTime;
  vec3 col = rdr(uv);
  
	out_color = vec4(col,1.);
}