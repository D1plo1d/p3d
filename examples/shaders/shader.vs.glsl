//#define TEXTURES

attribute vec3 position;
attribute vec3 normal;

#ifdef TEXTURES
attribute vec2 texCoord1;
#endif
attribute vec4 color;

uniform mat4 worldMatrix;
uniform mat4 projectionMatrix;
uniform mat4 worldInverseTransposeMatrix;

#ifdef TEXTURES
varying vec2 vTextureCoord;
#endif

varying vec4 vTransformedNormal;
varying vec4 vPosition;
varying vec4 vColor;


void main(void) {
  vPosition = worldMatrix * vec4(position, 1.0);
  gl_Position = projectionMatrix * vPosition;
  //gl_Position = vPosition;
  //vPosition = vec4(position, 1.0);
  
  #ifdef TEXTURES
    vTextureCoord = texCoord1;
  #endif
  vTransformedNormal = worldInverseTransposeMatrix * vec4(normal, 1.0);

  vColor = color;
}
