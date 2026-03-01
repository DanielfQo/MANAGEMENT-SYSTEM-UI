import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'venta_provider.dart';
import 'package:intl/intl.dart';
import 'models/venta_model.dart';

class VentaHistorialPage extends ConsumerWidget {
  const VentaHistorialPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ventasAsync = ref.watch(ventasHistorialProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Ventas"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/ventas'),
        ),
      ),
      body: ventasAsync.when(
        data: (ventas) {
          if (ventas.isEmpty) {
            return const Center(child: Text("No hay ventas registradas"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ventas.length,
            itemBuilder: (context, index) {
              final venta = ventas[index];
              final fecha = DateTime.parse(venta.fecha);
              final fechaFormateada = 
                  DateFormat('dd/MM/yyyy - hh:mm a').format(fecha);

              return Card(
                child: ListTile(
                onTap: () {
                    showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => _VentaDetalleModal(venta: venta),
                    );
                },
                title: Text("Venta #${venta.id} - S/. ${venta.total}"),
                subtitle: Text(
                    "Fecha: $fechaFormateada\nAtendido por: ${venta.usuarioNombre}",
                ),
                trailing: venta.esCredito
                    ? const Icon(Icons.credit_card)
                    : const Icon(Icons.attach_money),
                ),
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text("Error cargando ventas")),
      ),
    );
  }
}

class _VentaDetalleModal extends StatelessWidget {
  final VentaResponse venta;

  const _VentaDetalleModal({required this.venta});

  @override
  Widget build(BuildContext context) {
    final fecha = DateTime.parse(venta.fecha);
    final fechaFormateada =
        DateFormat('dd/MM/yyyy - hh:mm a').format(fecha);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Detalle de Venta #${venta.id}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Text("Total: S/. ${venta.total.toStringAsFixed(2)}"),
            Text("Fecha: $fechaFormateada"),
            Text("Atendido por: ${venta.usuarioNombre}"),
            Text("Tipo: ${venta.esCredito ? "Crédito" : "Contado"}"),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            const Text(
              "Productos",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if (venta.detalle.isEmpty)
              const Text("Esta venta no tiene productos registrados"),

            ...venta.detalle.map((detalle) {
              final precio = double.parse(detalle.precioVenta);
              final subtotal = precio * detalle.cantidad;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(detalle.producto),
                subtitle: Text("Cantidad: ${detalle.cantidad}"),
                trailing: Text(
                  "S/. ${subtotal.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}