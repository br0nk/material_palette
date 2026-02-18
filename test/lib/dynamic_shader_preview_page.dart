import 'package:flutter/material.dart';
import 'package:material_palette/material_palette.dart';

import 'shared_components.dart';

/// Sentinel value used in the dropdown to represent the marble smear shader,
/// which is not part of [ShaderMaterialType] because it requires interactive state.
const int _marbleSmearIndex = -1;

class DynamicShaderPreviewPage extends StatefulWidget {
  const DynamicShaderPreviewPage({super.key});

  @override
  State<DynamicShaderPreviewPage> createState() =>
      _DynamicShaderPreviewPageState();
}

class _DynamicShaderPreviewPageState extends State<DynamicShaderPreviewPage> {
  /// null means marble smear is selected.
  ShaderMaterialType? _selectedType = ShaderMaterialType.grittyGradient;
  double _width = 300;
  double _height = 400;
  ShaderAnimationMode _animationMode = ShaderAnimationMode.static;
  late ShaderParams _currentParams;
  late ShaderDefinition _definition;

  bool get _isMarbleSmear => _selectedType == null;

  @override
  void initState() {
    super.initState();
    _definition = ShaderMaterialRegistry.definition(_selectedType!);
    _currentParams = _definition.defaults;
  }

  void _onTypeChanged(int? index) {
    if (index == null) return;
    setState(() {
      if (index == _marbleSmearIndex) {
        _selectedType = null;
        _definition = marbleSmearShaderDef;
        _currentParams = _definition.defaults;
      } else {
        _selectedType = ShaderMaterialType.values[index];
        _definition = ShaderMaterialRegistry.definition(_selectedType!);
        _currentParams = _definition.defaults;
      }
    });
  }

  void _resetParams() {
    setState(() {
      _currentParams = _definition.defaults;
    });
  }

  /// Unique key that changes when the shader type changes, forcing
  /// ShaderBuilder to remount and load the correct shader program.
  Key get _shaderKey => ValueKey(_selectedType?.name ?? 'marble_smear');

  int get _dropdownValue =>
      _isMarbleSmear ? _marbleSmearIndex : _selectedType!.index;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Dynamic Shader Preview'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: shader preview
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Fill shader
                  _buildSectionLabel('ShaderFill'),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(kShaderCardBorderRadius),
                    child: _buildFillShader(),
                  ),
                  const SizedBox(height: 24),
                  // Wrap shader
                  _buildSectionLabel('RippleShaderWrap'),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(kShaderCardBorderRadius),
                    child: RippleShaderWrap(
                      child: SizedBox(
                        width: _width,
                        height: _height,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                'assets/images/earth.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Wrapped Content',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                            blurRadius: 8,
                                            color: Colors.black
                                                .withValues(alpha: 0.8)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_width.toInt()} x ${_height.toInt()}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                      shadows: [
                                        Shadow(
                                            blurRadius: 6,
                                            color: Colors.black
                                                .withValues(alpha: 0.8)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () {},
                                    child: const Text('Explore'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Right: controls panel
          const VerticalDivider(thickness: 1, width: 1),
          SizedBox(
            width: 340,
            child: _buildControlsPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildFillShader() {
    if (_isMarbleSmear) {
      return MarbleSmearShaderFill(
        key: _shaderKey,
        width: _width,
        height: _height,
        params: _currentParams,
        animationMode: _animationMode,
      );
    }
    return ShaderFill(
      key: _shaderKey,
      width: _width,
      height: _height,
      shaderPath: _selectedType!.shaderAssetPath,
      uniformsCallback: (shader, size, time) {
        setShaderUniforms(
            shader, size, time, _currentParams, _definition.layout);
      },
      animationMode: _animationMode,
    );
  }

  Widget _buildSectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildControlsPanel() {
    final ranges = _definition.uiDefaults.ranges;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shader type dropdown
          const ControlSectionTitle('Shader Type'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade700),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _dropdownValue,
                dropdownColor: Colors.grey.shade900,
                isExpanded: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: [
                  for (final type in ShaderMaterialType.values)
                    DropdownMenuItem(
                      value: type.index,
                      child: Text(type.displayName),
                    ),
                  const DropdownMenuItem(
                    value: _marbleSmearIndex,
                    child: Text('Marble Smear'),
                  ),
                ],
                onChanged: _onTypeChanged,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dimensions
          const ControlSectionTitle('Dimensions'),
          ControlSlider(
            label: 'Width',
            value: _width,
            min: 50,
            max: 800,
            onChanged: (v) => setState(() => _width = v),
          ),
          ControlSlider(
            label: 'Height',
            value: _height,
            min: 50,
            max: 800,
            onChanged: (v) => setState(() => _height = v),
          ),
          const SizedBox(height: 16),

          // Animation mode
          const ControlSectionTitle('Animation'),
          ControlSegmentedButton<ShaderAnimationMode>(
            label: 'Mode',
            value: _animationMode,
            options: const [
              (ShaderAnimationMode.static, 'Static'),
              (ShaderAnimationMode.running, 'Running'),
            ],
            onChanged: (v) => setState(() => _animationMode = v),
          ),
          const SizedBox(height: 16),

          // Shader param sliders
          if (ranges.isNotEmpty) ...[
            const ControlSectionTitle('Parameters'),
            for (final entry in ranges.entries)
              ControlSlider.fromRange(
                range: entry.value,
                value: _currentParams.get(entry.key),
                onChanged: (v) {
                  setState(() {
                    _currentParams = _currentParams.withValue(entry.key, v);
                  });
                },
              ),
            const SizedBox(height: 16),
          ],

          // Color pickers
          if (_currentParams.colors.isNotEmpty) ...[
            const ControlSectionTitle('Colors'),
            for (final entry in _currentParams.colors.entries)
              ControlColorPicker(
                label: entry.key,
                color: entry.value,
                onChanged: (c) {
                  setState(() {
                    _currentParams = _currentParams.withColor(entry.key, c);
                  });
                },
              ),
            const SizedBox(height: 16),
          ],

          // Reset button
          Center(
            child: TextButton.icon(
              onPressed: _resetParams,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset to Defaults'),
            ),
          ),
        ],
      ),
    );
  }
}
