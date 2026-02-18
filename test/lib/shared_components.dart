import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_palette/material_palette.dart';

/// Background color used throughout the app
const Color backgroundColor = Color(0xFF202329);

/// Standard border radius used for all shader cards
const double kShaderCardBorderRadius = 14.0;

/// Responsive card dimensions helper
class CardDimensions {
  final double width;
  final double height;
  final double controlsWidth;

  const CardDimensions({
    required this.width,
    required this.height,
    required this.controlsWidth,
  });

  static CardDimensions of(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final availableHeight = size.height - 200;
    final availableWidth = size.width;

    double height = (availableHeight * 0.75).clamp(200.0, 500.0);
    double width = (height * 0.6).clamp(150.0, 300.0);

    final maxWidthFromScreen = availableWidth * 0.7;
    if (width > maxWidthFromScreen) {
      width = maxWidthFromScreen;
      height = width / 0.6;
    }

    final controlsWidth = (availableWidth * 0.9).clamp(250.0, 400.0);

    return CardDimensions(
      width: width,
      height: height,
      controlsWidth: controlsWidth,
    );
  }
}

/// A wrapper that provides consistent sizing and rounded corners for all shader cards.
class ShaderCardContent extends StatelessWidget {
  const ShaderCardContent({
    super.key,
    required this.width,
    required this.height,
    required this.child,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kShaderCardBorderRadius),
        child: child,
      ),
    );
  }
}

