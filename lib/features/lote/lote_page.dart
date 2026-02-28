import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/lote_model.dart';
import 'lote_provider.dart';
import 'package:go_router/go_router.dart';

class LotePage extends ConsumerStatefulWidget {
  const LotePage({super.key});

  @override
  ConsumerState<LotePage> createState() => _LotePageState();
}

class _LotePageState extends ConsumerState<LotePage> {

  final _fechaController = TextEditingController();
  final _costoOperacionController = TextEditingController();
  final _costoTransporteController = TextEditingController();

  final _cantidadController = TextEditingController();
  final _precioController = TextEditingController();
  final _nuevoProductoController = TextEditingController();

  int? _selectedProductoId;
  bool _usarProductoExistente = true;

  @override
  void dispose() {
    _fechaController.dispose();
    _costoOperacionController.dispose();
    _costoTransporteController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    _nuevoProductoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final lote = ref.watch(loteProvider);
    final loteNotifier = ref.read(loteProvider.notifier);
    final productosAsync = ref.watch(productosProvider);

    final productos = lote?.productos ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Lote"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// DATOS GENERALES

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

            const Text(
              "Productos",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            /// Dropdown Productos

            ToggleButtons(
              isSelected: [
                _usarProductoExistente,
                !_usarProductoExistente,
              ],
              onPressed: (index) {
                setState(() {
                  _usarProductoExistente = index == 0;
                  _selectedProductoId = null;
                  _nuevoProductoController.clear();
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Existente"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Nuevo"),
                ),
              ],
            ),

            const SizedBox(height: 15),

            /// Mostrar solo UNO según selección

            if (_usarProductoExistente)
              productosAsync.when(
                data: (productosCatalogo) {
                  return DropdownButtonFormField<int>(
                    value: _selectedProductoId,
                    decoration: const InputDecoration(
                      labelText: "Producto existente",
                      border: OutlineInputBorder(),
                    ),
                    items: productosCatalogo.map((producto) {
                      return DropdownMenuItem<int>(
                        value: producto.id,
                        child: Text(producto.nombre),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProductoId = value;
                      });
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => const Text("Error cargando productos"),
              )
            else
              TextField(
                controller: _nuevoProductoController,
                decoration: const InputDecoration(
                  labelText: "Nombre nuevo producto",
                  border: OutlineInputBorder(),
                ),
              ),

            const SizedBox(height: 10),

            TextField(
              controller: _cantidadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Cantidad",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _precioController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Precio",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.green, size: 35),
              onPressed: () {

                if (_cantidadController.text.isEmpty ||
                    _precioController.text.isEmpty) {
                  return;
                }

                if (_usarProductoExistente && _selectedProductoId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Seleccione un producto")),
                  );
                  return;
                }

                if (!_usarProductoExistente &&
                    _nuevoProductoController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Ingrese el nombre del producto")),
                  );
                  return;
                }

                if (lote == null) {
                  loteNotifier.initLote(
                    fechaLlegada: _fechaController.text,
                    costoOperacion: _costoOperacionController.text,
                    costoTransporte: _costoTransporteController.text,
                  );
                }

                if (_usarProductoExistente) {
                  final productoSeleccionado = productosAsync.value!
                      .firstWhere((p) => p.id == _selectedProductoId);

                  loteNotifier.addProducto(
                    LoteProducto(
                      productoId: _selectedProductoId,
                      nombre: productoSeleccionado.nombre,
                      cantidad: int.parse(_cantidadController.text),
                      precioCompra: _precioController.text,
                      precioVentaBase: _precioController.text,
                    ),
                  );
                } else {
                  loteNotifier.addProducto(
                    LoteProducto(
                      nombre: _nuevoProductoController.text,
                      cantidad: int.parse(_cantidadController.text),
                      precioCompra: _precioController.text,
                      precioVentaBase: _precioController.text,
                    ),
                  );
                }

                _selectedProductoId = null;
                _nuevoProductoController.clear();
                _cantidadController.clear();
                _precioController.clear();

                setState(() {});
              },
            ),

            const SizedBox(height: 20),

            Column(
              children: productos.map((producto) {
                return Card(
                  child: ListTile(
                    title: Text(producto.nombre ?? "Producto"),
                    subtitle: Text(
                      "Cant: ${producto.cantidad}  •  S/. ${producto.precioCompra}",
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
              onPressed: () async {
                await loteNotifier.guardarLote();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Lote guardado correctamente")),
                );
              },
              child: const Text("GUARDAR LOTE"),
            ),
          ],
        ),
      ),
    );
  }
}
