#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;
uniform float time;
uniform vec4 uBgColor;         // Background color (RGBA, default transparent)
uniform vec2 uOrigin1;
uniform vec2 uOrigin2;
// Controllable ripple parameters
uniform float uFrequency;      // Wave frequency in Hz (default 1.5)
uniform float uNumWaves;       // Number of waves per unit distance (default 5.0)
uniform float uAmplitude;      // Wave amplitude/strength (default 1.0)
uniform float uSpeed;          // Animation speed multiplier (default 1.0)
uniform sampler2D uTexture;

out vec4 fragColor;

// Simple circular wave function
float wave(vec2 pos, float t, float freq, float numWaves, vec2 center) {
	vec2 delta = pos - center;
	delta.x *= uSize.x / uSize.y;
	float d = length(delta);
	d = log(1.0 + exp(d));
	return 1.0/(1.0+20.0*d*d) *
		   sin(2.0*3.1415*(-numWaves*d + t*freq));
}

// This height map combines two waves from origins outside viewport
float height(vec2 pos, float t) {
	float w;
	w =  wave(pos, t, uFrequency, uNumWaves, uOrigin1);
	w += wave(pos, t, uFrequency, uNumWaves, uOrigin2);
	return w * uAmplitude;
}

// Discrete differentiation
vec2 normal(vec2 pos, float t) {
	return 	vec2(height(pos - vec2(0.01, 0), t) - height(pos, t), 
				 height(pos - vec2(0, 0.01), t) - height(pos, t));
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  vec2 uvn = 2.0*uv - vec2(1.0);
  
  // Fade out ripple effect near edges to prevent discontinuities
  float edgeFade = 0.01;
  float fadeX = smoothstep(0.0, edgeFade, uv.x) * smoothstep(1.0, 1.0 - edgeFade, uv.x);
  float fadeY = smoothstep(0.0, edgeFade, uv.y) * smoothstep(1.0, 1.0 - edgeFade, uv.y);
  float fade = fadeX * fadeY;
  
  uv += normal(uvn, time * uSpeed) * fade;
  vec4 tex = texture(uTexture, uv);
  // Composite texture over background using premultiplied-alpha "source over"
  vec4 bg = vec4(uBgColor.rgb * uBgColor.a, uBgColor.a);
  fragColor = tex + bg * (1.0 - tex.a);
}