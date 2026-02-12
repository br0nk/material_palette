import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'shader_types.dart';

export 'shader_types.dart';

/// Callback for setting shader uniforms.
/// Receives the [UniformsSetter], current [Size], and elapsed [time] in seconds.
typedef UniformsCallback = void Function(
    UniformsSetter uniforms, Size size, double time);

/// A generic, reusable wrapper that applies a fragment shader to its child.
/// Subclasses or users can provide a [uniformsCallback] to set arbitrary uniforms.
///
/// Manages its own ticker for animation and provides the elapsed time to the
/// uniforms callback.
class ShaderWrap extends StatefulWidget {
  const ShaderWrap({
    super.key,
    required this.child,
    required this.shaderPath,
    required this.uniformsCallback,
    this.backgroundColor = Colors.transparent,
    this.onPointerDown,
    this.animationMode = ShaderAnimationMode.running,
    this.animation,
    this.cache = false,
  });

  final Widget child;
  final String shaderPath;
  final UniformsCallback uniformsCallback;
  final Color? backgroundColor;

  /// Optional pointer down callback for interactive shaders.
  final void Function(PointerDownEvent event)? onPointerDown;

  /// Controls how time is driven. Defaults to [ShaderAnimationMode.running].
  final ShaderAnimationMode animationMode;

  /// External animation that drives time when
  /// [animationMode] == [ShaderAnimationMode.animation].
  final Animation<double>? animation;

  /// When true, wraps the shader output in a [RepaintBoundary].
  final bool cache;

  @override
  State<ShaderWrap> createState() => _ShaderWrapState();
}

class _ShaderWrapState extends State<ShaderWrap>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupTimeSource();
  }

  // NOTE: Unlike ShaderFill (which uses CustomPaint's repaint
  // listenable to skip build()), ShaderWrap must use setState because
  // AnimatedSampler doesn't expose a repaint listenable API.
  void _setupTimeSource() {
    switch (widget.animationMode) {
      case ShaderAnimationMode.running:
        _ticker = createTicker((elapsed) {
          setState(() {
            _elapsed = elapsed;
          });
        });
        _ticker!.start();
        break;
      case ShaderAnimationMode.animation:
        widget.animation!.addListener(_onAnimationTick);
        break;
      case ShaderAnimationMode.static:
        break;
    }
  }

  void _onAnimationTick() {
    setState(() {});
  }

  @override
  void didUpdateWidget(ShaderWrap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.animationMode != widget.animationMode ||
        oldWidget.animation != widget.animation) {
      // Tear down old source
      switch (oldWidget.animationMode) {
        case ShaderAnimationMode.running:
          _ticker?.stop();
          _ticker?.dispose();
          _ticker = null;
          _elapsed = Duration.zero;
          break;
        case ShaderAnimationMode.animation:
          oldWidget.animation?.removeListener(_onAnimationTick);
          break;
        case ShaderAnimationMode.static:
          break;
      }

      // Set up new source
      _setupTimeSource();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    if (widget.animationMode == ShaderAnimationMode.animation) {
      widget.animation?.removeListener(_onAnimationTick);
    }
    super.dispose();
  }

  double get _time {
    switch (widget.animationMode) {
      case ShaderAnimationMode.static:
        return 0.0;
      case ShaderAnimationMode.running:
        return _elapsed.inMilliseconds.toDouble() / 1000;
      case ShaderAnimationMode.animation:
        return widget.animation!.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = _time;

    Widget result = ShaderBuilder(
      (context, shader, child) {
        return AnimatedSampler(
          (image, size, canvas) {
            shader
              ..setFloatUniforms((uniforms) {
                widget.uniformsCallback(uniforms, size, time);
              })
              ..setImageSampler(0, image);

            canvas.drawRect(
              Rect.fromLTWH(0, 0, size.width, size.height),
              Paint()..shader = shader,
            );
          },
          child: widget.child,
        );
      },
      assetKey: widget.shaderPath,
    );

    if (widget.onPointerDown != null) {
      result = Listener(
        onPointerDown: widget.onPointerDown,
        child: result,
      );
    }

    if (widget.cache) {
      result = RepaintBoundary(child: result);
    }

    return result;
  }
}
