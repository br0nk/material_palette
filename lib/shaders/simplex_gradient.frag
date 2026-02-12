#include <flutter/runtime_effect.glsl>

precision highp float;

// Core uniforms
uniform vec2 uSize;
uniform float uTime;

// Gradient settings
uniform float uGradientAngle;
uniform float uGradientScale;
uniform float uGradientOffset;

// Noise settings
uniform float uNoiseDensity;
uniform float uNoiseIntensity;
uniform float uDitherStrength;

// Animation
uniform float uAnimSpeed;

// Simplex-specific
uniform float uNoiseScale;
uniform float uSharpness;

// Color palette
uniform vec3 uColorA;
uniform vec3 uColorB;
uniform vec3 uColorMid;
uniform float uMidPosition;

// Post-processing
uniform float uExposure;
uniform float uContrast;

// Lighting uniforms
uniform float uBumpStrength;
uniform vec3 uLightDir;
uniform float uLightIntensity;
uniform float uAmbient;
uniform float uSpecular;
uniform float uShininess;
uniform float uMetallic;           // 0=dielectric, 1=metal
uniform float uRoughness;          // 0=mirror, 1=matte
uniform float uEdgeFade;           // Edge attenuation for noise/bump
uniform float uEdgeFadeMode;       // 0=both, 1=start only, 2=end only

out vec4 fragColor;

// ============ COLOR SPACE CONVERSION ============

float srgbToLinear(float c) {
    return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4);
}

vec3 srgbToLinear(vec3 c) {
    return vec3(srgbToLinear(c.r), srgbToLinear(c.g), srgbToLinear(c.b));
}

float linearToSrgb(float c) {
    return c <= 0.0031308 ? c * 12.92 : 1.055 * pow(c, 1.0 / 2.4) - 0.055;
}

vec3 linearToSrgb(vec3 c) {
    return vec3(linearToSrgb(c.r), linearToSrgb(c.g), linearToSrgb(c.b));
}

// ============ SIMPLEX NOISE ============

vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec4 mod289(vec4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x * 34.0) + 1.0) * x); }
vec4 permute(vec4 x) { return mod289(((x * 34.0) + 1.0) * x); }
vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

// ============ ANTI-ALIASING ============

float getAASmoothing(vec2 uv, float density) {
    // Approximate AA based on density (higher density = more smoothing needed)
    return clamp(density * 0.003, 0.0, 0.3);
}

// ============ EDGE ATTENUATION ============

float edgeAttenuation(float t, float strength, float mode) {
    if (strength <= 0.0) return 1.0;

    float dist;
    if (mode < 0.5) {
        // Both ends - fade at t=0 and t=1
        dist = abs(t - 0.5) * 2.0;
    } else if (mode < 1.5) {
        // Start only - fade near t=0
        dist = 1.0 - t;
    } else {
        // End only - fade near t=1
        dist = t;
    }

    // Quadratic curve for smooth falloff
    float curve = dist * dist;

    // Scale by strength - only fully clip at max strength (3.0)
    float fadeAmount = curve * (strength / 3.0);

    return clamp(1.0 - fadeAmount, 0.0, 1.0);
}

// ============ SIMPLEX NOISE ============

float simplexNoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187, 0.366025403784439,
                        -0.577350269189626, 0.024390243902439);

    // First corner
    vec2 i = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);

    // Other corners
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

    // Permutations
    i = mod289(i);
    vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));

    vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
    m = m * m;
    m = m * m;

    // Gradients
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);

    // Compute final value
    vec3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;

    return 130.0 * dot(m, g) * 0.5 + 0.5;
}

// 3D Simplex noise - evolves over time without translation
float simplexNoise3D(vec3 v) {
    const vec2 C = vec2(1.0 / 6.0, 1.0 / 3.0);
    const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);

    // First corner
    vec3 i = floor(v + dot(v, C.yyy));
    vec3 x0 = v - i + dot(i, C.xxx);

    // Other corners
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min(g.xyz, l.zxy);
    vec3 i2 = max(g.xyz, l.zxy);

    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy;
    vec3 x3 = x0 - D.yyy;

    // Permutations
    i = mod289(i);
    vec4 p = permute(permute(permute(
        i.z + vec4(0.0, i1.z, i2.z, 1.0))
        + i.y + vec4(0.0, i1.y, i2.y, 1.0))
        + i.x + vec4(0.0, i1.x, i2.x, 1.0));

    // Gradients
    float n_ = 0.142857142857;
    vec3 ns = n_ * D.wyz - D.xzx;

    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);

    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_);

    vec4 x = x_ * ns.x + ns.yyyy;
    vec4 y = y_ * ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);

    vec4 b0 = vec4(x.xy, y.xy);
    vec4 b1 = vec4(x.zw, y.zw);

    vec4 s0 = floor(b0) * 2.0 + 1.0;
    vec4 s1 = floor(b1) * 2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));

    vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;

    vec3 p0 = vec3(a0.xy, h.x);
    vec3 p1 = vec3(a0.zw, h.y);
    vec3 p2 = vec3(a1.xy, h.z);
    vec3 p3 = vec3(a1.zw, h.w);

    // Normalise gradients
    vec4 norm = taylorInvSqrt(vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;

    // Mix final noise value
    vec4 m = max(0.6 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
    m = m * m;
    return 42.0 * dot(m * m, vec4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3))) * 0.5 + 0.5;
}

