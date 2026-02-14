import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:material_palette/src/shader_wrap.dart';
import 'package:material_palette/src/shader_params.dart';
import 'package:material_palette/src/shader_definitions.dart';

/// A shader wrapper that applies a time-based ripple effect to its child.
class RippleShaderWrap extends StatelessWidget {
  RippleShaderWrap({
    super.key,
    required this.child,
    this.backgroundColor = Colors.transparent,
    ShaderParams? params,
    this.animationMode = ShaderAnimationMode.running,
    this.animation,
    this.cache = false,
  }) : params = params ?? rippleShaderDef.defaults;

  final Widget child;
  final Color backgroundColor;
  final ShaderParams params;
  final ShaderAnimationMode animationMode;
  final Animation<double>? animation;
  final bool cache;

  static Future<void> precacheShader() =>
      ShaderBuilder.precacheShader('packages/material_palette/shaders/ripple.frag');

  /// Scales an origin direction to ensure it's outside the viewport.
  static Offset _scaleOriginOutsideViewport(Offset origin, double scale) {
    final length = origin.distance;
    if (length == 0) return Offset(scale * 1.5, 0);
    final normalized = origin / length;
    return normalized * scale * 1.5;
  }

  @override
  Widget build(BuildContext context) {
    final origin1 = Offset(params.get('origin1X'), params.get('origin1Y'));
    final origin2 = Offset(params.get('origin2X'), params.get('origin2Y'));
    final originScale = params.get('originScale');
    final o1 = _scaleOriginOutsideViewport(origin1, originScale);
    final o2 = _scaleOriginOutsideViewport(origin2, originScale);

    return ShaderWrap(
      shaderPath: 'packages/material_palette/shaders/ripple.frag',
      uniformsCallback: (uniforms, size, time) {
        uniforms
          ..setSize(size)
          ..setFloat(time)
          ..setFloat(backgroundColor.r)
          ..setFloat(backgroundColor.g)
          ..setFloat(backgroundColor.b)
          ..setFloat(backgroundColor.a)
          ..setFloat(o1.dx)
          ..setFloat(o1.dy)
          ..setFloat(o2.dx)
          ..setFloat(o2.dy)
          ..setFloat(params.get('frequency'))
          ..setFloat(params.get('numWaves'))
          ..setFloat(params.get('amplitude'))
          ..setFloat(params.get('speed'));
      },
      animationMode: animationMode,
      animation: animation,
      cache: cache,
      child: child,
    );
  }
}
