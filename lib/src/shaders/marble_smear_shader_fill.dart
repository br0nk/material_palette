import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:material_palette/src/shader_fill.dart';
import 'package:material_palette/src/shader_params.dart';
import 'package:material_palette/src/shader_definitions.dart';

/// A shader wrapper that renders an animated marble/agate pattern with smudge interaction.
class MarbleSmearShaderFill extends StatefulWidget {
  MarbleSmearShaderFill({
    super.key,
    required this.width,
    required this.height,
    this.backgroundColor = Colors.transparent,
    ShaderParams? params,
    this.animationMode = ShaderAnimationMode.running,
    this.animation,
    this.cache = false,
    this.interactive = true,
    this.smudges,
    this.activeSmudge,
  }) : params = params ?? marbleSmearShaderDef.defaults;

  final double width;
  final double height;
  final Color? backgroundColor;
  final ShaderParams params;
  final ShaderAnimationMode animationMode;
  final Animation<double>? animation;
  final bool cache;
  final bool interactive;
  final List<ShaderSmudgeData>? smudges;
  final ShaderSmudgeData? activeSmudge;

  static const int maxSmudges = 10;
  static const double smudgeLifetime = 8.0;

  static Future<void> precacheShader() =>
      ShaderBuilder.precacheShader('packages/material_palette/shaders/marble_smear.frag');

  @override
  State<MarbleSmearShaderFill> createState() => _MarbleSmearShaderFillState();
}

class _MarbleSmearShaderFillState extends State<MarbleSmearShaderFill> {
  final List<ShaderSmudgeData> _smudges = [];
  ShaderSmudgeData? _activeSmudge;

  bool get _isInternalInteraction =>
      widget.interactive && widget.smudges == null;

  Offset _normalizePosition(Offset localPosition, Size size) {
    final normalizedX =
        (localPosition.dx / size.width - 0.5) * 2.0 * (size.width / size.height);
    final normalizedY = (localPosition.dy / size.height - 0.5) * 2.0;
    return Offset(normalizedX, normalizedY);
  }

  void _onPointerDown(PointerDownEvent event) {
    final size = Size(widget.width, widget.height);
    final normalizedPos = _normalizePosition(event.localPosition, size);
    setState(() {
      _activeSmudge = ShaderSmudgeData(
        startPosition: normalizedPos,
        endPosition: normalizedPos,
        startTime: DateTime.now(),
      );
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_activeSmudge == null) return;
    final size = Size(widget.width, widget.height);
    final normalizedPos = _normalizePosition(event.localPosition, size);
    setState(() {
      _activeSmudge = _activeSmudge!.copyWithEnd(normalizedPos);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_activeSmudge == null) return;
    final size = Size(widget.width, widget.height);
    final normalizedPos = _normalizePosition(event.localPosition, size);
    setState(() {
      final finalSmudge = _activeSmudge!.copyWithEnd(normalizedPos);
      _smudges.add(finalSmudge);
      while (_smudges.length > MarbleSmearShaderFill.maxSmudges) {
        _smudges.removeAt(0);
      }
      _activeSmudge = null;
    });
  }

  void _onPointerCancel(PointerCancelEvent event) {
    setState(() {
      _activeSmudge = null;
    });
  }

  void _removeExpiredSmudges() {
    _smudges.removeWhere(
        (smudge) => smudge.elapsed > MarbleSmearShaderFill.smudgeLifetime);
  }

  void _setUniforms(FragmentShader shader, Size size, double time) {
    final smudges = widget.smudges ?? _smudges;
    final activeSmudge = widget.smudges != null ? widget.activeSmudge : _activeSmudge;

    if (widget.smudges == null) {
      _removeExpiredSmudges();
    }

    final bgColor = widget.backgroundColor ?? Colors.transparent;
    final mergedParams = widget.params.withColor('bgColor', bgColor);
    int idx = setShaderUniforms(shader, size, time, mergedParams, marbleSmearShaderDef.layout);

    // Build combined list of smudges (completed + active)
    final allSmudges = <ShaderSmudgeData>[...smudges];
    if (activeSmudge != null) {
      allSmudges.add(activeSmudge);
    }

    // Smudge count
    shader.setFloat(idx++, allSmudges.length.toDouble());

    // Smudge data: 10 smudges x (startX, startY, endX, endY, time) = 50 floats
    for (int i = 0; i < MarbleSmearShaderFill.maxSmudges; i++) {
      if (i < allSmudges.length) {
        final smudge = allSmudges[i];
        shader.setFloat(idx++, smudge.startPosition.dx);
        shader.setFloat(idx++, smudge.startPosition.dy);
        shader.setFloat(idx++, smudge.endPosition.dx);
        shader.setFloat(idx++, smudge.endPosition.dy);
        shader.setFloat(idx++, smudge.elapsed);
      } else {
        shader.setFloat(idx++, 0.0);
        shader.setFloat(idx++, 0.0);
        shader.setFloat(idx++, 0.0);
        shader.setFloat(idx++, 0.0);
        shader.setFloat(idx++, 0.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = ShaderFill(
      width: widget.width,
      height: widget.height,
      shaderPath: 'packages/material_palette/shaders/marble_smear.frag',
      backgroundColor: widget.backgroundColor,
      uniformsCallback: _setUniforms,
      animationMode: widget.animationMode,
      animation: widget.animation,
      cache: widget.cache,
    );

    if (_isInternalInteraction) {
      child = Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: child,
      );
    }

    return child;
  }
}
