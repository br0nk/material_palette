import 'package:flutter/material.dart';
import 'package:material_palette/material_palette.dart';

import 'shared_components.dart';

// ============ CHECKERBOARD PAINTER ============

class CheckerboardPainter extends CustomPainter {
  static const double _cellSize = 16.0;
  static const Color _colorA = Color(0xFF3A3D45);
  static const Color _colorB = Color(0xFF2A2D35);

  @override
  void paint(Canvas canvas, Size size) {
    final paintA = Paint()..color = _colorA;
    final paintB = Paint()..color = _colorB;

    final cols = (size.width / _cellSize).ceil();
    final rows = (size.height / _cellSize).ceil();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final paint = (row + col).isEven ? paintA : paintB;
        canvas.drawRect(
          Rect.fromLTWH(col * _cellSize, row * _cellSize, _cellSize, _cellSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============ DEMO CONTENT HELPERS ============

Widget _buildDemoContentColumn(CardDimensions dimensions) {
  return SizedBox(
    width: dimensions.width,
    height: dimensions.height,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Shader Wrap',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Transparent background demo',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {},
          child: const Text('Button'),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/earth.jpg',
            width: dimensions.width * 0.5,
            height: dimensions.width * 0.5,
            fit: BoxFit.cover,
          ),
        ),
      ],
    ),
  );
}

Widget _buildDemoContentStack(CardDimensions dimensions) {
  return SizedBox(
    width: dimensions.width,
    height: dimensions.height,
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
                'Earth',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(blurRadius: 8, color: Colors.black.withValues(alpha: 0.8)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Our home planet',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  shadows: [
                    Shadow(blurRadius: 6, color: Colors.black.withValues(alpha: 0.8)),
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
  );
}

// ============ WRAP DEMO CARD ============

class _WrapDemoCard extends StatelessWidget {
  final CardDimensions dimensions;
  final String title;
  final String description;
  final Widget child;

  const _WrapDemoCard({
    required this.dimensions,
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderCardContent(
                width: dimensions.width,
                height: dimensions.height,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: CheckerboardPainter(),
                      ),
                    ),
                    child,
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ DEMO ITEMS ============

class _WrapDemoItem {
  final String title;
  final String description;
  final Widget Function(CardDimensions dimensions) builder;

  const _WrapDemoItem({
    required this.title,
    required this.description,
    required this.builder,
  });
}

final List<_WrapDemoItem> _wrapDemoItems = [
  _WrapDemoItem(
    title: 'Ripple + Column',
    description: 'RippleShaderWrap around a Column layout',
    builder: (dimensions) => RippleShaderWrap(
      child: _buildDemoContentColumn(dimensions),
    ),
  ),
  _WrapDemoItem(
    title: 'Ripple + Stack',
    description: 'RippleShaderWrap around a Stack layout',
    builder: (dimensions) => RippleShaderWrap(
      child: _buildDemoContentStack(dimensions),
    ),
  ),
  _WrapDemoItem(
    title: 'Tap Ripple + Column',
    description: 'ClickableRippleShaderWrap around a Column layout',
    builder: (dimensions) => ClickableRippleShaderWrap(
      child: _buildDemoContentColumn(dimensions),
    ),
  ),
  _WrapDemoItem(
    title: 'Tap Ripple + Stack',
    description: 'ClickableRippleShaderWrap around a Stack layout',
    builder: (dimensions) => ClickableRippleShaderWrap(
      child: _buildDemoContentStack(dimensions),
    ),
  ),
];

// ============ SHADER WRAP DEMO PAGE ============

class ShaderWrapDemoPage extends StatefulWidget {
  const ShaderWrapDemoPage({super.key});

  @override
  State<ShaderWrapDemoPage> createState() => _ShaderWrapDemoPageState();
}

class _ShaderWrapDemoPageState extends State<ShaderWrapDemoPage> {
  PageController? _pageController;
  int _currentPage = 0;
  double _lastViewportFraction = 0;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  double _getViewportFraction(double screenWidth) {
    if (screenWidth < 400) return 0.85;
    if (screenWidth < 600) return 0.75;
    if (screenWidth < 900) return 0.65;
    return 0.55;
  }

  void _updatePageController(double viewportFraction) {
    if (_lastViewportFraction != viewportFraction) {
      _lastViewportFraction = viewportFraction;
      _pageController?.dispose();
      _pageController = PageController(
        viewportFraction: viewportFraction,
        initialPage: _currentPage,
      );
    }
  }

  void _goToPage(int page) {
    _pageController?.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController?.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _wrapDemoItems.length - 1) {
      _pageController?.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final viewportFraction = _getViewportFraction(screenWidth);
    _updatePageController(viewportFraction);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Shader Wrap Demo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _currentPage > 0 ? _previousPage : null,
                  icon: const Icon(Icons.chevron_left, size: 32),
                  color: Colors.white,
                  disabledColor: Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade700),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _currentPage,
                      dropdownColor: Colors.grey.shade900,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      items: List.generate(
                        _wrapDemoItems.length,
                        (index) => DropdownMenuItem(
                          value: index,
                          child: SizedBox(
                            width: 140,
                            child: Text(
                              _wrapDemoItems[index].title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value != null) _goToPage(value);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _currentPage < _wrapDemoItems.length - 1 ? _nextPage : null,
                  icon: const Icon(Icons.chevron_right, size: 32),
                  color: Colors.white,
                  disabledColor: Colors.grey.shade700,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_currentPage + 1} / ${_wrapDemoItems.length}',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _wrapDemoItems.length,
              itemBuilder: (context, index) {
                final item = _wrapDemoItems[index];
                final dimensions = CardDimensions.of(context);
                return _WrapDemoCard(
                  dimensions: dimensions,
                  title: item.title,
                  description: item.description,
                  child: item.builder(dimensions),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
