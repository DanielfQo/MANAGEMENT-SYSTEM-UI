import 'package:flutter/material.dart';

class ErrorState extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;

  const ErrorState({
    super.key,
    required this.mensaje,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 44, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            mensaje,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F3A8F),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: onRetry,
            child: const Text('Reintentar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}