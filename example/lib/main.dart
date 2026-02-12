import 'package:flutter/material.dart';
import 'package:material_palette/material_palette.dart';

import 'shader_cards.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material Palette',
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF8C8CEF),
          onPrimary: Color(0xFF09090B),
          primaryContainer: Color(0xFF4C52D1),
          onPrimaryContainer: Color(0xFFF0F0F0),
          secondary: Color(0xFFD19A66),
          onSecondary: Color(0xFF09090B),
          secondaryContainer: Color(0xFF5A3E1F),
          onSecondaryContainer: Color(0xFFF0F0F0),
          tertiary: Color(0xFF81B88B),
          onTertiary: Color(0xFF09090B),
          tertiaryContainer: Color(0xFF2E5435),
          onTertiaryContainer: Color(0xFFF0F0F0),
          error: Color(0xFFE06C75),
          onError: Color(0xFF09090B),
          errorContainer: Color(0xFF5A222A),
          onErrorContainer: Color(0xFFF0F0F0),
          surface: Color(0xFF202329),
          onSurface: Color(0xFFF0F0F0),
          onSurfaceVariant: Color(0xFFABB2BF),
          outline: Color(0xFF373A44),
          outlineVariant: Color(0xFF2C2F38),
          shadow: Color(0xFF000000),
          scrim: Color(0xFF000000),
          inverseSurface: Color(0xFFF0F0F0),
          onInverseSurface: Color(0xFF202329),
          inversePrimary: Color(0xFF4C52D1),
          surfaceContainerHighest: Color(0xFF282C34),
        ),
      ),
      home: const ShaderCarouselPage(),
    );
  }
}

class ShaderCarouselPage extends StatefulWidget {
  const ShaderCarouselPage({super.key});

  @override
  State<ShaderCarouselPage> createState() => _ShaderCarouselPageState();
}

class _ShaderCarouselPageState extends State<ShaderCarouselPage> {
  PageController? _pageController;
  int _currentPage = 0;
  double _lastViewportFraction = 0;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }
  
  double _getViewportFraction(double screenWidth) {
    // On smaller screens, show more of the current card
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
    if (_currentPage < allShaders.length - 1) {
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
        title: const Text('Material Palette'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // Navigation bar with dropdown and arrows
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Previous button
                IconButton(
                  onPressed: _currentPage > 0 ? _previousPage : null,
                  icon: const Icon(Icons.chevron_left, size: 32),
                  color: Colors.white,
                  disabledColor: Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                // Shader picker dropdown
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
                        allShaders.length,
                        (index) => DropdownMenuItem(
                          value: index,
                          child: SizedBox(
                            width: 140,
                            child: Text(
                              allShaders[index].title,
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
                // Next button
                IconButton(
                  onPressed: _currentPage < allShaders.length - 1 ? _nextPage : null,
                  icon: const Icon(Icons.chevron_right, size: 32),
                  color: Colors.white,
                  disabledColor: Colors.grey.shade700,
                ),
              ],
            ),
          ),
          // Page counter
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_currentPage + 1} / ${allShaders.length}',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Carousel
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: allShaders.length,
              itemBuilder: (context, index) {
                return ShaderCard(data: allShaders[index]);
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
