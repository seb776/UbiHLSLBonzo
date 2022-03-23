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
vec2 map(vec3 p, float h)
{
  vec2 acc = vec2(100000.,-1.);

  float shape = _cube(p, vec3(.5));
  
  acc = _min(acc, vec2(shape, 0.));
  
  acc = _min(acc, vec2(-_cube(p-vec3(0.,-6.5,0.), vec3(7.,20.,7.)), 1.));
  
  acc = _min(acc, vec2(-p.y-h, 2.));
  return acc;
}
#define PI 3.14159265
vec3 getNormal(vec3 p, float h)
{
  vec2 e = vec2(0.01,0.);
  return -normalize(vec3(
    map(p-e.xyy,h).x-map(p+e.xyy,h).x,
    map(p-e.yxy,h).x-map(p+e.yxy,h).x,
    map(p-e.yyx,h).x-map(p+e.yyx,h).x
  ));
  
  return normalize(p);
}

vec3 getEnv(vec3 rd)
{
  vec2 uv = vec2(atan(rd.z, rd.x)/PI, -acos(rd.y)/PI);
  return pow(texture(texTex360, uv).xyz, vec3(1./2.2));
}
vec3 accCol;
vec4 trace(vec3 ro, vec3 rd, int steps, float maxdist, float h)
{
  accCol = vec3(0.);
  vec3 p = ro;
  for (int i = 0 ; i < 128 && distance(p, ro) < maxdist; ++i)
  {
    vec2 res = map(p,h);
    if (res.x < 0.01)
    {
      return vec4(res.x, distance(p, ro), res.y, float(i));
    }
    if (res.y == 0.)
    {
      
      accCol += vec3(sin(p.y*10+fGlobalTime*5.)*.5+.5,0.2,0)*0.1;
    }
    p += rd*res.x*0.7;
  }
  return vec4(-1.);
}

vec3 rdr(vec2 uv)
{
  vec3 col = vec3(0.);
  float t = fGlobalTime*.1;
  vec3 ro = vec3(sin(t)*5.,-2.,cos(t)*5.);
  vec3 ta = vec3(0,0,0);
  vec3 rd = normalize(ta-ro);
  rd = getCam(uv, rd);
  col = getEnv(rd);
  float h1 = 0.0;
  vec4 res = trace(ro, rd, 256,20.,h1);
  vec3 light = accCol;
  if (res.y > 0)
  {
    vec3 p = ro+rd*res.y;
    vec3 n= getNormal(p,h1);
    
    float ao = pow(1.-sat(res.w/128.),.4);
    float distao = 1.5;
    ao = sat(map(p+n*0.5*distao, h1).x/distao);
    col = mix(vec3(1.),(n*.5+.5),.25);
    col *= sat(ao+0.7);
    if (res.z == 2.) // Is ground
    {
      col = pow(texture(texTex2, p.xz*.4).x, .25)*vec3(.1,.5,.75)*.25;
      vec3 backupn = normalize(n+(texture(texTex4, p.xz*.4).xyz-0.5)*.05);
      n = normalize(n+(texture(texTex4, p.xz*.4).xyz-0.5)*.5);
      
      col += getEnv(reflect(rd, backupn))*.25;
      
      vec3 lightDir = normalize(vec3(1.));
      
      col += vec3(1.)*pow(sat(-dot(lightDir, n)),3.)*.5; // diffuse

      vec3 h = normalize(-rd-lightDir);
      col += vec3(1.)*pow(sat(dot(h, backupn)),38.); // specular

      vec3 refr = refract(rd, n, .7); // rayon refraction
      float h2 = -0.5;
      vec4 resrefr = trace(p, refr, 128, 5., h2); // resultat refraction
      if (resrefr.y > 0.)
      {
        vec3 prefr = p+refr*resrefr.y; // p point refraction
        vec3 nrefr = getNormal(prefr, h2); // normal refraction
        
        
        col += sat(pow(texture(texNoise, prefr.xz*.5).x, 2.5)*5.+.25)*.25;
        col += sat(pow(texture(texNoise, prefr.xz*.25).x, 2.5)*5.+.25)*vec3(.1,.75,.9)*.75;
        
        col += vec3(.1,.25,.9).zyx*(1.-sat((abs(prefr.x-sin(prefr.z*2.+fGlobalTime)*.3)-.01)*4.))*2.;
      }
      
    }
    
    
  
  }
  col += light;
  
  return col;
}

void main(void)
{
	vec2 uv = (out_texcoord-.5)*(v2Resolution.xy/v2Resolution.xx);
  _seed = texture(texTex2, uv).x+fGlobalTime;
  vec3 col = rdr(uv);
  
	out_color = vec4(col,1.);
}