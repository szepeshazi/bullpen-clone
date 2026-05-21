import 'package:bullpen/logic/puzzle_config.dart';
import 'package:bullpen/widgets/main/grid_card.dart';
import 'package:flutter/material.dart';

class SizeCarousel extends StatefulWidget {
  final int selectedSize;
  final ValueChanged<int> onSizeChanged;

  const SizeCarousel({
    required this.selectedSize, required this.onSizeChanged, super.key,
  });

  @override
  State<SizeCarousel> createState() => _SizeCarouselState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('selectedSize', selectedSize));
    properties.add(ObjectFlagProperty<ValueChanged<int>>.has('onSizeChanged', onSizeChanged));
  }
}

class _SizeCarouselState extends State<SizeCarousel> {
  late final PageController _controller;
  static const _viewportFraction = 0.32;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: puzzleSupportedSizes.indexOf(widget.selectedSize),
      viewportFraction: _viewportFraction,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageView.builder(
      controller: _controller,
      itemCount: puzzleSupportedSizes.length,
      onPageChanged: (index) =>
          widget.onSizeChanged(puzzleSupportedSizes[index]),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final size = puzzleSupportedSizes[index];
        final isSelected = size == widget.selectedSize;
        return _CarouselItem(
          size: size,
          isSelected: isSelected,
          onTap: () => _animateToSize(size),
        );
      },
    );

  void _animateToSize(int size) {
    _controller.animateToPage(
      puzzleSupportedSizes.indexOf(size),
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
  Widget build(BuildContext context) => AnimatedScale(
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('size', size));
    properties.add(DiagnosticsProperty<bool>('isSelected', isSelected));
    properties.add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap));
  }
}
