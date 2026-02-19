#include <flutter/runtime_effect.glsl>

precision highp float;

// Core uniforms
uniform vec2 uSize;
uniform float uTime;          // elapsed time in seconds

// Burn direction
uniform float uDirX;
uniform float uDirY;

// Noise & edge
uniform float uNoiseScale;
uniform float uEdgeWidth;
uniform float uGlowIntensity;
uniform vec3 uFireColor;      // RGB fire color
uniform float uSpeed;         // burn speed multiplier

// Child texture
uniform sampler2D uTexture;

out vec4 fragColor;

// ============ HASH FUNCTIONS ============

vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy) * 2.0 - 1.0;
}

// ============ PERLIN NOISE ============

float perlinNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    float a = dot(hash22(i), f);
    float b = dot(hash22(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0));
    float c = dot(hash22(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0));
    float d = dot(hash22(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y) * 0.5 + 0.5;
}

// ============ FBM ============

float fbmNoise(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    float maxValue = 0.0;

    mat2 rot = mat2(0.8, 0.6, -0.6, 0.8);

    for (int i = 0; i < 5; i++) {
        value += amplitude * perlinNoise(p * frequency);
        maxValue += amplitude;
        amplitude *= 0.5;
        frequency *= 2.1;
        p = rot * p;
    }

    return value / maxValue;
}

// ============ MAIN ============

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;

    // Normalize direction
    vec2 dir = vec2(uDirX, uDirY);
    float dirLen = length(dir);
    if (dirLen > 0.0) {
        dir /= dirLen;
    } else {
        dir = vec2(1.0, 0.0);
    }

    // Ping-pong progress from elapsed time and speed
    float t = uTime * uSpeed;
    float progress = abs(mod(t, 2.0) - 1.0);

    // Burn line: directional gradient + fbm noise distortion
    float noiseVal = fbmNoise(uv * uNoiseScale);
    float d = dot(uv, dir) + uEdgeWidth * (noiseVal - 0.5) * 2.0
              - progress * (1.0 + uEdgeWidth);

    // Sample child texture
    vec4 tex = texture(uTexture, uv);

    // Edge threshold: smoothstep for soft burn edge
    float edgeThickness = 0.06;
    float burnMask = smoothstep(-edgeThickness, edgeThickness, d);

    // Fire glow at the edge
    float glowWidth = 0.12;
    float glow = smoothstep(-glowWidth - edgeThickness, -edgeThickness, d)
               * (1.0 - burnMask);

    // Modulate glow with noise for organic flicker
    float glowNoise = fbmNoise(uv * uNoiseScale * 2.0 + 42.0);
    glow *= 0.5 + 0.5 * glowNoise;

    // Fire color
    vec3 fireColor = uFireColor * uGlowIntensity;

    // Compose: child texture with burn mask + fire glow
    // Use premultiplied alpha compositing (same pattern as ripple.frag)
    vec3 color = tex.rgb * burnMask + fireColor * glow;
    float alpha = tex.a * burnMask + glow;
    alpha = clamp(alpha, 0.0, 1.0);

    fragColor = vec4(color, alpha);
}
