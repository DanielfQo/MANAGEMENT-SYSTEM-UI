import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/lote_model.dart';
import 'lote_provider.dart';

class LotePage extends ConsumerStatefulWidget {
  const LotePage({super.key});

  @override
  ConsumerState<LotePage> createState() => _LotePageState();
}

class _LotePageState extends ConsumerState<LotePage> {
  final _fechaController = TextEditingController();
  final _costoOperacionController = TextEditingController();
  final _costoTransporteController = TextEditingController();

  final _productoController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _precioController = TextEditingController();

  @override
  void dispose() {
    _fechaController.dispose();
    _costoOperacionController.dispose();
    _costoTransporteController.dispose();
    _productoController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lote = ref.watch(loteProvider);
    final loteNotifier = ref.read(loteProvider.notifier);

    final productos = lote?.productos ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Lote"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔹 DATOS GENERALES

            TextField(
              controller: _fechaController,
              decoration: const InputDecoration(
                labelText: "Fecha Llegada (YYYY-MM-DD)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _costoOperacionController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Costo Operación",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _costoTransporteController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Costo Transporte",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),

            /// 🔹 PRODUCTOS

            const Text(
              "Productos",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _productoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Producto (ID)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _cantidadController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Cant.",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _precioController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Precio",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                IconButton(
                  icon: const Icon(Icons.add_circle,
                      color: Colors.green, size: 35),
                  onPressed: () {
                    if (_productoController.text.isNotEmpty &&
                        _cantidadController.text.isNotEmpty &&
                        _precioController.text.isNotEmpty) {

                      loteNotifier.addProducto(
                        LoteProducto(
                          productoId: int.parse(_productoController.text),
                          cantidad: int.parse(_cantidadController.text),
                          precioCompra: _precioController.text,
                          precioVentaBase: _precioController.text,
                        ),
                      );

                      _productoController.clear();
                      _cantidadController.clear();
                      _precioController.clear();
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            Column(
              children: productos.map((producto) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(
                      producto.productoId != null
                          ? "Producto ID: ${producto.productoId}"
                          : "Producto Nuevo: ${producto.nombre}",
                    ),
                    subtitle: Text(
                      "Cantidad: ${producto.cantidad} | Compra: ${producto.precioCompra} | Venta: ${producto.precioVentaBase}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        loteNotifier.removeProducto(producto);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {},
              child: const Text(
                "GUARDAR LOTE",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}