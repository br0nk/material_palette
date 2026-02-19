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
uniform float uNoiseDensity;       // Stipple density (higher = finer grain)
uniform float uNoiseIntensity;     // How much noise affects the color (0-1)
uniform float uDitherStrength;     // Dithering at color boundaries (0-1)

// Animation
uniform float uAnimSpeed;          // Noise animation speed

// Color palette (sRGB, RGBA) - up to 10 gradient stops
uniform vec4 uColor0;
uniform vec4 uColor1;
uniform vec4 uColor2;
uniform vec4 uColor3;
uniform vec4 uColor4;
uniform vec4 uColor5;
uniform vec4 uColor6;
uniform vec4 uColor7;
uniform vec4 uColor8;
uniform vec4 uColor9;
uniform float uColorCount;         // Number of active color stops (2-10)
uniform float uSoftness;           // Transition sharpness (0=sharp, 1=smooth)

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

// ============ GRADIENT FUNCTION ============

float calculateGradient(vec2 uv) {
    // Convert angle to radians
    float aspect = uSize.x / uSize.y;
    float angle = uGradientAngle * 3.14159265 / 180.0;

    // Direction vector
    vec2 dir = normalize(vec2(cos(angle) / aspect, sin(angle)));

    // Center UV and apply scale
    vec2 centered = (uv - 0.5) / uGradientScale;

    // Project onto gradient direction
    float t = dot(centered, dir) + 0.5 + uGradientOffset;

    // Clamp to 0-1 range
    return clamp(t, 0.0, 1.0);
}

// ============ MULTI-STOP COLOR INTERPOLATION ============

// Get color stop by index (GLSL has no array indexing for uniforms in Flutter)
vec4 getColorStop(int i) {
    if (i == 0) return uColor0;
    if (i == 1) return uColor1;
    if (i == 2) return uColor2;
    if (i == 3) return uColor3;
    if (i == 4) return uColor4;
    if (i == 5) return uColor5;
    if (i == 6) return uColor6;
    if (i == 7) return uColor7;
    if (i == 8) return uColor8;
    return uColor9;
}

// Multi-stop gradient with softness control and premultiplied alpha
vec4 gradientColor(float t) {
    int count = int(uColorCount);
    if (count < 2) count = 2;
    if (count > 10) count = 10;

    // Map t to color stop space
    float stopT = t * float(count - 1);
    int idx = int(floor(stopT));
    if (idx >= count - 1) idx = count - 2;
    float frac = stopT - float(idx);

    // Get the two adjacent stops
    vec4 stopA = getColorStop(idx);
    vec4 stopB = getColorStop(idx + 1);

    // Convert sRGB to linear, premultiply alpha
    vec3 linA = srgbToLinear(stopA.rgb);
    vec3 linB = srgbToLinear(stopB.rgb);
    float alphaA = stopA.a;
    float alphaB = stopB.a;

    // Premultiply
    vec4 pmA = vec4(linA * alphaA, alphaA);
    vec4 pmB = vec4(linB * alphaB, alphaB);

    // Apply softness to transition
    float blend;
    if (uSoftness >= 0.999) {
        blend = frac; // fully smooth linear interpolation
    } else if (uSoftness <= 0.001) {
        blend = step(0.5, frac); // hard step
    } else {
        // smoothstep-based transition with adjustable width
        float edge = 0.5 * uSoftness;
        blend = smoothstep(0.5 - edge, 0.5 + edge, frac);
    }

    // Interpolate in premultiplied space
    return mix(pmA, pmB, blend);
}

// Apply stipple noise to create gritty color transition
vec4 grittyGradientColor(float gradientT, float noise) {
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

    // Calculate gradient position (0 to 1 across the gradient direction)
    float gradientT = calculateGradient(uv);

    // Generate stipple noise
    float grit = grittyTexture(fragCoord, time, gradientT);

    // Get color with gritty/stippled transition (premultiplied alpha)
    vec4 pmColor = grittyGradientColor(gradientT, grit);

    // Un-premultiply for post-processing
    float alpha = pmColor.a;
    vec3 color = alpha > 0.001 ? pmColor.rgb / alpha : vec3(0.0);

    // Apply contrast
    color = mix(vec3(0.5), color, uContrast);

    // Apply exposure
    color *= uExposure;

    // Clamp to [0,1] before sRGB conversion
    color = clamp(color, 0.0, 1.0);

    // Convert back to sRGB
    color = linearToSrgb(color);
    color = clamp(color, 0.0, 1.0);

    // Re-premultiply for output
    fragColor = vec4(color * alpha, alpha);
}
