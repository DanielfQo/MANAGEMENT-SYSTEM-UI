import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;

  const EmptyState({
    super.key,
    required this.icon,
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE9EEF6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 44, color: const Color(0xFF2F3A8F)),
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}