import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import '../shader_fill.dart';
import '../shader_params.dart';
import '../shader_definitions.dart';

/// A shader wrapper that renders an FBM (Fractional Brownian Motion) gradient effect.
class FbmGradientShaderFill extends StatelessWidget {
  FbmGradientShaderFill({
    super.key,
    required this.width,
    required this.height,
    ShaderParams? params,
    this.animationMode = ShaderAnimationMode.running,
    this.animation,
    this.cache = false,
  }) : params = params ?? fbmGradientDef.defaults;

  final double width;
  final double height;
  final ShaderParams params;
  final ShaderAnimationMode animationMode;
  final Animation<double>? animation;
  final bool cache;

  static Future<void> precacheShader() =>
      ShaderBuilder.precacheShader('packages/material_palette/shaders/fbm_gradient.frag');

  void _setUniforms(FragmentShader shader, Size size, double time) {
    setShaderUniforms(shader, size, time, params, fbmGradientDef.layout);
  }

  @override
  Widget build(BuildContext context) {
    return ShaderFill(
      width: width,
      height: height,
      shaderPath: 'packages/material_palette/shaders/fbm_gradient.frag',
      uniformsCallback: _setUniforms,
      animationMode: animationMode,
      animation: animation,
      cache: cache,
    );
  }
}
