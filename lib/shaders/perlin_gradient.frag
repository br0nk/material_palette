#include <flutter/runtime_effect.glsl>

precision highp float;

// Core uniforms
uniform vec2 uSize;
uniform float uTime;

// Gradient settings
uniform float uGradientAngle;      // Gradient direction in degrees (90 = vertical)
uniform float uGradientScale;      // Scale factor for viewport (1.0 = full viewport)
uniform float uGradientOffset;     // Shift gradient position (-1 to 1)

// Noise settings
uniform float uNoiseDensity;       // Noise scale (higher = finer detail)
uniform float uNoiseIntensity;     // How much noise affects the gradient (0-1)
uniform float uDitherStrength;     // Dithering at color boundaries (0-1)

// Animation
uniform float uAnimSpeed;          // Noise animation speed

// Perlin-specific
uniform float uNoiseScale;         // Scale of the Perlin noise
uniform float uNoiseContrast;      // Contrast of the noise pattern

// Color palette (sRGB) - gradient endpoints
uniform vec3 uColorA;              // Start color
uniform vec3 uColorB;              // End color
uniform vec3 uColorMid;            // Optional mid color
uniform float uMidPosition;        // Position of mid color (0-1), -1 to disable

// Post-processing
uniform float uExposure;
uniform float uContrast;

// Lighting uniforms
uniform float uBumpStrength;       // Normal map intensity (0 = flat, 1 = full)
uniform vec3 uLightDir;            // Light direction (normalized)
uniform float uLightIntensity;     // Overall light intensity
uniform float uAmbient;            // Ambient light level
uniform float uSpecular;           // Specular highlight strength
uniform float uShininess;          // Specular shininess
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

// ============ HASH FUNCTIONS ============

vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy) * 2.0 - 1.0;
}

// 3D hash function returning 3D gradient
vec3 hash33(vec3 p) {
    p = fract(p * vec3(0.1031, 0.1030, 0.0973));
    p += dot(p, p.yxz + 33.33);
    return fract((p.xxy + p.yxx) * p.zyx) * 2.0 - 1.0;
}

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

// ============ PERLIN NOISE ============

// 2D Perlin noise (for static use)
float perlinNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    // Quintic interpolation for smoother results
    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    // Four corners
    float a = dot(hash22(i), f);
    float b = dot(hash22(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0));
    float c = dot(hash22(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0));
    float d = dot(hash22(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0));

    // Bilinear interpolation
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y) * 0.5 + 0.5;
}

// 3D Perlin noise - evolves over time without translation
float perlinNoise3D(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);

    // Quintic interpolation
    vec3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    // Eight corners of the cube
    float n000 = dot(hash33(i + vec3(0.0, 0.0, 0.0)), f - vec3(0.0, 0.0, 0.0));
    float n100 = dot(hash33(i + vec3(1.0, 0.0, 0.0)), f - vec3(1.0, 0.0, 0.0));
    float n010 = dot(hash33(i + vec3(0.0, 1.0, 0.0)), f - vec3(0.0, 1.0, 0.0));
    float n110 = dot(hash33(i + vec3(1.0, 1.0, 0.0)), f - vec3(1.0, 1.0, 0.0));
    float n001 = dot(hash33(i + vec3(0.0, 0.0, 1.0)), f - vec3(0.0, 0.0, 1.0));
    float n101 = dot(hash33(i + vec3(1.0, 0.0, 1.0)), f - vec3(1.0, 0.0, 1.0));
    float n011 = dot(hash33(i + vec3(0.0, 1.0, 1.0)), f - vec3(0.0, 1.0, 1.0));
    float n111 = dot(hash33(i + vec3(1.0, 1.0, 1.0)), f - vec3(1.0, 1.0, 1.0));

    // Trilinear interpolation
    float n00 = mix(n000, n100, u.x);
    float n01 = mix(n001, n101, u.x);
    float n10 = mix(n010, n110, u.x);
    float n11 = mix(n011, n111, u.x);

    float n0 = mix(n00, n10, u.y);
    float n1 = mix(n01, n11, u.y);

    return mix(n0, n1, u.z) * 0.5 + 0.5;
}

// Animated Perlin using time as Z coordinate - noise evolves in place
float animatedPerlin(vec2 p, float time) {
    return perlinNoise3D(vec3(p, time * 0.3));
}

// ============ DITHER ============

float orderedDither(vec2 p) {
    vec2 grid = mod(floor(p), 4.0);
    float dither = mod(grid.x + grid.y * 2.0, 4.0) / 4.0;
    return (dither - 0.5) * 2.0;
}

// ============ GRADIENT FUNCTION ============

float calculateGradient(vec2 uv) {
    float aspect = uSize.x / uSize.y;
    float angle = uGradientAngle * 3.14159265 / 180.0;
    vec2 dir = normalize(vec2(cos(angle) / aspect, sin(angle)));
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

    // Sample noise at neighboring points
    float center = animatedPerlin(noiseCoord, time);
    float right = animatedPerlin(noiseCoord + vec2(eps, 0.0), time);
    float up = animatedPerlin(noiseCoord + vec2(0.0, eps), time);

    // Compute gradient
    float dx = (right - center) / eps;
    float dy = (up - center) / eps;

    // Create normal from height gradient
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
    float aspect = uSize.x / uSize.y;
    vec2 uvAspect = vec2(uv.x * aspect, uv.y);
    float time = uTime * uAnimSpeed;

    // Calculate base gradient position
    float gradientT = calculateGradient(uv);

    // Edge attenuation for noise and bump
    float edgeAtten = edgeAttenuation(gradientT, uEdgeFade, uEdgeFadeMode);

    // Generate Perlin noise
    vec2 noiseCoord = uvAspect * uNoiseScale * uNoiseDensity / 10.0;
    float noise = animatedPerlin(noiseCoord, time);

    // Apply contrast to noise
    noise = pow(noise, uNoiseContrast);

    // AA: smooth noise based on screen-space derivatives
    float aaFactor = getAASmoothing(uv, uNoiseDensity);
    noise = mix(noise, smoothstep(0.0, 1.0, noise), aaFactor);

    // Add ordered dither for smoother transitions
    float dither = orderedDither(fragCoord * 0.5) * uDitherStrength * 0.05;

    // Modulate gradient with noise (attenuated at edges)
    float noiseMod = (noise - 0.5) * 2.0 * uNoiseIntensity * edgeAtten;
    float noisyT = clamp(gradientT + noiseMod + dither, 0.0, 1.0);

    // Get gradient color
    vec3 color = gradientColor(noisyT);

    // Compute normal with attenuated bump and apply lighting
    float attenuatedBump = uBumpStrength * edgeAtten;
    vec3 normal = computeNormal(uvAspect, time, attenuatedBump);
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
