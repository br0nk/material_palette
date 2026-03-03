import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_palette/material_palette.dart';

import 'gallery_presets.dart';
import 'shader_cards.dart';
import 'shader_card_components.dart';

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final swatchSize = (screenWidth - 48) / 3;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Preset Gallery'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: galleryPresets.length,
        itemBuilder: (context, index) {
          return _GallerySwatch(
            preset: galleryPresets[index],
            size: swatchSize,
          );
        },
      ),
    );
  }
}

class _GallerySwatch extends StatelessWidget {
  const _GallerySwatch({
    required this.preset,
    required this.size,
  });

  final GalleryPreset preset;
  final double size;

  void _copyToClipboard(BuildContext context) {
    final paramsCode = PresetGenerator.shaderParams(preset.params);
    final clipboardText = '${preset.name}\n\n${preset.shaderType}:\n\n$paramsCode';
    Clipboard.setData(ClipboardData(text: clipboardText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied "${preset.name}" preset to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildShaderFill() {
    switch (preset.shaderType) {
      case 'Turbulence':
        return TurbulenceGradientShaderFill(
          width: size, height: size, params: preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Turbulence Radial':
        return RadialTurbulenceGradientShaderFill(
          width: size, height: size, params: preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'FBM':
        return FbmGradientShaderFill(
          width: size, height: size, params: preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'FBM Radial':
        return RadialFbmGradientShaderFill(
          width: size, height: size, params: preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Simplex':
        return SimplexGradientShaderFill(
          width: size, height: size, params: preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Simplex Radial':
        return RadialSimplexGradientShaderFill(
          width: size, height: size, params: preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Perlin':
        return PerlinGradientShaderFill(
          width: size, height: size, params: preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Perlin Radial':
        return RadialPerlinGradientShaderFill(
          width: size, height: size, params: preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Voronoi':
        return VoronoiGradientShaderFill(
          width: size, height: size, params: preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Voronoi Radial':
        return RadialVoronoiGradientShaderFill(
          width: size, height: size, params: preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Voronoise':
        return VoronoiseGradientShaderFill(
          width: size, height: size, params: preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Voronoise Radial':
        return RadialVoronoiseGradientShaderFill(
          width: size, height: size, params: preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Grit':
        return GrittyGradientShaderFill(
          width: size, height: size, params: preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Grit Radial':
        return RadialGrittyGradientShaderFill(
          width: size, height: size, params: preset.params,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      case 'Smarble':
        return MarbleSmearShaderFill(
          width: size, height: size, params: preset.params,
          backgroundColor: const Color(0xFF202329), interactive: false,
          animationMode: ShaderAnimationMode.continuous, cache: true,
        );
      default:
        return Container(color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: preset.name,
      child: GestureDetector(
        onTap: () => _copyToClipboard(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kShaderCardBorderRadius),
          child: _buildShaderFill(),
        ),
      ),
    );
  }
}
