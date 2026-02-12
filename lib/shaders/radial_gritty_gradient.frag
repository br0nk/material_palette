#include <flutter/runtime_effect.glsl>

precision highp float;

// Core uniforms
uniform vec2 uSize;
uniform float uTime;

// Gradient settings
uniform vec2 uGradientCenter;     // Center point (0.5, 0.5 = center)
uniform float uGradientScale;     // Scale factor (1.0 = covers viewport)
uniform float uGradientOffset;    // Shift gradient position (-1 to 1)

// Noise settings
uniform float uNoiseDensity;      // Stipple density (higher = finer grain)
uniform float uNoiseIntensity;    // How much noise affects the color (0-1)
uniform float uDitherStrength;    // Dithering at color boundaries (0-1)

// Animation
uniform float uAnimSpeed;         // Noise animation speed

// Color palette (sRGB) - gradient endpoints
uniform vec3 uColorA;             // Center color
uniform vec3 uColorB;             // Edge color
uniform vec3 uColorMid;           // Optional mid color
uniform float uMidPosition;       // Position of mid color (0-1), -1 to disable

// Post-processing
uniform float uExposure;
uniform float uContrast;

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

// ============ NOISE FUNCTIONS ============

// High-quality random for stipple effect
float random(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Stipple noise - creates the grainy/risograph effect
float stippleNoise(vec2 p, float time) {
    // Pixel-level random stipple
    vec2 pixelCoord = floor(p);

    // Add subtle time-based variation if animated
    float timeOffset = time * 100.0;

    // Multiple layers of stipple at different scales
    float stipple1 = random(pixelCoord + timeOffset);
    float stipple2 = random(pixelCoord * 0.5 + timeOffset * 0.7);
    float stipple3 = random(pixelCoord * 2.0 + timeOffset * 1.3);

    // Combine with weighted average favoring fine detail
    return stipple1 * 0.6 + stipple2 * 0.25 + stipple3 * 0.15;
}

// Dither pattern for smoother color transitions
float orderedDither(vec2 p) {
    // 4x4 Bayer matrix approximation
    vec2 grid = mod(floor(p), 4.0);
    float dither = mod(grid.x + grid.y * 2.0, 4.0) / 4.0;
    return (dither - 0.5) * 2.0;
}

// Combined gritty texture
float grittyTexture(vec2 fragCoord, float time, float gradientT) {
    // Scale coordinates for stipple density
    vec2 p = fragCoord * uNoiseDensity / 100.0;

    // Get base stipple noise
    float stipple = stippleNoise(p, time);

    // Add ordered dither near gradient boundaries for smoother transitions
    float dither = orderedDither(fragCoord * 0.5) * uDitherStrength * 0.1;

    // Combine stipple with subtle dither
    float grit = stipple + dither;

    return grit;
}

// ============ RADIAL GRADIENT FUNCTION ============

float calculateRadialGradient(vec2 uv) {
    // Account for aspect ratio to make gradient circular
    float aspect = uSize.x / uSize.y;
    vec2 adjustedUV = uv;
    adjustedUV.x = (adjustedUV.x - 0.5) * aspect + 0.5;

    // Calculate distance from center
    vec2 centered = adjustedUV - uGradientCenter;
    float dist = length(centered);

    // Apply scale and offset
    float t = dist / (0.5 * uGradientScale) + uGradientOffset;

    // Clamp to 0-1 range
    return clamp(t, 0.0, 1.0);
}

// ============ COLOR INTERPOLATION ============

vec3 gradientColor(float t) {
    vec3 colorA = srgbToLinear(uColorA);
    vec3 colorB = srgbToLinear(uColorB);

    if (uMidPosition >= 0.0 && uMidPosition <= 1.0) {
        // 3-stop gradient
        vec3 colorMid = srgbToLinear(uColorMid);

        if (t < uMidPosition) {
            return mix(colorA, colorMid, t / uMidPosition);
        } else {
            return mix(colorMid, colorB, (t - uMidPosition) / (1.0 - uMidPosition));
        }
    } else {
        // Simple 2-stop gradient
        return mix(colorA, colorB, t);
    }
}

// Apply stipple noise to create gritty color transition
vec3 grittyGradientColor(float gradientT, float noise) {
    // Use noise to modulate the gradient threshold
    // This creates the stippled/dithered transition effect
    float noiseMod = (noise - 0.5) * 2.0 * uNoiseIntensity;

    // Modify gradient position based on noise
    float noisyT = gradientT + noiseMod;
    noisyT = clamp(noisyT, 0.0, 1.0);

    return gradientColor(noisyT);
}

// ============ MAIN ============

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uSize;
    float time = uTime * uAnimSpeed;

    // Calculate radial gradient position (0 at center, 1 at edge)
    float gradientT = calculateRadialGradient(uv);

    // Generate stipple noise
    float grit = grittyTexture(fragCoord, time, gradientT);

    // Get color with gritty/stippled transition
    vec3 color = grittyGradientColor(gradientT, grit);

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
