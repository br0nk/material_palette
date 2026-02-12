import 'dart:ui' as ui show FragmentShader;

import 'package:flutter/material.dart';
import 'shader_types.dart';

// ── Core param container ─────────────────────────────────────────────────────

/// Generic immutable parameter bag for any shader.
/// All scalar values (including flattened Offset/Offset3D components) live in
/// [values]; colors live in [colors].
class ShaderParams {
  final Map<String, double> values;
  final Map<String, Color> colors;

  const ShaderParams({this.values = const {}, this.colors = const {}});

  double get(String key) => values[key] ?? 0.0;
  Color getColor(String key) => colors[key] ?? const Color(0xFF000000);

  /// Return a copy with one scalar value changed.
  ShaderParams withValue(String key, double value) {
    return ShaderParams(
      values: {...values, key: value},
      colors: colors,
    );
  }

  /// Return a copy with one color changed.
  ShaderParams withColor(String key, Color color) {
    return ShaderParams(
      values: values,
      colors: {...colors, key: color},
    );
  }

  /// Bulk merge update.
  ShaderParams copyWith({
    Map<String, double>? values,
    Map<String, Color>? colors,
  }) {
    return ShaderParams(
      values: values != null ? {...this.values, ...values} : this.values,
      colors: colors != null ? {...this.colors, ...colors} : this.colors,
    );
  }

  /// Serialize to JSON.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    for (final e in values.entries) {
      json[e.key] = e.value;
    }
    for (final e in colors.entries) {
      json[e.key] = _colorToHex(e.value);
    }
    return json;
  }

  static String _colorToHex(Color color) {
    return '#${color.red.toRadixString(16).padLeft(2, '0')}${color.green.toRadixString(16).padLeft(2, '0')}${color.blue.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }
}

// ── UI Defaults ──────────────────────────────────────────────────────────────

/// Map-based slider ranges for all parameters of a shader.
class ShaderUIDefaults {
  final Map<String, SliderRange> ranges;

  const ShaderUIDefaults(this.ranges);

  SliderRange? operator [](String key) => ranges[key];
}

// ── Uniform layout ───────────────────────────────────────────────────────────

enum UniformFieldType { float, color }

/// A single uniform field in a shader's layout.
class UniformField {
  final String key;
  final UniformFieldType type;

  const UniformField(this.key, [this.type = UniformFieldType.float]);
  const UniformField.color(this.key) : type = UniformFieldType.color;
}

/// Ordered list of uniform fields after the standard header (width, height, time).
class UniformLayout {
  final List<UniformField> fields;
  const UniformLayout(this.fields);
}

/// Write the standard header + all params to a [FragmentShader] according to [layout].
int setShaderUniforms(
  ui.FragmentShader shader,
  Size size,
  double time,
  ShaderParams params,
  UniformLayout layout,
) {
  int idx = 0;
  // Standard header
  shader
    ..setFloat(idx++, size.width)
    ..setFloat(idx++, size.height)
    ..setFloat(idx++, time);
  // Fields
  for (final field in layout.fields) {
    switch (field.type) {
      case UniformFieldType.float:
        shader.setFloat(idx++, params.get(field.key));
      case UniformFieldType.color:
        final c = params.getColor(field.key);
        shader.setFloat(idx, c.r);
        shader.setFloat(idx + 1, c.g);
        shader.setFloat(idx + 2, c.b);
        idx += 3;
    }
  }
  return idx;
}

// ── Reusable field / default / range groups ───────────────────────────────────

/// Composable building blocks for shader definitions.
abstract class ParamGroups {
  // ── Field groups (UniformField lists) ──

  static const linearGradientFields = [
    UniformField('gradientAngle'),
    UniformField('gradientScale'),
    UniformField('gradientOffset'),
  ];

  static const radialGradientFields = [
    UniformField('gradientCenterX'),
    UniformField('gradientCenterY'),
    UniformField('gradientScale'),
    UniformField('gradientOffset'),
  ];

  static const commonNoiseFields = [
    UniformField('noiseDensity'),
    UniformField('noiseIntensity'),
    UniformField('ditherStrength'),
    UniformField('animSpeed'),
  ];

  static const colorsFields = [
    UniformField.color('colorA'),
    UniformField.color('colorB'),
    UniformField.color('colorMid'),
    UniformField('midPosition'),
  ];

  static const postProcessingFields = [
    UniformField('exposure'),
    UniformField('contrast'),
  ];

