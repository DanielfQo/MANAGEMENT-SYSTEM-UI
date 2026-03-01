import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:management_system_ui/core/common_libs.dart';

import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/venta/venta_repository.dart';

import 'package:management_system_ui/features/venta/models/venta_model.dart';
import 'package:management_system_ui/features/venta/models/cliente_model.dart';
import 'package:management_system_ui/features/venta/models/lote_stock_model.dart';


final ventaProvider =
    NotifierProvider<VentaNotifier, VentaModel?>(VentaNotifier.new);

final clientesProvider = FutureProvider<List<ClienteModel>>((ref) async {
  final repo = ref.watch(ventaRepositoryProvider);
  return repo.getClientes();
});

final productosStockProvider =
    FutureProvider.family<List<LoteStockModel>, int>((ref, tiendaId) async {
  final repo = ref.watch(ventaRepositoryProvider);
  return repo.getStock(tiendaId);
});

final ventasHistorialProvider =
    FutureProvider<List<VentaResponse>>((ref) async {
  final tiendaId = ref.watch(authProvider).selectedTiendaId;
  if (tiendaId == null) return [];

  final repo = ref.watch(ventaRepositoryProvider);
  return repo.getVentas(tiendaId: tiendaId);
});

class VentaNotifier extends Notifier<VentaModel?> {
  late final VentaRepository _repository;

  @override
  VentaModel? build() {
    _repository = ref.watch(ventaRepositoryProvider);
    return null;
  }

  void initVenta({
    required String metodoPago,
    required bool esCredito,
  }) {
    final tiendaId = ref.read(authProvider).selectedTiendaId;
    if (tiendaId == null) return;

    state = VentaModel(
      tiendaId: tiendaId,
      metodoPago: metodoPago,
      esCredito: esCredito,
      productos: [],
    );
  }

  void addProducto(VentaProducto producto) {
    if (state == null) return;

    state = state!.copyWith(
      productos: [...state!.productos, producto],
    );
  }

  void setClienteExistente(int clienteId) {
    if (state == null) return;

    state = state!.copyWith(
      clienteId: clienteId,
      cliente: null,
      resetCliente: true,
    );
  }

  void setClienteNuevo(ClienteNuevo cliente) {
    if (state == null) return;

    state = state!.copyWith(
      clienteId: null,
      cliente: cliente,
      resetCliente: true,
    );
  }

  Future<VentaResponse> guardarVenta() async {
    if (state == null) {
      throw Exception("No hay venta para guardar");
    }

    for (final producto in state!.productos) {
      if (producto.precioVenta != null) {
        final precio = double.parse(producto.precioVenta!);
      }
    }

    final ventaGuardada = await _repository.crearVenta(state!);
    state = null;

    return ventaGuardada;
  }
}
