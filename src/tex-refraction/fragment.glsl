uniform float uTime;
uniform vec2 uMouse;
uniform vec2 uResolution;
uniform sampler2D uTexture;
varying vec2 vUv;

const float PI = 3.14159265;
const float fov = PI / 6.;
const vec3 cPos = vec3(0., 0., 3.);

float sdSphere(vec3 p, float s) {
  return length(p) - s;
}


float sdPlane(vec3 p, vec3 n, float h) {
  return dot(p, n) + h;
}

float smin(float a, float b, float k) {
  float h = max(k - abs(a - b), 0.0) / k;
  return min(a, b) - h * h * k * (1.0 / 4.0);
}

struct Intersect {
  float dist;
  float gray;
};

Intersect map(vec3 p) {
  Intersect i;
  float aspectRatio = uResolution.x / uResolution.y;
  vec2 m = vec2(uMouse.x, uMouse.y / (aspectRatio));
  float n = sin(p.x * 7. + uTime * .005) + cos(p.y * 7. + uTime * .005);
  float center = sdSphere(p + vec3(m * 1., 0.), .5 + n * .001);
  float interactive = sdSphere(p - vec3(m * 1.8, 0.), .2 + n * .001);
  float bg = sdPlane(p + vec3(0., 0., -0.35), vec3(0., 0., 1.), .5);
  i.dist = min(bg, smin(center, interactive, 1.7));
  i.gray = bg <= i.dist ? 1. : 0.;
  return i;
}

vec3 getNormal(in vec3 p) {
  const float eps = .0001;
  const vec2 h = vec2(eps, 0);
  return normalize(vec3(
    map(p + h.xyy).dist - map(p - h.xyy).dist,
    map(p + h.yxy).dist - map(p - h.yxy).dist,
    map(p + h.yyx).dist - map(p - h.yyx).dist
  ));
}

vec2 shiftTex(vec2 uv, float size) {
  vec2 result = uv * (1.0 - size) + size * 0.5;
  return result;
}

float genShadow(vec3 ro, vec3 rd){
  float h = 0.0;
  float c = 0.001;
  float r = 1.0;
  float shadowCoef = 0.5;
  for(float t = 0.0; t < 10.; t++){
    h = map(ro - rd * c).dist;
    if(h < 0.001){
      return shadowCoef;
    }
    r = min(r, h * 2.5 / c);
    c += h;
  }
  return mix(shadowCoef, 1.0, r);
}

const float redScale = 0.298912;
const float greenScale = 0.586611;
const float blueScale = 0.114478;
const vec3 monochromeScale = vec3(redScale, greenScale, blueScale);
const vec3 lightDir = vec3(0., -0.25, -1.);

void main() {
  vec2 p = (gl_FragCoord.xy * 2.0 - uResolution) / uResolution.x;

  vec3 ray = normalize(vec3(sin(fov) * p.x, sin(fov) * p.y, -cos(fov)));
  vec3 rayPos = cPos;
  float tmp = 0.;
  float dist = 0.;
  float gray = 0.;
  for (int i = 0; i < 64; i++) {
    rayPos = cPos + tmp * ray;
    Intersect intersect = map(rayPos);
    dist = intersect.dist;
    gray = intersect.gray;
    if (dist < 0.002 || tmp > 5.) {
      break;
    }
    tmp += dist;
  }

  vec2 ratio = vec2(
    min((uResolution.x / uResolution.y), 1.),
    min((uResolution.y / uResolution.x), 1.)
  );
  vec2 uv = vec2(
    vUv.x * ratio.x + (1. - ratio.x) * .5,
    vUv.y * ratio.y + (1. - ratio.y) * .5
  );
  vec3 color;
  float shadow = 1.0;
  if (abs(dist) < 0.01) {
    vec3 normal = getNormal(rayPos);
    float distortion = dot(normal, -vec3(0., 0., -1.));
    shadow = genShadow(rayPos + normal * 0.001, lightDir);
    color = gray > .5 ?
      mix(texture2D(uTexture, uv).rgb * 1.5, vec3(dot(texture2D(uTexture, uv).rgb, monochromeScale) * .4), shadow):
      texture2D(uTexture, shiftTex(uv, .55) + normal.xy * 0.2 * distortion).rgb;
  } else {
    color = vec3(dot(texture2D(uTexture, uv).rgb, monochromeScale)) * .6;
  }

  gl_FragColor = vec4(color, 1.0);
}