  static const lightingFields = [
    UniformField('bumpStrength'),
    UniformField('lightDirX'),
    UniformField('lightDirY'),
    UniformField('lightDirZ'),
    UniformField('lightIntensity'),
    UniformField('ambient'),
    UniformField('specular'),
    UniformField('shininess'),
    UniformField('metallic'),
    UniformField('roughness'),
    UniformField('edgeFade'),
    UniformField('edgeFadeMode'),
  ];

  // ── Default value groups ──

  static const linearGradientDefaults = {
    'gradientAngle': 110.0,
    'gradientScale': 1.0,
    'gradientOffset': 0.0,
  };

  static const radialGradientDefaults = {
    'gradientCenterX': 0.5,
    'gradientCenterY': 0.5,
    'gradientScale': 1.0,
    'gradientOffset': 0.0,
  };

  static const commonNoiseDefaults = {
    'noiseDensity': 40.0,
    'noiseIntensity': 0.50,
    'ditherStrength': 0.0,
    'animSpeed': 0.5,
  };

  static const postProcessingDefaults = {
    'exposure': 1.0,
    'contrast': 1.0,
  };

  static const lightingDefaults = {
    'bumpStrength': 0.0,
    'lightDirX': 0.60,
    'lightDirY': 0.40,
    'lightDirZ': 1.0,
    'lightIntensity': 1.10,
    'ambient': 0.35,
    'specular': 0.30,
    'shininess': 24.0,
    'metallic': 0.0,
    'roughness': 0.50,
    'edgeFade': 0.0,
    'edgeFadeMode': 0.0,
  };

  // ── Range groups ──

  static const linearGradientRanges = {
    'gradientAngle': SliderRange('Angle', min: 0.0, max: 360.0),
    'gradientScale': SliderRange('Scale', min: 0.5, max: 3.0),
    'gradientOffset': SliderRange('Offset', min: -1.0, max: 1.0),
  };

  static const radialGradientRanges = {
    'gradientCenterX': SliderRange('Center X', min: 0.0, max: 1.0),
    'gradientCenterY': SliderRange('Center Y', min: 0.0, max: 1.0),
    'gradientScale': SliderRange('Scale', min: 0.5, max: 3.0),
    'gradientOffset': SliderRange('Offset', min: -1.0, max: 1.0),
  };

  static const commonNoiseRanges = {
    'noiseDensity': SliderRange('Density', min: 10.0, max: 200.0),
    'noiseIntensity': SliderRange('Intensity', min: 0.0, max: 1.0),
    'ditherStrength': SliderRange('Dither', min: 0.0, max: 1.0),
    'animSpeed': SliderRange('Speed', min: 0.0, max: 2.0),
  };

  /// Gritty shaders have a wider density range.
  static const grittyNoiseRanges = {
    'noiseDensity': SliderRange('Density', min: 100.0, max: 2000.0),
    'noiseIntensity': SliderRange('Intensity', min: 0.0, max: 1.0),
    'ditherStrength': SliderRange('Dither', min: 0.0, max: 1.0),
    'animSpeed': SliderRange('Speed', min: 0.0, max: 2.0),
  };

  static const colorsRanges = {
    'midPosition': SliderRange('Mid Position', min: -1.0, max: 1.0),
  };

  static const postProcessingRanges = {
    'exposure': SliderRange('Exposure', min: 0.5, max: 2.0),
    'contrast': SliderRange('Contrast', min: 0.5, max: 2.0),
  };

  static const lightingRanges = {
    'bumpStrength': SliderRange('Bump Strength', min: 0.0, max: 2.0),
    'lightDirX': SliderRange('Light X', min: -2.0, max: 2.0),
    'lightDirY': SliderRange('Light Y', min: -2.0, max: 2.0),
    'lightDirZ': SliderRange('Light Z', min: -2.0, max: 2.0),
    'lightIntensity': SliderRange('Light Intensity', min: 0.0, max: 2.0),
    'ambient': SliderRange('Ambient', min: 0.0, max: 1.0),
    'specular': SliderRange('Specular', min: 0.0, max: 1.0),
    'shininess': SliderRange('Shininess', min: 1.0, max: 128.0),
    'metallic': SliderRange('Metallic', min: 0.0, max: 1.0),
    'roughness': SliderRange('Roughness', min: 0.0, max: 1.0),
  };

  static const edgeFadeRanges = {
    'edgeFade': SliderRange('Edge Fade', min: 0.0, max: 3.0),
  };
}
