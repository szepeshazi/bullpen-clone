import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  int _selectedSize = 8;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startGame() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          // Import lazily to avoid circular deps — we just push the route.
          return _GamePageLauncher(gridSize: _selectedSize);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final compact = screenHeight < 700;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: compact ? 24 : 48),
            // Title
            _buildTitle(compact),
            SizedBox(height: compact ? 20 : 40),
            // Size selector
            Expanded(
              child: _buildSizeSelector(),
            ),
            SizedBox(height: compact ? 12 : 24),
            // Start button
            _buildStartButton(),
            SizedBox(height: compact ? 24 : 48),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(bool compact) {
    return Column(
      children: [
        SvgPicture.asset(
          'assets/bull-head.svg',
          width: compact ? 56 : 80,
          height: compact ? 56 : 80,
          colorFilter: const ColorFilter.mode(
            bullpenAccentColor,
            BlendMode.srcIn,
          ),
        ),
        SizedBox(height: compact ? 8 : 16),
        const Text(
          'BULLPEN',
          style: TextStyle(
            color: bullpenAccentColor,
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Place the bulls. Break no rules.',
          style: TextStyle(
            color: bullpenAccentColor.withValues(alpha: 0.6),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSizeSelector() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'SELECT GRID SIZE',
          style: TextStyle(
            color: bullpenAccentColor.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 160,
          child: _SizeCarousel(
            selectedSize: _selectedSize,
            onSizeChanged: (size) => setState(() => _selectedSize = size),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '$_selectedSize × $_selectedSize',
          style: const TextStyle(
            color: bullpenAccentColor,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_selectedSize * 2} bulls to place',
          style: TextStyle(
            color: bullpenAccentColor.withValues(alpha: 0.5),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: SizedBox(
        width: 220,
        height: 56,
        child: ElevatedButton(
          onPressed: _startGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: bullpenAccentColor,
            foregroundColor: Colors.white,
            elevation: 6,
            shadowColor: bullpenAccentColor.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          child: const Text('START'),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Size carousel – horizontally scrollable grid-size cards
// ---------------------------------------------------------------------------

class _SizeCarousel extends StatefulWidget {
  final int selectedSize;
  final ValueChanged<int> onSizeChanged;

  const _SizeCarousel({
    required this.selectedSize,
    required this.onSizeChanged,
  });

  @override
  State<_SizeCarousel> createState() => _SizeCarouselState();
}

class _SizeCarouselState extends State<_SizeCarousel> {
  late final PageController _controller;
  static const _sizes = [8, 9, 10, 11, 12, 13, 14, 15, 16];
  static const _viewportFraction = 0.32;

  @override
  void initState() {
    super.initState();
    final initialPage = _sizes.indexOf(widget.selectedSize);
    _controller = PageController(
      initialPage: initialPage,
      viewportFraction: _viewportFraction,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      itemCount: _sizes.length,
      onPageChanged: (index) => widget.onSizeChanged(_sizes[index]),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final size = _sizes[index];
        final isSelected = size == widget.selectedSize;
        return AnimatedScale(
          scale: isSelected ? 1.0 : 0.78,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: isSelected ? 1.0 : 0.45,
            duration: const Duration(milliseconds: 250),
            child: GestureDetector(
              onTap: () {
                final page = _sizes.indexOf(size);
                _controller.animateToPage(
                  page,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: _GridCard(size: size, isSelected: isSelected),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Grid card – mini grid preview for a given size
// ---------------------------------------------------------------------------

class _GridCard extends StatelessWidget {
  final int size;
  final bool isSelected;

  const _GridCard({required this.size, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? bullpenAccentColor
              : bullpenAccentColor.withValues(alpha: 0.2),
          width: isSelected ? 2.5 : 1.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: bullpenAccentColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Center(
        child: _MiniGrid(size: size),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mini grid – tiny visual representation of an N×N grid
// ---------------------------------------------------------------------------

class _MiniGrid extends StatelessWidget {
  final int size;

  const _MiniGrid({required this.size});

  @override
  Widget build(BuildContext context) {
    // Use a fixed visual size and divide into cells
    const gridVisualSize = 80.0;
    final cellSize = gridVisualSize / size;

    return SizedBox(
      width: gridVisualSize,
      height: gridVisualSize,
      child: CustomPaint(
        painter: _MiniGridPainter(
          gridSize: size,
          cellSize: cellSize,
        ),
      ),
    );
  }
}

class _MiniGridPainter extends CustomPainter {
  final int gridSize;
  final double cellSize;

  const _MiniGridPainter({required this.gridSize, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = bullpenAccentColor.withValues(alpha: 0.25)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final borderPaint = Paint()
      ..color = bullpenAccentColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw cells
    for (int r = 0; r <= gridSize; r++) {
      final y = r * cellSize;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    for (int c = 0; c <= gridSize; c++) {
      final x = c * cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    // Outer border
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      borderPaint,
    );

    // Draw a couple of decorative "bull" dots
    final dotPaint = Paint()
      ..color = bullpenAccentColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    // Place bulls at deterministic positions based on grid size
    final bulls = _decorativeBullPositions(gridSize);
    for (final (r, c) in bulls) {
      final cx = (c + 0.5) * cellSize;
      final cy = (r + 0.5) * cellSize;
      canvas.drawCircle(Offset(cx, cy), cellSize * 0.3, dotPaint);
    }
  }

  List<(int, int)> _decorativeBullPositions(int n) {
    // A few non-adjacent positions for visual decoration
    if (n <= 9) return [(0, 2), (2, 0), (1, n - 1), (n - 1, 1)];
    if (n <= 12) return [(0, 3), (2, 0), (1, n - 2), (n - 1, 2), (n - 2, n - 1)];
    return [(0, 3), (2, 0), (1, n - 2), (n - 1, 2), (n - 2, n - 1), (n - 3, 4)];
  }

  @override
  bool shouldRepaint(_MiniGridPainter oldDelegate) =>
      oldDelegate.gridSize != gridSize;
}

// ---------------------------------------------------------------------------
// Game page launcher – bridges main page → game page with the selected size
// ---------------------------------------------------------------------------

class _GamePageLauncher extends StatelessWidget {
  final int gridSize;

  const _GamePageLauncher({required this.gridSize});

  @override
  Widget build(BuildContext context) {
    // Deferred import to avoid pulling game_cubit into main_page at top level.
    // We use a builder callback registered in main.dart instead.
    return _gamePageBuilder!(gridSize);
  }
}

/// Set by main.dart so main_page doesn't import game/cubit directly.
Widget Function(int gridSize)? _gamePageBuilder;

void registerGamePageBuilder(Widget Function(int gridSize) builder) {
  _gamePageBuilder = builder;
}
