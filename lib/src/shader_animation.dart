import 'package:flutter/animation.dart';

/// A declarative animation configuration for shader widgets.
///
/// Describes *how* an animation should behave (duration, delay, curve,
/// looping). The hosting widget's state is responsible for driving time —
/// this object owns no ticker or controller.
///
/// ```dart
/// BurnShaderWrap(
///   animationMode: ShaderAnimationMode.explicit,
///   animationConfig: ShaderAnimationConfig(
///     curve: Curves.easeInOut,
///     duration: Duration(seconds: 2),
///   ),
///   child: myWidget,
/// )
/// ```
class ShaderAnimationConfig {
  const ShaderAnimationConfig({
    this.duration = const Duration(seconds: 3),
    this.delay = Duration.zero,
    this.curve = Curves.linear,
    this.loop = false,
    this.reverse = false,
    this.invert = false,
    this.rangeStart = 0.0,
    this.rangeEnd = 1.0,
  });

  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool loop;
  final bool reverse;

  /// When true, the animation runs in reverse direction within the range.
  ///
  /// With the default range [0, 1], the animation goes from 1→0
  /// instead of 0→1. Combined with a custom range like [0.2, 0.8],
  /// the animation goes from 0.8→0.2 instead of 0.2→0.8.
  final bool invert;

  /// The start of the output range. Progress 0.0 maps to this value.
  /// Defaults to 0.0. Must be in [0, 1].
  final double rangeStart;

  /// The end of the output range. Progress 1.0 maps to this value.
  /// Defaults to 1.0. Must be in [0, 1].
  final double rangeEnd;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShaderAnimationConfig &&
          runtimeType == other.runtimeType &&
          duration == other.duration &&
          delay == other.delay &&
          curve == other.curve &&
          loop == other.loop &&
          reverse == other.reverse &&
          invert == other.invert &&
          rangeStart == other.rangeStart &&
          rangeEnd == other.rangeEnd;

  @override
  int get hashCode => Object.hash(
      duration, delay, curve, loop, reverse, invert, rangeStart, rangeEnd);

  ShaderAnimationConfig copyWith({
    Duration? duration,
    Duration? delay,
    Curve? curve,
    bool? loop,
    bool? reverse,
    bool? invert,
    double? rangeStart,
    double? rangeEnd,
  }) =>
      ShaderAnimationConfig(
        duration: duration ?? this.duration,
        delay: delay ?? this.delay,
        curve: curve ?? this.curve,
        loop: loop ?? this.loop,
        reverse: reverse ?? this.reverse,
        invert: invert ?? this.invert,
        rangeStart: rangeStart ?? this.rangeStart,
        rangeEnd: rangeEnd ?? this.rangeEnd,
      );
}
