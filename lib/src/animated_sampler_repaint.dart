// Fork of flutter_shaders v0.1.3 AnimatedSampler with repaint listenable.
// Original copyright below.
//
// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_shaders/flutter_shaders.dart' show AnimatedSamplerBuilder;

/// A variant of [AnimatedSampler] that accepts a [Listenable] to trigger
/// repaints without rebuilding the widget tree.
class AnimatedSamplerRepaint extends StatelessWidget {
  const AnimatedSamplerRepaint(
    this.builder, {
    required this.child,
    super.key,
    this.enabled = true,
    this.repaint,
  });

  final AnimatedSamplerBuilder builder;
  final bool enabled;
  final Widget child;

  /// Optional listenable that triggers a repaint (via
  /// [markNeedsCompositedLayerUpdate]) without rebuilding the widget.
  final Listenable? repaint;

  @override
  Widget build(BuildContext context) {
    return _ShaderSamplerBuilder(
      builder,
      enabled: enabled,
      repaint: repaint,
      child: child,
    );
  }
}

class _ShaderSamplerBuilder extends SingleChildRenderObjectWidget {
  const _ShaderSamplerBuilder(
    this.builder, {
    super.child,
    required this.enabled,
    this.repaint,
  });

  final AnimatedSamplerBuilder builder;
  final bool enabled;
  final Listenable? repaint;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderShaderSamplerBuilderWidget(
      devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
      builder: builder,
      enabled: enabled,
      repaint: repaint,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderObject renderObject) {
    (renderObject as _RenderShaderSamplerBuilderWidget)
      ..devicePixelRatio = MediaQuery.of(context).devicePixelRatio
      ..builder = builder
      ..enabled = enabled
      ..repaint = repaint;
  }
}

class _RenderShaderSamplerBuilderWidget extends RenderProxyBox {
  _RenderShaderSamplerBuilderWidget({
    required double devicePixelRatio,
    required AnimatedSamplerBuilder builder,
    required bool enabled,
    Listenable? repaint,
  })  : _devicePixelRatio = devicePixelRatio,
        _builder = builder,
        _enabled = enabled,
        _repaint = repaint {
    _repaint?.addListener(_onRepaint);
  }

  void _onRepaint() {
    markNeedsCompositedLayerUpdate();
  }

  Listenable? _repaint;
  set repaint(Listenable? value) {
    if (value == _repaint) {
      return;
    }
    _repaint?.removeListener(_onRepaint);
    _repaint = value;
    _repaint?.addListener(_onRepaint);
  }

  @override
  void dispose() {
    _repaint?.removeListener(_onRepaint);
    super.dispose();
  }

  @override
  OffsetLayer updateCompositedLayer(
      {required covariant _ShaderSamplerBuilderLayer? oldLayer}) {
    final _ShaderSamplerBuilderLayer layer =
        oldLayer ?? _ShaderSamplerBuilderLayer(builder);
    layer
      ..callback = builder
      ..size = size
      ..devicePixelRatio = devicePixelRatio;
    // Always mark dirty: the repaint listenable triggers
    // updateCompositedLayer but the layer setters no-op when
    // values are identical (same closure, same size, same dpr).
    layer.invalidate();
    return layer;
  }

  double get devicePixelRatio => _devicePixelRatio;
  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == devicePixelRatio) {
      return;
    }
    _devicePixelRatio = value;
    markNeedsCompositedLayerUpdate();
  }

  AnimatedSamplerBuilder get builder => _builder;
  AnimatedSamplerBuilder _builder;
  set builder(AnimatedSamplerBuilder value) {
    if (value == builder) {
      return;
    }
    _builder = value;
    markNeedsCompositedLayerUpdate();
  }

  bool get enabled => _enabled;
  bool _enabled;
  set enabled(bool value) {
    if (value == enabled) {
      return;
    }
    _enabled = value;
    markNeedsPaint();
    markNeedsCompositingBitsUpdate();
  }

  @override
  bool get isRepaintBoundary => alwaysNeedsCompositing;

  @override
  bool get alwaysNeedsCompositing => enabled;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (size.isEmpty) {
      return;
    }
    assert(!_enabled || offset == Offset.zero);
    return super.paint(context, offset);
  }
}

class _ShaderSamplerBuilderLayer extends OffsetLayer {
  _ShaderSamplerBuilderLayer(this._callback);

  ui.Picture? _lastPicture;

  /// Unconditionally marks this layer as needing to re-run [addToScene].
  /// Called by the render object when the repaint listenable fires, since
  /// the property setters no-op when the values haven't changed.
  void invalidate() {
    markNeedsAddToScene();
  }

  Size get size => _size;
  Size _size = Size.zero;
  set size(Size value) {
    if (value == size) {
      return;
    }
    _size = value;
    markNeedsAddToScene();
  }

  double get devicePixelRatio => _devicePixelRatio;
  double _devicePixelRatio = 1.0;
  set devicePixelRatio(double value) {
    if (value == devicePixelRatio) {
      return;
    }
    _devicePixelRatio = value;
    markNeedsAddToScene();
  }

  AnimatedSamplerBuilder get callback => _callback;
  AnimatedSamplerBuilder _callback;
  set callback(AnimatedSamplerBuilder value) {
    if (value == callback) {
      return;
    }
    _callback = value;
    markNeedsAddToScene();
  }

  ui.Image _buildChildScene(Rect bounds, double pixelRatio) {
    final ui.SceneBuilder builder = ui.SceneBuilder();
    final Matrix4 transform =
        Matrix4.diagonal3Values(pixelRatio, pixelRatio, 1);
    builder.pushTransform(transform.storage);
    addChildrenToScene(builder);
    builder.pop();
    final ui.Scene scene = builder.build();
    final ui.Image image = scene.toImageSync(
      (pixelRatio * bounds.width).ceil(),
      (pixelRatio * bounds.height).ceil(),
    );
    scene.dispose();
    return image;
  }

  @override
  void dispose() {
    _lastPicture?.dispose();
    super.dispose();
  }

  @override
  void addToScene(ui.SceneBuilder builder) {
    if (size.isEmpty) return;
    final ui.Image image = _buildChildScene(
      offset & size,
      devicePixelRatio,
    );
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    try {
      callback(image, size, canvas);
    } finally {
      image.dispose();
    }
    final ui.Picture picture = pictureRecorder.endRecording();
    _lastPicture?.dispose();
    _lastPicture = picture;
    builder.addPicture(offset, picture);
  }
}
