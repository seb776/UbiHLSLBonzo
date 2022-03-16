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

float map(vec3 p)
{
  float shape = length(p)-1.;
  vec3 pc = p+vec3(1.,0,-0.);
  pc.yz *= r2d(fGlobalTime);
  shape = min(shape, _cube(pc, vec3(.5)));
  return shape;
}

vec3 getNormal(vec3 p)
{
  vec2 e = vec2(0.001,0.);
  return -normalize(vec3(
    map(p-e.xyy)-map(p+e.xyy),
    map(p-e.yxy)-map(p+e.yxy),
    map(p-e.yyx)-map(p+e.yyx)
  ));
  
  return normalize(p);
}

vec3 rdr(vec2 uv)
{
  vec3 col = vec3(0.);
  
  //col = vec3(1.)*(1.-sat((length(uv)-.25)*400.));
  
  vec3 camPos = vec3(0.,0.,-5.);
  vec3 ta = vec3(0,0,0);
  vec3 rd = normalize(ta-camPos);
  rd = getCam(uv, rd);
  
  vec3 p = camPos;// + rd;
  for (int i = 0 ; i < 128; ++i)
  {
    float dist = map(p);
    if (dist < 0.001)
    {
      col = getNormal(p)*.5+.5;
      break;
    }
    p += rd*dist;
  }
  
  return col;
}

void main(void)
{
	vec2 uv = (out_texcoord-.5)*(v2Resolution.xy/v2Resolution.xx);

  vec3 col = rdr(uv);
	out_color = vec4(col,1.);
}