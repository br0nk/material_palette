import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:material_palette/src/shader_animation.dart';
import 'package:material_palette/src/shader_wrap.dart';
import 'package:material_palette/src/shader_params.dart';
import 'package:material_palette/src/shader_definitions.dart';

/// A shader wrapper that applies a burn dissolve effect to its child.
///
/// Animates a diagonal burn that progressively makes the child transparent
/// along an organic FBM-noise edge with a fire glow.
///
/// In `continuous` mode the [speed] param controls how fast the ping-pong
/// animation runs. In `explicit` mode the shader receives 0-1 progress
/// from a [ShaderAnimationConfig].
class BurnShaderWrap extends StatelessWidget {
  BurnShaderWrap({
    super.key,
    required this.child,
    ShaderParams? params,
    this.animationMode = ShaderAnimationMode.continuous,
    this.time = 0,
    this.animationConfig,
    this.cache = false,
  }) : params = params ?? burnShaderDef.defaults;

  final Widget child;
  final ShaderParams params;
  final ShaderAnimationMode animationMode;
  final double time;
  final ShaderAnimationConfig? animationConfig;
  final bool cache;

  static Future<void> precacheShader() =>
      ShaderBuilder.precacheShader('packages/material_palette/shaders/burn.frag');

  @override
  Widget build(BuildContext context) {
    return ShaderWrap(
      shaderPath: 'packages/material_palette/shaders/burn.frag',
      uniformsCallback: (uniforms, size, time) {
        // In running mode, compute ping-pong progress from raw elapsed time.
        // In animation mode, time is already 0-1 from the Animation.
        final progress = animationMode == ShaderAnimationMode.continuous
            ? pingPong(time * params.get('speed'))
            : time;

        final fireColor = params.getColor('fireColor');
        uniforms
          ..setSize(size)
          ..setFloat(progress)
          ..setFloat(params.get('dirX'))
          ..setFloat(params.get('dirY'))
          ..setFloat(params.get('noiseScale'))
          ..setFloat(params.get('edgeWidth'))
          ..setFloat(params.get('glowIntensity'))
          ..setFloat(fireColor.r)
          ..setFloat(fireColor.g)
          ..setFloat(fireColor.b);
      },
      animationMode: animationMode,
      time: time,
      animationConfig: animationConfig,
      cache: cache,
      child: child,
    );
  }
}
