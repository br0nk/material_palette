import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:material_palette/src/shader_wrap.dart';
import 'package:material_palette/src/shader_params.dart';
import 'package:material_palette/src/shader_definitions.dart';

/// A shader wrapper that applies a radial pixel dissolve effect to its child.
///
/// Dissolves outward from a configurable center point, breaking the child into
/// discrete pixel blocks that scatter radially. The dissolve ping-pongs
/// automatically; [speed] controls how fast.
class RadialPixelDissolveShaderWrap extends StatelessWidget {
  RadialPixelDissolveShaderWrap({
    super.key,
    required this.child,
    ShaderParams? params,
    this.animationMode = ShaderAnimationMode.running,
    this.animation,
    this.cache = false,
  }) : params = params ?? radialPixelDissolveShaderDef.defaults;

  final Widget child;
  final ShaderParams params;
  final ShaderAnimationMode animationMode;
  final Animation<double>? animation;
  final bool cache;

  static Future<void> precacheShader() =>
      ShaderBuilder.precacheShader('packages/material_palette/shaders/radial_pixel_dissolve.frag');

  @override
  Widget build(BuildContext context) {
    return ShaderWrap(
      shaderPath: 'packages/material_palette/shaders/radial_pixel_dissolve.frag',
      uniformsCallback: (uniforms, size, time) {
        uniforms
          ..setSize(size)
          ..setFloat(time)
          ..setFloat(params.get('centerX'))
          ..setFloat(params.get('centerY'))
          ..setFloat(params.get('scale'))
          ..setFloat(params.get('pixelSize'))
          ..setFloat(params.get('edgeWidth'))
          ..setFloat(params.get('scatter'))
          ..setFloat(params.get('noiseAmount'))
          ..setFloat(params.get('speed'));
      },
      animationMode: animationMode,
      animation: animation,
      cache: cache,
      child: child,
    );
  }
}
