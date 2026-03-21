import 'package:flutter/material.dart';

class DropdownSkeleton extends StatelessWidget {
  final String label;
  final double height;

  const DropdownSkeleton({
    super.key,
    required this.label,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      alignment: Alignment.centerLeft,
      child: Text(label, style: const TextStyle(color: Colors.grey)),
    );
  }
}