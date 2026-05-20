import 'package:flutter/material.dart';

import 'grid_card.dart';

class SizeCarousel extends StatefulWidget {
  final int selectedSize;
  final ValueChanged<int> onSizeChanged;

  const SizeCarousel({
    super.key,
    required this.selectedSize,
    required this.onSizeChanged,
  });

  static const supportedSizes = [8, 9, 10, 11, 12, 13, 14, 15, 16];

  @override
  State<SizeCarousel> createState() => _SizeCarouselState();
}

class _SizeCarouselState extends State<SizeCarousel> {
  late final PageController _controller;
  static const _viewportFraction = 0.32;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: SizeCarousel.supportedSizes.indexOf(widget.selectedSize),
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
      itemCount: SizeCarousel.supportedSizes.length,
      onPageChanged: (index) =>
          widget.onSizeChanged(SizeCarousel.supportedSizes[index]),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final size = SizeCarousel.supportedSizes[index];
        final isSelected = size == widget.selectedSize;
        return _CarouselItem(
          size: size,
          isSelected: isSelected,
          onTap: () => _animateToSize(size),
        );
      },
    );
  }

  void _animateToSize(int size) {
    _controller.animateToPage(
      SizeCarousel.supportedSizes.indexOf(size),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}

class _CarouselItem extends StatelessWidget {
  final int size;
  final bool isSelected;
  final VoidCallback onTap;

  const _CarouselItem({
    required this.size,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isSelected ? 1.0 : 0.78,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: isSelected ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 250),
        child: GestureDetector(
          onTap: onTap,
          child: GridCard(size: size, isSelected: isSelected),
        ),
      ),
    );
  }
}