/// A labeled slider control for numeric parameters.
class ControlSlider extends StatelessWidget {
  const ControlSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  ControlSlider.fromRange({
    super.key,
    required SliderRange range,
    required this.value,
    required this.onChanged,
  }) : label = range.label,
       min = range.min,
       max = range.max;

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 45,
            child: Text(
              value.toStringAsFixed(2),
              style: const TextStyle(fontSize: 10, color: Colors.white54),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// A labeled segmented button control for selecting from discrete options.
class ControlSegmentedButton<T> extends StatelessWidget {
  const ControlSegmentedButton({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ),
          Expanded(
            child: SegmentedButton<T>(
              segments: options.map((opt) => ButtonSegment<T>(
                value: opt.$1,
                label: Text(opt.$2, style: const TextStyle(fontSize: 10)),
              )).toList(),
              selected: {value},
              onSelectionChanged: (selected) {
                if (selected.isNotEmpty) {
                  onChanged(selected.first);
                }
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A section title for grouping related controls.
class ControlSectionTitle extends StatelessWidget {
  const ControlSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Generates a palette of colors from a seed color using Material's ColorScheme.
class ShaderColorPalette {
  final String name;
  final Color seedColor;
  late final ColorScheme _scheme;

  ShaderColorPalette(this.name, this.seedColor) {
    _scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
  }

  List<Color> get colors => [
    _scheme.primary,
    _scheme.primaryContainer,
    _scheme.secondary,
    _scheme.secondaryContainer,
    _scheme.tertiary,
    _scheme.tertiaryContainer,
    _scheme.surface,
    _scheme.surfaceContainerHighest,
    _scheme.onPrimary,
    _scheme.onSecondary,
    _scheme.onTertiary,
    _scheme.outline,
  ];

  static final marble = ShaderColorPalette('Marble', const Color(0xFF607D8B));
  static final gradient = ShaderColorPalette('Gradient', const Color(0xFFE91E63));
  static final radialGradient = ShaderColorPalette('Radial', const Color(0xFF009688));
  static final ripple = ShaderColorPalette('Ripple', const Color(0xFF2196F3));
  static final defaultPalette = ShaderColorPalette('Default', const Color(0xFF6750A4));
  static final perlin = ShaderColorPalette('Perlin', const Color(0xFF228B22));
  static final simplex = ShaderColorPalette('Simplex', const Color(0xFF9C27B0));
  static final fbm = ShaderColorPalette('FBM', const Color(0xFF8D6E63));
  static final turbulence = ShaderColorPalette('Turbulence', const Color(0xFF546E7A));
  static final voronoi = ShaderColorPalette('Voronoi', const Color(0xFF00BCD4));
  static final voronoise = ShaderColorPalette('Voronoise', const Color(0xFFFF8F00));
}

/// A labeled color picker row that shows a color swatch and opens an HSL picker dialog on tap.
class ControlColorPicker extends StatelessWidget {
  const ControlColorPicker({
    super.key,
    required this.label,
    required this.color,
    required this.onChanged,
    this.palette,
  });

  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;
  final ShaderColorPalette? palette;

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => HSLColorPickerDialog(
        initialColor: color,
        palette: palette ?? ShaderColorPalette.defaultPalette,
        onColorSelected: (selectedColor) {
          onChanged(selectedColor);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showColorPicker(context),
            child: Container(
              width: 32,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// HSL color picker dialog with optional preset swatches and HSL sliders.
class HSLColorPickerDialog extends StatefulWidget {
  const HSLColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.onColorSelected,
    this.title = 'Pick Color',
    this.palette,
  });

  final Color initialColor;
  final ValueChanged<Color> onColorSelected;
  final String title;
  final ShaderColorPalette? palette;

  @override
  State<HSLColorPickerDialog> createState() => _HSLColorPickerDialogState();
}

class _HSLColorPickerDialogState extends State<HSLColorPickerDialog> {
  late double _hue;
  late double _saturation;
  late double _lightness;
  late TextEditingController _hexController;
  bool _hexError = false;

  @override
  void initState() {
    super.initState();
    final hsl = HSLColor.fromColor(widget.initialColor);
    _hue = hsl.hue;
    _saturation = hsl.saturation;
    _lightness = hsl.lightness;
    _hexController = TextEditingController(text: _colorToHex(widget.initialColor));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Color get _currentColor => HSLColor.fromAHSL(1.0, _hue, _saturation, _lightness).toColor();

  String _colorToHex(Color color) {
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
  }

  Color? _hexToColor(String hex) {
    hex = hex.trim().toUpperCase();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length != 6) return null;
    try {
      final r = int.parse(hex.substring(0, 2), radix: 16);
      final g = int.parse(hex.substring(2, 4), radix: 16);
      final b = int.parse(hex.substring(4, 6), radix: 16);
      return Color.fromRGBO(r, g, b, 1);
    } catch (_) {
      return null;
    }
  }

  void _setColorFromRGB(Color color) {
    final hsl = HSLColor.fromColor(color);
    setState(() {
      _hue = hsl.hue;
      _saturation = hsl.saturation;
      _lightness = hsl.lightness;
      _hexController.text = _colorToHex(color);
      _hexError = false;
    });
  }

  void _onHexSubmitted(String value) {
    final color = _hexToColor(value);
    if (color != null) {
      _setColorFromRGB(color);
    } else {
      setState(() => _hexError = true);
    }
  }

  void _updateHexFromCurrentColor() {
    _hexController.text = _colorToHex(_currentColor);
    _hexError = false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, style: const TextStyle(fontSize: 16)),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 280,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: _currentColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _hexController,
                      style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        errorText: _hexError ? 'Invalid' : null,
                        errorStyle: const TextStyle(fontSize: 9),
                      ),
                      onSubmitted: _onHexSubmitted,
                      onEditingComplete: () => _onHexSubmitted(_hexController.text),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'Copy hex',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _colorToHex(_currentColor)));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied ${_colorToHex(_currentColor)}'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (widget.palette != null) ...[
                Text(
                  '${widget.palette!.name} Palette',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.palette!.colors.map((color) {
                    final isSelected = _colorsAreClose(color, _currentColor);
                    return GestureDetector(
                      onTap: () => _setColorFromRGB(color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.white24,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                widget.palette != null ? 'Custom Color (HSL)' : 'Color (HSL)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildHSLSlider(
                label: 'Hue',
                value: _hue,
                max: 360,
                gradient: LinearGradient(
                  colors: List.generate(7, (i) =>
                    HSLColor.fromAHSL(1.0, i * 60.0, 1.0, 0.5).toColor()
                  ),
                ),
                onChanged: (v) => setState(() { _hue = v; _updateHexFromCurrentColor(); }),
              ),
              _buildHSLSlider(
                label: 'Saturation',
                value: _saturation,
                max: 1,
                gradient: LinearGradient(
                  colors: [
                    HSLColor.fromAHSL(1.0, _hue, 0.0, _lightness).toColor(),
                    HSLColor.fromAHSL(1.0, _hue, 1.0, _lightness).toColor(),
                  ],
                ),
                onChanged: (v) => setState(() { _saturation = v; _updateHexFromCurrentColor(); }),
              ),
              _buildHSLSlider(
                label: 'Lightness',
                value: _lightness,
                max: 1,
                gradient: LinearGradient(
                  colors: [
                    HSLColor.fromAHSL(1.0, _hue, _saturation, 0.0).toColor(),
                    HSLColor.fromAHSL(1.0, _hue, _saturation, 0.5).toColor(),
                    HSLColor.fromAHSL(1.0, _hue, _saturation, 1.0).toColor(),
                  ],
                ),
                onChanged: (v) => setState(() { _lightness = v; _updateHexFromCurrentColor(); }),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onColorSelected(_currentColor);
            Navigator.pop(context);
          },
          child: const Text('Select'),
        ),
      ],
    );
  }

  Widget _buildHSLSlider({
    required String label,
    required double value,
    required double max,
    required LinearGradient gradient,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
              Text(
                max > 1 ? value.toStringAsFixed(0) : value.toStringAsFixed(2),
                style: const TextStyle(fontSize: 10, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white24),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 12,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                    elevation: 2,
                  ),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: value,
                  min: 0,
                  max: max,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _colorsAreClose(Color a, Color b) {
    const tolerance = 5.0 / 255.0;
    return (a.r - b.r).abs() < tolerance &&
           (a.g - b.g).abs() < tolerance &&
           (a.b - b.b).abs() < tolerance;
  }
}
