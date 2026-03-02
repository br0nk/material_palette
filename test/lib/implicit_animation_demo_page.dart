import 'package:flutter/material.dart';
import 'package:material_palette/material_palette.dart';

import 'shared_components.dart';

// ── Preset definitions ──────────────────────────────────────────────────────

class _Preset {
  final String name;
  final ShaderParams params;
  final Color? backgroundColor;

  const _Preset(this.name, this.params, this.backgroundColor);
}

final _presets = <_Preset>[
  _Preset(
    'Sunset',
    ShaderParams(
      values: {
        'gradientAngle': 45.0,
        'gradientScale': 1.0,
        'gradientOffset': 0.0,
        'noiseDensity': 160.0,
        'noiseIntensity': 0.65,
        'stippleStrength': 1.0,
        'ditherStrength': 0.44,
        'ditherScale': 0.50,
        'animSpeed': 0.0,
        'colorCount': 3.0,
        'softness': 1.0,
        'exposure': 1.0,
        'contrast': 1.0,
      },
      colors: {
        ...ParamGroups.gradientColorDefaults([
          const Color(0xFFFF6B35),
          const Color(0xFF9B2335),
          const Color(0xFF1A0533),
        ]),
      },
    ),
    const Color(0xFF1A0533),
  ),
  _Preset(
    'Ocean',
    ShaderParams(
      values: {
        'gradientAngle': 180.0,
        'gradientScale': 1.2,
        'gradientOffset': 0.1,
        'noiseDensity': 200.0,
        'noiseIntensity': 0.4,
        'stippleStrength': 0.8,
        'ditherStrength': 0.2,
        'ditherScale': 0.50,
        'animSpeed': 0.0,
        'colorCount': 3.0,
        'softness': 0.8,
        'exposure': 1.1,
        'contrast': 1.0,
      },
      colors: {
        ...ParamGroups.gradientColorDefaults([
          const Color(0xFF0D1B2A),
          const Color(0xFF1B4965),
          const Color(0xFF5FA8D3),
        ]),
      },
    ),
    const Color(0xFF0D1B2A),
  ),
  _Preset(
    'Aurora',
    ShaderParams(
      values: {
        'gradientAngle': 90.0,
        'gradientScale': 0.8,
        'gradientOffset': -0.2,
        'noiseDensity': 300.0,
        'noiseIntensity': 0.8,
        'stippleStrength': 1.0,
        'ditherStrength': 0.1,
        'ditherScale': 0.30,
        'animSpeed': 0.0,
        'colorCount': 4.0,
        'softness': 1.0,
        'exposure': 1.2,
        'contrast': 1.1,
      },
      colors: {
        ...ParamGroups.gradientColorDefaults([
          const Color(0xFF0B0C10),
          const Color(0xFF1F6650),
          const Color(0xFF45B69C),
          const Color(0xFFE0BBE4),
        ]),
      },
    ),
    const Color(0xFF0B0C10),
  ),
  _Preset(
    'Blush',
    ShaderParams(
      values: {
        'gradientAngle': 135.0,
        'gradientScale': 1.5,
        'gradientOffset': 0.0,
        'noiseDensity': 120.0,
        'noiseIntensity': 0.55,
        'stippleStrength': 1.0,
        'ditherStrength': 0.3,
        'ditherScale': 0.50,
        'animSpeed': 0.0,
        'colorCount': 2.0,
        'softness': 1.0,
        'exposure': 1.0,
        'contrast': 1.0,
      },
      colors: {
        ...ParamGroups.gradientColorDefaults([
          const Color(0xFFEBC8D8),
          const Color(0xFF738CBF),
        ]),
      },
    ),
    const Color(0xFF2A1B2E),
  ),
];

// ── Page ─────────────────────────────────────────────────────────────────────

class ImplicitAnimationDemoPage extends StatefulWidget {
  const ImplicitAnimationDemoPage({super.key});

  @override
  State<ImplicitAnimationDemoPage> createState() =>
      _ImplicitAnimationDemoPageState();
}

class _ImplicitAnimationDemoPageState extends State<ImplicitAnimationDemoPage> {
  int _presetIndex = 0;
  int _curveIndex = 2; // easeInOut
  double _durationSec = 1.5;

  static const _curves = <(String, Curve)>[
    ('linear', Curves.linear),
    ('easeIn', Curves.easeIn),
    ('easeInOut', Curves.easeInOut),
    ('easeOut', Curves.easeOut),
    ('bounceOut', Curves.bounceOut),
    ('elasticOut', Curves.elasticOut),
  ];

  final _definition = grittyGradientDef;

  _Preset get _preset => _presets[_presetIndex];

  @override
  Widget build(BuildContext context) {
    final dimensions = CardDimensions.of(context);
    final duration = Duration(milliseconds: (_durationSec * 1000).round());

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Implicit Animation Demo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Row(
        children: [
          // Preview
          Expanded(
            child: Center(
              child: AnimatedShaderParams(
                params: _preset.params,
                backgroundColor: _preset.backgroundColor,
                duration: duration,
                curve: _curves[_curveIndex].$2,
                builder: (params, bgColor) {
                  return ShaderCardContent(
                    width: dimensions.width,
                    height: dimensions.height,
                    child: Stack(
                      children: [
                        if (bgColor != null)
                          Positioned.fill(
                            child: ColoredBox(color: bgColor),
                          ),
                        Positioned.fill(
                          child: ShaderFill(
                            width: dimensions.width,
                            height: dimensions.height,
                            shaderPath:
                                ShaderMaterialType.grittyGradient.shaderAssetPath,
                            uniformsCallback: (shader, size, time) {
                              setShaderUniforms(
                                shader,
                                size,
                                time,
                                params,
                                _definition.layout,
                              );
                            },
                            animationMode: ShaderAnimationMode.implicit,
                            cache: false,
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Text(
                            _preset.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 8,
                                  color: Colors.black.withValues(alpha: 0.8),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Controls panel
          Container(
            width: dimensions.controlsWidth,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D23),
              border: Border(
                left: BorderSide(color: Colors.grey.shade800, width: 1),
              ),
            ),
            child: ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ControlSectionTitle('Preset'),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(_presets.length, (i) {
                        final selected = i == _presetIndex;
                        return ChoiceChip(
                          label: Text(
                            _presets[i].name,
                            style: const TextStyle(fontSize: 11),
                          ),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _presetIndex = i),
                          visualDensity: VisualDensity.compact,
                        );
                      }),
                    ),

                    const SizedBox(height: 20),
                    const ControlSectionTitle('Curve'),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(_curves.length, (i) {
                        final selected = i == _curveIndex;
                        return ChoiceChip(
                          label: Text(
                            _curves[i].$1,
                            style: const TextStyle(fontSize: 11),
                          ),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _curveIndex = i),
                          visualDensity: VisualDensity.compact,
                        );
                      }),
                    ),

                    const SizedBox(height: 20),
                    const ControlSectionTitle('Duration'),
                    ControlSlider(
                      label: 'Duration (s)',
                      value: _durationSec,
                      min: 0.2,
                      max: 5.0,
                      onChanged: (v) =>
                          setState(() => _durationSec = v),
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap a preset to smoothly animate all shader '
                      'parameters and the background color at once, '
                      'using AnimatedShaderParams.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white38,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
