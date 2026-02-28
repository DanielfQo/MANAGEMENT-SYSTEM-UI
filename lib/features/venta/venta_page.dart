import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/venta/venta_provider.dart';
import 'package:management_system_ui/features/venta/models/venta_model.dart';

class VentaPage extends ConsumerStatefulWidget {
  const VentaPage({super.key});

  @override
  ConsumerState<VentaPage> createState() => _VentaPageState();
}

class _VentaPageState extends ConsumerState<VentaPage> {
  bool esCredito = false;

  final cantidadController = TextEditingController();
  final precioController = TextEditingController();

  int? productoSeleccionadoId;
  double? precioVentaBase;

  bool usarClienteExistente = true;

  int? clienteSeleccionadoId;

  final nombreClienteController = TextEditingController();
  final telefonoClienteController = TextEditingController();
  final emailClienteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(ventaProvider.notifier).initVenta(
            metodoPago: "EFECTIVO",
            esCredito: false,
          );
    });
  }

  @override
  void dispose() {
    cantidadController.dispose();
    precioController.dispose();
    nombreClienteController.dispose();
    telefonoClienteController.dispose();
    emailClienteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tiendaId = ref.watch(authProvider).selectedTiendaId!;
    final productosAsync = ref.watch(productosStockProvider(tiendaId));
    final venta = ref.watch(ventaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nueva Venta"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            /// SWITCH CRÉDITO
            SwitchListTile(
              title: const Text("Venta a Crédito"),
              value: esCredito,
              onChanged: (value) {
                setState(() {
                  esCredito = value;
                  clienteSeleccionadoId = null;
                  nombreClienteController.clear();
                  telefonoClienteController.clear();
                  emailClienteController.clear();
                });

                ref.read(ventaProvider.notifier).initVenta(
                  metodoPago: value ? "CREDITO" : "EFECTIVO",
                  esCredito: value,
                );
              },
            ),

            /// 👇 BLOQUE CLIENTES SOLO SI ES CRÉDITO
            if (esCredito) ...[
              const SizedBox(height: 20),
              const Divider(),
              const Text(
                "Cliente",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              ToggleButtons(
                isSelected: [
                  usarClienteExistente,
                  !usarClienteExistente,
                ],
                onPressed: (index) {
                  setState(() {
                    usarClienteExistente = index == 0;
                    clienteSeleccionadoId = null;
                    nombreClienteController.clear();
                    telefonoClienteController.clear();
                    emailClienteController.clear();
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

              if (usarClienteExistente)
                ref.watch(clientesProvider).when(
                  data: (clientes) {
                    return DropdownButtonFormField<int>(
                      value: clienteSeleccionadoId,
                      decoration: const InputDecoration(
                        labelText: "Seleccionar cliente",
                        border: OutlineInputBorder(),
                      ),
                      items: clientes
                          .map(
                            (c) => DropdownMenuItem<int>(
                              value: c.id,
                              child: Text("${c.nombre} | Deuda: S/. ${c.saldoTotal}"),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          clienteSeleccionadoId = value;
                        });

                        if (value != null) {
                          ref
                              .read(ventaProvider.notifier)
                              .setClienteExistente(value);
                        }
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text("Error cargando clientes"),
                )
              else ...[
                TextField(
                  controller: nombreClienteController,
                  decoration: const InputDecoration(
                    labelText: "Nombre",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: telefonoClienteController,
                  decoration: const InputDecoration(
                    labelText: "Teléfono",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailClienteController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              const Divider(),
            ],

            const Text(
              "Productos",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            /// DROPDOWN
            productosAsync.when(
              data: (productos) {

                final uniqueProductos = {
                  for (var p in productos) p.productoId: p
                }.values.toList();

                if (productoSeleccionadoId != null &&
                    !uniqueProductos
                        .any((p) => p.productoId == productoSeleccionadoId)) {
                  productoSeleccionadoId = null;
                }

                return DropdownButtonFormField<int>(
                  value: productoSeleccionadoId,
                  decoration: const InputDecoration(
                    labelText: "Producto",
                    border: OutlineInputBorder(),
                  ),
                  items: uniqueProductos
                      .map(
                        (p) => DropdownMenuItem<int>(
                          value: p.productoId,
                          child: Text(
                            "${p.productoNombre} | Stock: ${p.cantidadActual} | S/. ${p.precioVentaBase}",
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    final producto = uniqueProductos
                        .firstWhere((p) => p.productoId == value);

                    setState(() {
                      productoSeleccionadoId = producto.productoId;
                      precioVentaBase =
                          double.parse(producto.precioVentaBase);
                    });
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Text("Error cargando stock"),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: cantidadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Cantidad",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: precioController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Precio Venta (opcional)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                final cantidad = int.tryParse(cantidadController.text);
                final precio = precioController.text.isNotEmpty
                    ? double.tryParse(precioController.text)
                    : null;

                if (productoSeleccionadoId == null || cantidad == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Selecciona producto y cantidad")),
                  );
                  return;
                }

                if (precio != null &&
                    precioVentaBase != null &&
                    precio < precioVentaBase!) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            "El precio no puede ser menor al precio base")),
                  );
                  return;
                }

                ref.read(ventaProvider.notifier).addProducto(
                      VentaProducto(
                        productoId: productoSeleccionadoId!,
                        cantidad: cantidad,
                        precioVenta:
                            precio != null ? precio.toString() : null,
                      ),
                    );

                setState(() {
                  productoSeleccionadoId = null;
                  precioVentaBase = null;
                });

                cantidadController.clear();
                precioController.clear();
              },
              child: const Text("Agregar Producto"),
            ),

            const SizedBox(height: 20),

            /// PRODUCTOS AGREGADOS
            if (venta != null && venta.productos.isNotEmpty) ...[

              const Text(
                "Productos agregados",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              ...venta.productos.map((p) {

                final producto = productosAsync.asData?.value
                    .firstWhere((prod) => prod.productoId == p.productoId);

                final precioUnitario = p.precioVenta != null
                    ? double.parse(p.precioVenta!)
                    : double.parse(producto?.precioVentaBase ?? "0");

                final subtotal = precioUnitario * p.cantidad;

                return ListTile(
                  title: Text(producto?.productoNombre ?? "Producto"),
                  subtitle: Text(
                      "Cantidad: ${p.cantidad}  |  S/. ${precioUnitario.toStringAsFixed(2)}"),
                  trailing: Text(
                    "S/. ${subtotal.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }),

              const Divider(),

              /// TOTAL
              Builder(
                builder: (_) {

                  double total = 0;

                  for (var p in venta.productos) {
                    final producto = productosAsync.asData?.value
                        .firstWhere((prod) => prod.productoId == p.productoId);

                    final precioUnitario = p.precioVenta != null
                        ? double.parse(p.precioVenta!)
                        : double.parse(producto?.precioVentaBase ?? "0");

                    total += precioUnitario * p.cantidad;
                  }

                  return Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "TOTAL: S/. ${total.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
            ],

            ElevatedButton(
                onPressed: () async {
                    if (venta == null || venta.productos.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Agrega al menos un producto")),
                    );
                    return;
                    }

                    if (esCredito) {
                      if (usarClienteExistente && clienteSeleccionadoId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Seleccione un cliente")),
                        );
                        return;
                      }

                      if (!usarClienteExistente) {

                        if (nombreClienteController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Ingrese el nombre del cliente")),
                          );
                          return;
                        }

                        ref.read(ventaProvider.notifier).setClienteNuevo(
                          ClienteNuevo(
                            nombre: nombreClienteController.text,
                            telefono: telefonoClienteController.text,
                            email: emailClienteController.text,
                          ),
                        );
                      }
                    }

                    try {
                    await ref.read(ventaProvider.notifier).guardarVenta();

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Venta realizada")),
                    );

                    ref.read(ventaProvider.notifier).initVenta(
                        metodoPago: "EFECTIVO",
                        esCredito: false,
                    );

                    setState(() {
                        esCredito = false;
                        productoSeleccionadoId = null;
                        precioVentaBase = null;
                    });

                    cantidadController.clear();
                    precioController.clear();

                    } catch (_) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Error al realizar la venta")),
                    );
                    }
                },
                child: const Text("REALIZAR VENTA"),
                ),
          ],
        ),
      ),
    );
  }
}