// Animated Simplex using time as Z coordinate - noise evolves in place
float animatedSimplex(vec2 p, float time) {
    return simplexNoise3D(vec3(p, time * 0.3));
}

// ============ DITHER ============

float orderedDither(vec2 p) {
    vec2 grid = mod(floor(p), 4.0);
    float dither = mod(grid.x + grid.y * 2.0, 4.0) / 4.0;
    return (dither - 0.5) * 2.0;
}

// ============ GRADIENT FUNCTION ============

float calculateGradient(vec2 uv) {
    float angle = uGradientAngle * 3.14159265 / 180.0;
    vec2 dir = vec2(cos(angle), sin(angle));
    vec2 centered = (uv - 0.5) / uGradientScale;
    float t = dot(centered, dir) + 0.5 + uGradientOffset;
    return clamp(t, 0.0, 1.0);
}

// ============ COLOR INTERPOLATION ============

vec3 gradientColor(float t) {
    vec3 colorA = srgbToLinear(uColorA);
    vec3 colorB = srgbToLinear(uColorB);

    if (uMidPosition >= 0.0 && uMidPosition <= 1.0) {
        vec3 colorMid = srgbToLinear(uColorMid);
        if (t < uMidPosition) {
            return mix(colorA, colorMid, t / uMidPosition);
        } else {
            return mix(colorMid, colorB, (t - uMidPosition) / (1.0 - uMidPosition));
        }
    } else {
        return mix(colorA, colorB, t);
    }
}

// ============ NORMAL MAP FROM NOISE ============

vec3 computeNormal(vec2 uv, float time, float bumpStrength) {
    vec2 noiseCoord = uv * uNoiseScale * uNoiseDensity / 10.0;
    float eps = 0.01;

    float center = animatedSimplex(noiseCoord, time);
    float right = animatedSimplex(noiseCoord + vec2(eps, 0.0), time);
    float up = animatedSimplex(noiseCoord + vec2(0.0, eps), time);

    float dx = (right - center) / eps;
    float dy = (up - center) / eps;

    vec3 normal = normalize(vec3(-dx * bumpStrength, -dy * bumpStrength, 1.0));
    return normal;
}

// ============ LIGHTING ============

vec3 applyLighting(vec3 color, vec3 normal) {
    if (uBumpStrength < 0.001) return color;

    vec3 lightDir = normalize(uLightDir);
    vec3 viewDir = vec3(0.0, 0.0, 1.0);

    // Roughness affects shininess (squared for perceptual linearity)
    float roughness2 = uRoughness * uRoughness;
    float effectiveShininess = mix(uShininess, 2.0, roughness2);

    // Metal: specular = base color, reduced diffuse
    // Dielectric: specular = white, full diffuse
    vec3 specularColor = mix(vec3(1.0), color, uMetallic);
    float diffuseFactor = 1.0 - uMetallic * 0.9;

    // Ambient
    vec3 ambient = color * uAmbient;

    // Diffuse (Lambertian, reduced for metals)
    float diff = max(dot(normal, lightDir), 0.0);
    vec3 diffuse = color * diff * (1.0 - uAmbient) * diffuseFactor;

    // Specular (Blinn-Phong with roughness)
    vec3 halfDir = normalize(lightDir + viewDir);
    float NdotH = max(dot(normal, halfDir), 0.0);
    float specIntensity = mix(1.0, 0.2, roughness2);
    float spec = pow(NdotH, effectiveShininess) * specIntensity;
    vec3 specular = specularColor * spec * uSpecular;

    return (ambient + diffuse + specular) * uLightIntensity;
}

// ============ MAIN ============

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uSize;
    float time = uTime * uAnimSpeed;

    // Calculate base gradient position
    float gradientT = calculateGradient(uv);

    // Edge attenuation for noise and bump
    float edgeAtten = edgeAttenuation(gradientT, uEdgeFade, uEdgeFadeMode);

    // Generate Simplex noise
    vec2 noiseCoord = uv * uNoiseScale * uNoiseDensity / 10.0;
    float noise = animatedSimplex(noiseCoord, time);

    // Apply sharpness (contrast on noise)
    noise = pow(noise, uSharpness);

    // AA: smooth noise based on screen-space derivatives
    float aaFactor = getAASmoothing(uv, uNoiseDensity);
    noise = mix(noise, smoothstep(0.0, 1.0, noise), aaFactor);

    // Add ordered dither
    float dither = orderedDither(fragCoord * 0.5) * uDitherStrength * 0.05;

    // Modulate gradient with noise (attenuated at edges)
    float noiseMod = (noise - 0.5) * 2.0 * uNoiseIntensity * edgeAtten;
    float noisyT = clamp(gradientT + noiseMod + dither, 0.0, 1.0);

    // Get gradient color
    vec3 color = gradientColor(noisyT);

    // Compute normal with attenuated bump and apply lighting
    float attenuatedBump = uBumpStrength * edgeAtten;
    vec3 normal = computeNormal(uv, time, attenuatedBump);
    color = applyLighting(color, normal);

    // Apply contrast
    color = mix(vec3(0.5), color, uContrast);

    // Apply exposure
    color *= uExposure;

    // Clamp to [0,1] before sRGB conversion
    color = clamp(color, 0.0, 1.0);

    // Convert back to sRGB
    color = linearToSrgb(color);
    color = clamp(color, 0.0, 1.0);

    fragColor = vec4(color, 1.0);
}
