import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:material_palette/src/shader_wrap.dart';
import 'package:material_palette/src/shader_params.dart';
import 'package:material_palette/src/shader_definitions.dart';

/// A shader wrapper that applies a smoke dissolve effect to its child.
///
/// Animates a diagonal smoke that progressively makes the child transparent
/// along an organic turbulence-noise edge with a smoky glow.
/// The smoke ping-pongs automatically; [speed] controls how fast.
class SmokeShaderWrap extends StatelessWidget {
  SmokeShaderWrap({
    super.key,
    required this.child,
    ShaderParams? params,
    this.animationMode = ShaderAnimationMode.running,
    this.animation,
    this.cache = false,
  }) : params = params ?? smokeShaderDef.defaults;

  final Widget child;
  final ShaderParams params;
  final ShaderAnimationMode animationMode;
  final Animation<double>? animation;
  final bool cache;

  static Future<void> precacheShader() =>
      ShaderBuilder.precacheShader('packages/material_palette/shaders/smoke.frag');

  @override
  Widget build(BuildContext context) {
    return ShaderWrap(
      shaderPath: 'packages/material_palette/shaders/smoke.frag',
      uniformsCallback: (uniforms, size, time) {
        final smokeColor = params.getColor('smokeColor');
        uniforms
          ..setSize(size)
          ..setFloat(time)
          ..setFloat(params.get('dirX'))
          ..setFloat(params.get('dirY'))
          ..setFloat(params.get('noiseScale'))
          ..setFloat(params.get('edgeWidth'))
          ..setFloat(params.get('glowIntensity'))
          ..setFloat(smokeColor.r)
          ..setFloat(smokeColor.g)
          ..setFloat(smokeColor.b)
          ..setFloat(params.get('speed'));
      },
      animationMode: animationMode,
      animation: animation,
      cache: cache,
      child: child,
    );
  }
}
