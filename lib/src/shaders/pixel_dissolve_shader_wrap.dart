import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:material_palette/src/shader_animation.dart';
import 'package:material_palette/src/shader_wrap.dart';
import 'package:material_palette/src/shader_params.dart';
import 'package:material_palette/src/shader_definitions.dart';

/// A shader wrapper that applies a pixel dissolve effect to its child.
///
/// Divides the child into a grid of square pixel blocks that scatter outward
/// along a directional dissolve sweep, creating a "Thanos snap" disintegration.
///
/// In `continuous` mode the [speed] param controls how fast the ping-pong
/// animation runs. In `explicit` mode the shader receives 0-1 progress
/// from a [ShaderAnimationConfig].
class PixelDissolveShaderWrap extends StatelessWidget {
  PixelDissolveShaderWrap({
    super.key,
    required this.child,
    ShaderParams? params,
    this.animationMode = ShaderAnimationMode.continuous,
    this.time = 0,
    this.animationConfig,
    this.cache = false,
  }) : params = params ?? pixelDissolveShaderDef.defaults;

  final Widget child;
  final ShaderParams params;
  final ShaderAnimationMode animationMode;
  final double time;
  final ShaderAnimationConfig? animationConfig;
  final bool cache;

  static Future<void> precacheShader() =>
      ShaderBuilder.precacheShader('packages/material_palette/shaders/pixel_dissolve.frag');

  @override
  Widget build(BuildContext context) {
    return ShaderWrap(
      shaderPath: 'packages/material_palette/shaders/pixel_dissolve.frag',
      uniformsCallback: (uniforms, size, time) {
        final progress = animationMode == ShaderAnimationMode.continuous
            ? pingPong(time * params.get('speed'))
            : time;

        uniforms
          ..setSize(size)
          ..setFloat(progress)
          ..setFloat(params.get('angle'))
          ..setFloat(params.get('scale'))
          ..setFloat(params.get('offset'))
          ..setFloat(params.get('pixelSize'))
          ..setFloat(params.get('edgeWidth'))
          ..setFloat(params.get('scatter'))
          ..setFloat(params.get('noiseAmount'));
      },
      animationMode: animationMode,
      time: time,
      animationConfig: animationConfig,
      cache: cache,
      child: child,
    );
  }
}
