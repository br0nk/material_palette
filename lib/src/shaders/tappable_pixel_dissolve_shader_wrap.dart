import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:material_palette/src/shader_wrap.dart';
import 'package:material_palette/src/shader_params.dart';
import 'package:material_palette/src/shader_definitions.dart';

/// A shader wrapper that applies a tap-triggered pixel dissolve effect.
///
/// Each tap creates a radial pixel dissolve that expands outward then contracts
/// back before disappearing. Supports up to 10 simultaneous tap points.
class TappablePixelDissolveShaderWrap extends StatefulWidget {
  TappablePixelDissolveShaderWrap({
    super.key,
    required this.child,
    ShaderParams? params,
    this.animationMode = ShaderAnimationMode.running,
    this.animation,
    this.cache = false,
    this.interactive = true,
    this.touchPoints,
  }) : params = params ?? tappablePixelDissolveShaderDef.defaults;

  final Widget child;
  final ShaderParams params;
  final ShaderAnimationMode animationMode;
  final Animation<double>? animation;
  final bool cache;
  final bool interactive;
  final List<ShaderTouchPoint>? touchPoints;

  static const int maxClicks = 10;

  static Future<void> precacheShader() =>
      ShaderBuilder.precacheShader('packages/material_palette/shaders/tappable_pixel_dissolve.frag');

  @override
  State<TappablePixelDissolveShaderWrap> createState() =>
      _TappablePixelDissolveShaderWrapState();
}

class _TappablePixelDissolveShaderWrapState
    extends State<TappablePixelDissolveShaderWrap> {
  final List<ShaderTouchPoint> _clicks = [];

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      _removeExpiredClicks();
      _clicks.add(ShaderTouchPoint(
        position: event.localPosition,
        startTime: DateTime.now(),
      ));
      if (_clicks.length > TappablePixelDissolveShaderWrap.maxClicks) {
        _clicks.removeAt(0);
      }
    });
  }

  void _removeExpiredClicks() {
    final speed = widget.params.get('speed');
    final lifetime = widget.params.get('lifetime');
    _clicks.removeWhere((click) =>
        click.elapsed > lifetime / speed);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.params;
    final clicks = widget.touchPoints ?? _clicks;

    return ShaderWrap(
      shaderPath: 'packages/material_palette/shaders/tappable_pixel_dissolve.frag',
      uniformsCallback: (uniforms, size, time) {
        uniforms.setSize(size);

        // Click count
        uniforms.setFloat(clicks.length.toDouble());

        // Touch points (always send 10, padding with zeros)
        for (int i = 0; i < TappablePixelDissolveShaderWrap.maxClicks; i++) {
          if (i < clicks.length) {
            uniforms.setFloats([clicks[i].position.dx, clicks[i].position.dy]);
          } else {
            uniforms.setFloats([0.0, 0.0]);
          }
        }

        // Times (always send 10, padding with zeros)
        for (int i = 0; i < TappablePixelDissolveShaderWrap.maxClicks; i++) {
          if (i < clicks.length) {
            uniforms.setFloat(clicks[i].elapsed);
          } else {
            uniforms.setFloat(0.0);
          }
        }

        // Pixel dissolve parameters
        uniforms.setFloat(p.get('pixelSize'));
        uniforms.setFloat(p.get('edgeWidth'));
        uniforms.setFloat(p.get('scatter'));
        uniforms.setFloat(p.get('noiseAmount'));
        uniforms.setFloat(p.get('speed'));
        uniforms.setFloat(p.get('radius'));
        uniforms.setFloat(p.get('lifetime'));
      },
      animationMode: widget.animationMode,
      animation: widget.animation,
      cache: widget.cache,
      onPointerDown: (widget.interactive && widget.touchPoints == null)
          ? _onPointerDown
          : null,
      child: widget.child,
    );
  }
}
