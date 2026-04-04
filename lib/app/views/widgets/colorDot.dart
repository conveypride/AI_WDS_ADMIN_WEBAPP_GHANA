import 'package:flutter/material.dart';

class ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const ColorDot({super.key, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24, height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: selected ? Colors.white : Colors.transparent, width: 2),
          boxShadow: selected ? [const BoxShadow(color: Colors.black45, blurRadius: 2)] : [],
        ),
      ),
    );
  }
}