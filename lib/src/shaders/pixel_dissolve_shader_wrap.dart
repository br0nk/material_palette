import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:material_palette/src/shader_wrap.dart';
import 'package:material_palette/src/shader_params.dart';
import 'package:material_palette/src/shader_definitions.dart';

/// A shader wrapper that applies a pixel dissolve effect to its child.
///
/// Divides the child into a grid of square pixel blocks that scatter outward
/// along a directional dissolve sweep, creating a "Thanos snap" disintegration.
/// The dissolve ping-pongs automatically; [speed] controls how fast.
class PixelDissolveShaderWrap extends StatelessWidget {
  PixelDissolveShaderWrap({
    super.key,
    required this.child,
    ShaderParams? params,
    this.animationMode = ShaderAnimationMode.running,
    this.animation,
    this.cache = false,
  }) : params = params ?? pixelDissolveShaderDef.defaults;

  final Widget child;
  final ShaderParams params;
  final ShaderAnimationMode animationMode;
  final Animation<double>? animation;
  final bool cache;

  static Future<void> precacheShader() =>
      ShaderBuilder.precacheShader('packages/material_palette/shaders/pixel_dissolve.frag');

  @override
  Widget build(BuildContext context) {
    return ShaderWrap(
      shaderPath: 'packages/material_palette/shaders/pixel_dissolve.frag',
      uniformsCallback: (uniforms, size, time) {
        uniforms
          ..setSize(size)
          ..setFloat(time)
          ..setFloat(params.get('dirX'))
          ..setFloat(params.get('dirY'))
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
