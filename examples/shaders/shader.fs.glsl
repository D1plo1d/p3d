//#define TEXTURES
#define DIRECTIONAL_LIGHT // enable this if your scene includes a directional light source
//#define POINT_LIGHTS // enable this if your scene includes point light sources

#ifdef GL_ES
  precision highp float;
#endif

#ifdef TEXTURES
  varying vec2 vTextureCoord;
#endif

varying vec4 vTransformedNormal;
varying vec4 vPosition;

#ifdef TEXTURES
  uniform bool hasTexture1;
#else
  varying vec4 vColor;
#endif

uniform mat4 viewMatrix;
uniform bool enableLights;
uniform vec3 ambientColor;

#ifdef DIRECTIONAL_LIGHT
  uniform vec3 directionalColor;
  uniform vec3 lightingDirection;
#endif

#ifdef POINT_LIGHTS
  uniform vec3 pointLocation[1];
  uniform vec3 pointColor[1];
#endif

uniform sampler2D sampler1;

void main(void) {
  vec3 lightWeighting;
  if (!enableLights) {
    lightWeighting = vec3(1.0, 1.0, 1.0);
  } else {
    #ifdef POINT_LIGHTS
      vec3 lightDirection = normalize((viewMatrix * vec4(pointLocation[0], 1.0)).xyz - vPosition.xyz);
    #endif

    #ifdef DIRECTIONAL_LIGHT
      vec3 pointWeight = vec3(0.0, 0.0, 0.0);
      float directionalLightWeighting = max(dot(vTransformedNormal.xyz, lightingDirection), 0.0);
      lightWeighting = ambientColor + (directionalColor * directionalLightWeighting) + pointWeight;
    #else
      float directionalLightWeighting = max(dot(normalize(vTransformedNormal.xyz), lightDirection), 0.0);
      lightWeighting = ambientColor + pointColor[0] * directionalLightWeighting;
    #endif

  }

  vec4 fragmentColor;
  #ifdef TEXTURES
  if (hasTexture1) {
    fragmentColor = texture2D(sampler1, vec2(vTextureCoord.s, vTextureCoord.t));
  } else {
  #endif
    fragmentColor = vColor;// vec4(1.0, 1.0, 1.0, 1.0);
  #ifdef TEXTURES
  }
  #endif
  gl_FragColor = vec4(fragmentColor.rgb * lightWeighting, fragmentColor.a);
}
