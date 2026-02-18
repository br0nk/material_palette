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

// Voronoi-specific
uniform float uCellScale;
uniform float uCellJitter;
uniform float uDistanceType; // 0=Euclidean, 1=Manhattan, 2=Chebyshev
uniform float uOutputMode;   // 0=F1, 1=F2, 2=F2-F1 (edge detection)
uniform float uCellSmoothness; // Smoothness of cell boundaries (0=sharp, higher=smoother)

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

// ============ HASH FUNCTIONS ============

vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

// 3D hash function for temporal evolution
vec3 hash33(vec3 p) {
    p = fract(p * vec3(0.1031, 0.1030, 0.0973));
    p += dot(p, p.yxz + 33.33);
    return fract((p.xxy + p.yxx) * p.zyx);
}

// ============ DISTANCE FUNCTIONS ============

float distanceMetric(vec2 a, vec2 b, float distType) {
    vec2 d = abs(a - b);
    if (distType < 0.5) {
        // Euclidean
        return length(a - b);
    } else if (distType < 1.5) {
        // Manhattan
        return d.x + d.y;
    } else {
        // Chebyshev
        return max(d.x, d.y);
    }
}

// ============ SMOOTH MIN (Exponential) ============
// Based on Inigo Quilez's smooth minimum technique
// https://iquilezles.org/articles/smin/

float smin(float a, float b, float k) {
    if (k <= 0.0) return min(a, b);
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}

// ============ VORONOI ============

// Smooth voronoi using exponential weighting for anti-aliased cell boundaries
vec3 voronoiSmooth(vec2 p, float jitter, float distType, float smoothness, float time) {
    vec2 n = floor(p);
    vec2 f = fract(p);

    // Use time slices for smooth interpolation
    float timeSlice = time * 0.5;
    float t0 = floor(timeSlice);
    float t1 = t0 + 1.0;
    float blend = smoothstep(0.0, 1.0, fract(timeSlice));

    // For smooth F1: accumulate weighted distances
    float smoothF1 = 0.0;
    float totalWeight = 0.0;

    // For F2 and edge detection: still track min distances
    float minDist1 = 8.0;
    float minDist2 = 8.0;
    vec2 minPoint = vec2(0.0);

    // Smoothness factor for exponential weighting (higher = smoother)
    float k = max(smoothness * 8.0, 0.001);

    // Expand search radius for smooth voronoi
    for (int j = -2; j <= 2; j++) {
        for (int i = -2; i <= 2; i++) {
            vec2 neighbor = vec2(float(i), float(j));

            // Get cell positions at two time slices and interpolate
            vec3 cellHash0 = hash33(vec3(n + neighbor, t0));
            vec3 cellHash1 = hash33(vec3(n + neighbor, t1));
            vec2 cellHash = mix(cellHash0.xy, cellHash1.xy, blend);

            // Apply jitter to cell point
            vec2 point = 0.5 + jitter * (cellHash - 0.5);

            float dist = distanceMetric(neighbor + point, f, distType);

            // Exponential weighting for smooth F1
            float w = exp(-k * dist);
            smoothF1 += dist * w;
            totalWeight += w;

            // Track hard min for F2 calculation
            if (dist < minDist1) {
                minDist2 = minDist1;
                minDist1 = dist;
                minPoint = cellHash;
            } else if (dist < minDist2) {
                minDist2 = dist;
            }
        }
    }

    // Compute smooth F1
    float f1 = (totalWeight > 0.0) ? smoothF1 / totalWeight : minDist1;

    // For F2, use smooth minimum between the two closest
    float f2 = smin(minDist2, minDist1 + 0.01, smoothness * 0.5) + 0.01;
    if (smoothness <= 0.0) f2 = minDist2;

    return vec3(f1, f2, hash22(minPoint).x);
}

float voronoiNoise(vec2 p, float jitter, float distType, float outputMode, float smoothness, float time) {
    vec3 v = voronoiSmooth(p, jitter, distType, smoothness, time);

    if (outputMode < 0.5) {
        // F1: distance to nearest (smoothed)
        return v.x;
    } else if (outputMode < 1.5) {
        // F2: distance to second nearest
        return v.y;
    } else {
        // F2-F1: edge detection (smoother edges)
        float edge = v.y - v.x;
        // Apply additional smoothing to edge detection
        if (smoothness > 0.0) {
            edge = smoothstep(0.0, 0.1 + smoothness * 0.2, edge);
        }
        return edge;
    }
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
    vec2 noiseCoord = uv * uCellScale * uNoiseDensity / 10.0;
    float eps = 0.01;

    float center = voronoiNoise(noiseCoord, uCellJitter, uDistanceType, uOutputMode, uCellSmoothness, time);
    float right = voronoiNoise(noiseCoord + vec2(eps, 0.0), uCellJitter, uDistanceType, uOutputMode, uCellSmoothness, time);
    float up = voronoiNoise(noiseCoord + vec2(0.0, eps), uCellJitter, uDistanceType, uOutputMode, uCellSmoothness, time);

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
    float time = uTime * uAnimSpeed;

    // Calculate base gradient position
    float gradientT = calculateGradient(uv);
    float edgeAtten = edgeAttenuation(gradientT, uEdgeFade, uEdgeFadeMode);

    // Generate Voronoi noise
    vec2 noiseCoord = uvAspect * uCellScale * uNoiseDensity / 10.0;
    float noise = voronoiNoise(noiseCoord, uCellJitter, uDistanceType, uOutputMode, uCellSmoothness, time);

    // Normalize noise to 0-1 range (approximate)
    noise = clamp(noise * 0.7, 0.0, 1.0);

    // Apply anti-aliasing smoothing
    float aaFactor = getAASmoothing(uv, uNoiseDensity);
    noise = mix(noise, smoothstep(0.0, 1.0, noise), aaFactor);

    // Add ordered dither
    float dither = orderedDither(fragCoord * 0.5) * uDitherStrength * 0.05;

    // Modulate gradient with noise
    float noiseMod = (noise - 0.5) * 2.0 * uNoiseIntensity * edgeAtten;
    float noisyT = clamp(gradientT + noiseMod + dither, 0.0, 1.0);

    // Get gradient color
    vec3 color = gradientColor(noisyT);

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

    fragColor = vec4(color, 1.0);
}
