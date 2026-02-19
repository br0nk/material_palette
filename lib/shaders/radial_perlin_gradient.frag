#include <flutter/runtime_effect.glsl>

precision highp float;

// Core uniforms
uniform vec2 uSize;
uniform float uTime;

// Gradient settings
uniform vec2 uGradientCenter;      // Center point (0.5, 0.5 = center)
uniform float uGradientScale;      // Scale factor (1.0 = covers viewport)
uniform float uGradientOffset;     // Shift gradient position (-1 to 1)

// Noise settings
uniform float uNoiseIntensity;     // How much noise affects the gradient (0-1)
uniform float uDitherStrength;     // Dithering at color boundaries (0-1)

// Animation
uniform float uAnimSpeed;          // Noise animation speed

// Perlin-specific
uniform float uNoiseScale;         // Scale of the Perlin noise
uniform float uNoiseContrast;      // Contrast of the noise pattern

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

float getAASmoothing(vec2 uv, float scale) {
    // Approximate AA based on scale (higher scale = more smoothing needed)
    return clamp(scale * 0.006, 0.0, 0.3);
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

// ============ RADIAL GRADIENT FUNCTION ============

float calculateRadialGradient(vec2 uv) {
    float aspect = uSize.x / uSize.y;
    vec2 adjustedUV = uv;
    adjustedUV.x = (adjustedUV.x - 0.5) * aspect + 0.5;

    vec2 centered = adjustedUV - uGradientCenter;
    float dist = length(centered);

    float t = dist / (0.5 * uGradientScale) + uGradientOffset;
    return clamp(t, 0.0, 1.0);
}

// ============ MULTI-STOP COLOR INTERPOLATION ============

// Get color stop by index
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
        blend = frac;
    } else if (uSoftness <= 0.001) {
        blend = step(0.5, frac);
    } else {
        float edge = 0.5 * uSoftness;
        blend = smoothstep(0.5 - edge, 0.5 + edge, frac);
    }

    // Interpolate in premultiplied space
    return mix(pmA, pmB, blend);
}

// ============ NORMAL MAP FROM NOISE ============

vec3 computeNormal(vec2 uv, float time, float bumpStrength) {
    vec2 noiseCoord = uv * uNoiseScale;
    float eps = 0.01;

    float center = animatedPerlin(noiseCoord, time);
    float right = animatedPerlin(noiseCoord + vec2(eps, 0.0), time);
    float up = animatedPerlin(noiseCoord + vec2(0.0, eps), time);

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
    float aspect = uSize.x / uSize.y;
    vec2 uvAspect = vec2(uv.x * aspect, uv.y);
    float time = uTime * uAnimSpeed;

    // Calculate base radial gradient position
    float gradientT = calculateRadialGradient(uv);

    // Edge attenuation for noise and bump
    float edgeAtten = edgeAttenuation(gradientT, uEdgeFade, uEdgeFadeMode);

    // Generate Perlin noise
    vec2 noiseCoord = uvAspect * uNoiseScale;
    float noise = animatedPerlin(noiseCoord, time);

    // Clamp noise to valid range before pow() - Perlin noise with non-unit
    // gradient vectors can slightly exceed [0,1], and pow(negative, x) is undefined
    noise = clamp(noise, 0.0, 1.0);

    // Apply contrast to noise
    noise = pow(noise, uNoiseContrast);

    // AA: smooth noise based on screen-space derivatives
    float aaFactor = getAASmoothing(uv, uNoiseScale);
    noise = mix(noise, smoothstep(0.0, 1.0, noise), aaFactor);

    // Add ordered dither for smoother transitions
    float dither = orderedDither(fragCoord * 0.5) * uDitherStrength * 0.05;

    // Modulate gradient with noise (attenuated at edges)
    float noiseMod = (noise - 0.5) * 2.0 * uNoiseIntensity * edgeAtten;
    float noisyT = clamp(gradientT + noiseMod + dither, 0.0, 1.0);

    // Get gradient color (premultiplied alpha)
    vec4 pmColor = gradientColor(noisyT);

    // Un-premultiply for post-processing
    float alpha = pmColor.a;
    vec3 color = alpha > 0.001 ? pmColor.rgb / alpha : vec3(0.0);

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

    // Re-premultiply for output
    fragColor = vec4(color * alpha, alpha);
}
