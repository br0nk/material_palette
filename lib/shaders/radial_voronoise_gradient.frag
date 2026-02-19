#include <flutter/runtime_effect.glsl>

precision highp float;

// Core uniforms
uniform vec2 uSize;
uniform float uTime;

// Gradient settings
uniform vec2 uGradientCenter;
uniform float uGradientScale;
uniform float uGradientOffset;

// Noise settings
uniform float uNoiseIntensity;
uniform float uDitherStrength;

// Animation
uniform float uAnimSpeed;

// Voronoise-specific
uniform float uCellScale;
uniform float uNoiseBlend;
uniform float uEdgeSmoothness;

// Color palette (multi-stop)
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
uniform float uColorCount;
uniform float uSoftness;

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

// ============ HASH FUNCTIONS ============

vec3 hash33(vec3 p3) {
    p3 = fract(p3 * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yxx) * p3.zyx);
}

// ============ VORONOISE ============

float voronoise(vec2 p, float u, float v, float time) {
    float k = 1.0 + 63.0 * pow(1.0 - v, 6.0);

    vec2 i = floor(p);
    vec2 f = fract(p);

    vec2 a = vec2(0.0, 0.0);
    for (int y = -2; y <= 2; y++) {
        for (int x = -2; x <= 2; x++) {
            vec2 g = vec2(float(x), float(y));
            vec3 o = hash33(vec3(i + g, time * 0.1)) * vec3(u, u, 1.0);
            vec2 d = g - f + o.xy;
            float w = pow(1.0 - smoothstep(0.0, 1.414, length(d)), k);
            a += vec2(o.z * w, w);
        }
    }

    return a.x / a.y;
}

// ============ DITHER ============

float orderedDither(vec2 p) {
    vec2 grid = mod(floor(p), 4.0);
    float dither = mod(grid.x + grid.y * 2.0, 4.0) / 4.0;
    return (dither - 0.5) * 2.0;
}

// ============ RADIAL GRADIENT ============

float calculateRadialGradient(vec2 uv) {
    float aspect = uSize.x / uSize.y;
    vec2 adjustedUV = uv;
    adjustedUV.x = (adjustedUV.x - 0.5) * aspect + 0.5;

    vec2 centered = adjustedUV - uGradientCenter;
    float dist = length(centered);

    float t = dist / (0.5 * uGradientScale) + uGradientOffset;
    return clamp(t, 0.0, 1.0);
}

// ============ COLOR INTERPOLATION (MULTI-STOP) ============

vec4 getColorStop(int i) {
    if (i == 0) return uColor0; if (i == 1) return uColor1;
    if (i == 2) return uColor2; if (i == 3) return uColor3;
    if (i == 4) return uColor4; if (i == 5) return uColor5;
    if (i == 6) return uColor6; if (i == 7) return uColor7;
    if (i == 8) return uColor8; return uColor9;
}

vec4 gradientColor(float t) {
    int count = int(uColorCount);
    if (count < 2) count = 2; if (count > 10) count = 10;
    float stopT = t * float(count - 1);
    int idx = int(floor(stopT));
    if (idx >= count - 1) idx = count - 2;
    float frac = stopT - float(idx);
    vec4 sA = getColorStop(idx); vec4 sB = getColorStop(idx + 1);
    vec3 linA = srgbToLinear(sA.rgb); vec3 linB = srgbToLinear(sB.rgb);
    vec4 pmA = vec4(linA * sA.a, sA.a); vec4 pmB = vec4(linB * sB.a, sB.a);
    float blend;
    if (uSoftness >= 0.999) { blend = frac; }
    else if (uSoftness <= 0.001) { blend = step(0.5, frac); }
    else { float edge = 0.5 * uSoftness; blend = smoothstep(0.5 - edge, 0.5 + edge, frac); }
    return mix(pmA, pmB, blend);
}

// ============ NORMAL MAP FROM NOISE ============

vec3 computeNormal(vec2 uv, float time, float bumpStrength) {
    vec2 noiseCoord = uv * uCellScale;
    float eps = 0.01;

    float center = voronoise(noiseCoord, 1.0 - uNoiseBlend, uEdgeSmoothness, time);
    float right = voronoise(noiseCoord + vec2(eps, 0.0), 1.0 - uNoiseBlend, uEdgeSmoothness, time);
    float up = voronoise(noiseCoord + vec2(0.0, eps), 1.0 - uNoiseBlend, uEdgeSmoothness, time);

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

    float roughness2 = uRoughness * uRoughness;
    float effectiveShininess = mix(uShininess, 2.0, roughness2);

    vec3 specularColor = mix(vec3(1.0), color, uMetallic);
    float diffuseFactor = 1.0 - uMetallic * 0.9;

    vec3 ambient = color * uAmbient;

    float diff = max(dot(normal, lightDir), 0.0);
    vec3 diffuse = color * diff * (1.0 - uAmbient) * diffuseFactor;

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
    float time = uTime * uAnimSpeed * 0.02;

    // Calculate base radial gradient position
    float gradientT = calculateRadialGradient(uv);
    float edgeAtten = edgeAttenuation(gradientT, uEdgeFade, uEdgeFadeMode);

    // Generate Voronoise
    vec2 noiseCoord = uvAspect * uCellScale;
    float noise = voronoise(noiseCoord, 1.0 - uNoiseBlend, uEdgeSmoothness, time);

    // Apply anti-aliasing smoothing
    float aaFactor = getAASmoothing(uv, uCellScale);
    noise = mix(noise, smoothstep(0.0, 1.0, noise), aaFactor);

    // Add ordered dither
    float dither = orderedDither(fragCoord * 0.5) * uDitherStrength * 0.05;

    // Modulate gradient with noise
    float noiseMod = (noise - 0.5) * 2.0 * uNoiseIntensity * edgeAtten;
    float noisyT = clamp(gradientT + noiseMod + dither, 0.0, 1.0);

    // Get gradient color (premultiplied alpha)
    vec4 pmColor = gradientColor(noisyT);
    float alpha = pmColor.a;
    vec3 color = alpha > 0.001 ? pmColor.rgb / alpha : vec3(0.0);

    // Compute normal and apply lighting
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

    fragColor = vec4(color * alpha, alpha);
}
