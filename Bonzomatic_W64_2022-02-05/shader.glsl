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
uniform sampler2D texVoronoi;

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


vec2 _min(vec2 a, vec2 b)
{
  if (a.x < b.x)
    return a;
  return b;
}
float _cube(vec3 p, vec3 s)
{
    vec3 l = abs(p)-s;
  return max(l.x, max(l.y, l.z));
}
vec2 map(vec3 p, float h)
{
  vec2 acc = vec2(1000., -1.);
  p.xz *= r2d(fGlobalTime);
  //acc = _min(acc, vec2(length(p)-1., 0.));
  acc = _min(acc, vec2(_cube(p, vec3(1.)), 0.));
  
  acc = _min(acc, vec2(-p.y-h, 1.));
  return acc;
}

vec3 getNormal(vec3 p, float h)
{
  return -normalize(
    vec3(map(p-vec3(0.001,0,0), h).x-map(p+vec3(0.001,0,0), h).x,
    map(p-vec3(0.0,0.001,0), h).x-map(p+vec3(0.,0.001,0), h).x,
    map(p-vec3(0.0,0,0.001), h).x-map(p+vec3(0.,0,0.001), h).x)
  );
}


vec3 getCam(vec3 rd, vec2 uv)
{
  vec3 r = normalize(cross(rd, vec3(0,1,0)));
  vec3 u = normalize(cross(rd, r));
  return normalize(rd+(uv.x*r+uv.y*u)*2.);
}

vec3 trace(vec3 ro, vec3 rd, int steps, float h)
{

  vec3 p = ro;

  for (int i =0; i < steps; ++i)
  {
    vec2 dist = map(p, h);
    if (dist.x < 0.001)
      return vec3(dist.x, distance(p, ro), dist.y);

    p = p + rd * dist.x;
  }
  return vec3(-1.);
}

vec3 rdr(vec2 uv)
{ 
  vec3 col = vec3(0.);
  
  vec3 ro = vec3(0.,-5.,-5.+sin(fGlobalTime));
  vec3 ta = vec3(0.,0.,0.);
  vec3 rd = normalize(ta-ro);
  
  rd = getCam(rd, uv);


  float plan1h = 0.;
  vec3 res = trace(ro, rd, 128, plan1h);
  if (res.y > 0.)
  {
      vec3 p = ro+rd*res.y;
      vec3 n = getNormal(p,plan1h);
      col = n*.5+.5;
      vec3 lpos = vec3(0.,-5.,-5.);
    
    vec3 ldir = normalize(lpos-p);
    
    vec2 uvt = p.xz*.02;
    uvt+= texture(texNoise, p.xz).xx*.025;
    //col += texture(texVoronoi, uvt).xxx;
    
    n = normalize(n+(texture(texTex4, uvt).xyz-0.5)*.35+
    (texture(texVoronoi, uvt).xyz-0.5)*.5);

    float diff = sat(dot(n, ldir))*.25;
    vec3 h = normalize(lpos-p+rd);
    col = vec3(1.)*diff;
    float spec = sat(dot(h, n));
    col += vec3(1.)*pow(spec, 10.)*.75
    +vec3(1.)*(1.-pow(spec, .5))*.5;


    vec3 refr = refract(rd, n, .8);
    float plan2h = -1.7;
    vec3 refrres = trace(p, refr, 128, plan2h);
    if (refrres.y > 0.)
    {
      vec3 prefr = p+refr*refrres.y;
      vec3 nrefr = getNormal(prefr, plan2h);
      
      vec2 uvt2 = prefr.xz*.05;
      col += pow(texture(texTex3, uvt2*.1).x, .5)*vec3(.1,.5,.78);
      
      vec3 lpos2 = vec3(0,0,0);
      
      col += vec3(.8,.25,.75)*sat(dot(nrefr, -normalize(prefr-lpos2)))*.5;
    }
  }
  return col;
}

void main(void)
{
	vec2 uv = out_texcoord;
	uv -= 0.5;
	uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 col = rdr(uv);

	out_color = vec4(col, 1.);
}