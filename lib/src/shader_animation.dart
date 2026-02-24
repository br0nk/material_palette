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
  });

  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool loop;
  final bool reverse;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShaderAnimationConfig &&
          runtimeType == other.runtimeType &&
          duration == other.duration &&
          delay == other.delay &&
          curve == other.curve &&
          loop == other.loop &&
          reverse == other.reverse;

  @override
  int get hashCode => Object.hash(duration, delay, curve, loop, reverse);

  ShaderAnimationConfig copyWith({
    Duration? duration,
    Duration? delay,
    Curve? curve,
    bool? loop,
    bool? reverse,
  }) =>
      ShaderAnimationConfig(
        duration: duration ?? this.duration,
        delay: delay ?? this.delay,
        curve: curve ?? this.curve,
        loop: loop ?? this.loop,
        reverse: reverse ?? this.reverse,
      );
}
