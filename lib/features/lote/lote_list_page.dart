import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lote_provider.dart';
import 'models/lote_response_model.dart';
import 'package:go_router/go_router.dart';

class LoteListPage extends ConsumerWidget {
  const LoteListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotesAsync = ref.watch(lotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock de Lotes"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/lotes'),
        ),
      ),
      body: lotesAsync.when(
        data: (lotes) {
          if (lotes.isEmpty) {
            return const Center(child: Text("No hay lotes registrados"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lotes.length,
            itemBuilder: (context, index) {
              final lote = lotes[index];

              return Card(
                child: ExpansionTile(
                  title: Text(
                      "Lote #${lote.id} - ${lote.fechaLlegada}"),
                  subtitle: Text(
                      "Tienda: ${lote.tienda.nombreSede}"),
                  children: lote.productos.map((producto) {
                    return ListTile(
                      title: Text(producto.productoNombre),
                      subtitle: Text(
                          "Stock: ${producto.cantidadActual}/${producto.cantidadInicial}"),
                      trailing: Text(
                          "S/. ${producto.precioVentaBase}"),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            const Center(child: Text("Error cargando lotes")),
      ),
    );
  }
}