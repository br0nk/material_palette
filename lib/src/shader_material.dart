import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:material_palette/src/shader_params.dart';
import 'package:material_palette/src/shader_definitions.dart';

/// All available shader material types for the shape builder.
/// Excludes MarbleSmear (which requires interactive state).
enum ShaderMaterialType {
  grittyGradient('Grit', 'packages/material_palette/shaders/gritty_gradient.frag'),
  radialGrittyGradient('Grit Radial', 'packages/material_palette/shaders/radial_gritty_gradient.frag'),
  perlinGradient('Perlin', 'packages/material_palette/shaders/perlin_gradient.frag'),
  radialPerlinGradient('Perlin Radial', 'packages/material_palette/shaders/radial_perlin_gradient.frag'),
  simplexGradient('Simplex', 'packages/material_palette/shaders/simplex_gradient.frag'),
  radialSimplexGradient('Simplex Radial', 'packages/material_palette/shaders/radial_simplex_gradient.frag'),
  fbmGradient('FBM', 'packages/material_palette/shaders/fbm_gradient.frag'),
  radialFbmGradient('FBM Radial', 'packages/material_palette/shaders/radial_fbm_gradient.frag'),
  turbulenceGradient('Turbulence', 'packages/material_palette/shaders/turbulence_gradient.frag'),
  radialTurbulenceGradient('Turbulence Radial', 'packages/material_palette/shaders/radial_turbulence_gradient.frag'),
  voronoiGradient('Voronoi', 'packages/material_palette/shaders/voronoi_gradient.frag'),
  radialVoronoiGradient('Voronoi Radial', 'packages/material_palette/shaders/radial_voronoi_gradient.frag'),
  voronoiseGradient('Voronoise', 'packages/material_palette/shaders/voronoise_gradient.frag'),
  radialVoronoiseGradient('Voronoise Radial', 'packages/material_palette/shaders/radial_voronoise_gradient.frag');

  const ShaderMaterialType(this.displayName, this.shaderAssetPath);
  final String displayName;
  final String shaderAssetPath;
}

/// A shader material assigned to a canvas shape.
class ShaderMaterial {
  final ShaderMaterialType type;
  final ShaderParams params;

  const ShaderMaterial({required this.type, required this.params});

  ShaderMaterial copyWithParams(ShaderParams newParams) {
    return ShaderMaterial(type: type, params: newParams);
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'params': params.toJson(),
    };
  }
}

/// Registry providing default params, uniform setting, and serialization
/// for all shader material types.
class ShaderMaterialRegistry {
  /// Returns default params for a given material type.
  static ShaderParams defaultParams(ShaderMaterialType type) {
    return shaderDefinitions[type]!.defaults;
  }

  /// Returns the shader definition for a given material type.
  static ShaderDefinition definition(ShaderMaterialType type) {
    return shaderDefinitions[type]!;
  }

  /// Sets uniforms on a [FragmentShader] for the given material type.
  static void setUniforms(
    ShaderMaterialType type,
    ui.FragmentShader shader,
    Size size,
    double time,
    ShaderParams params,
  ) {
    final def = shaderDefinitions[type]!;
    setShaderUniforms(shader, size, time, params, def.layout);
  }

  /// Serializes params to JSON for export.
  static Map<String, dynamic> paramsToJson(ShaderMaterialType type, ShaderParams params) {
    return params.toJson();
  }
}
