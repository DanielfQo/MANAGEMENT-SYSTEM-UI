import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/venta/models/cliente_model.dart';
import 'package:management_system_ui/features/venta/models/venta_create_model.dart';
import 'package:management_system_ui/features/venta/models/venta_read_model.dart';
import 'package:management_system_ui/features/venta/venta_repository.dart';
import 'package:management_system_ui/features/venta/constants/tipo_venta.dart';
import 'package:management_system_ui/features/venta/constants/metodo_pago.dart';
import 'package:management_system_ui/features/venta/constants/tipo_comprobante.dart';

// ============================================================================
// CARRITO PROVIDERS & NOTIFIER
// ============================================================================

class CarritoItem {
  final int? productoId;
  final int? loteProductoId;
  final String productoNombre;
  final String unidadMedida;
  double cantidad;
  double precioVenta;
  final bool esAveriado;
  final String? productoImagen;

  CarritoItem({
    this.productoId,
    this.loteProductoId,
    required this.productoNombre,
    required this.unidadMedida,
    required this.cantidad,
    required this.precioVenta,
    this.esAveriado = false,
    this.productoImagen,
  });

  double get subtotal => cantidad * precioVenta;

  CarritoItem copyWith({
    int? productoId,
    int? loteProductoId,
    String? productoNombre,
    String? unidadMedida,
    double? cantidad,
    double? precioVenta,
    bool? esAveriado,
    String? productoImagen,
  }) {
    return CarritoItem(
      productoId: productoId ?? this.productoId,
      loteProductoId: loteProductoId ?? this.loteProductoId,
      productoNombre: productoNombre ?? this.productoNombre,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      cantidad: cantidad ?? this.cantidad,
      precioVenta: precioVenta ?? this.precioVenta,
      esAveriado: esAveriado ?? this.esAveriado,
      productoImagen: productoImagen ?? this.productoImagen,
    );
  }
}

class CarritoState {
  final List<CarritoItem> items;

  const CarritoState({required this.items});

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);

  CarritoState copyWith({List<CarritoItem>? items}) {
    return CarritoState(items: items ?? this.items);
  }
}

final carritoProvider =
    NotifierProvider<CarritoNotifier, CarritoState>(CarritoNotifier.new);

class CarritoNotifier extends Notifier<CarritoState> {
  @override
  CarritoState build() {
    return const CarritoState(items: []);
  }

  void agregarItem(CarritoItem item) {
    state = state.copyWith(items: [...state.items, item]);
  }

  void eliminarItem(int index) {
    if (index >= 0 && index < state.items.length) {
      final newItems = [...state.items];
      newItems.removeAt(index);
      state = state.copyWith(items: newItems);
    }
  }

  void actualizarCantidad(int index, double cantidad) {
    if (index >= 0 && index < state.items.length && cantidad > 0) {
      final newItems = [...state.items];
      newItems[index] = newItems[index].copyWith(cantidad: cantidad);
      state = state.copyWith(items: newItems);
    }
  }

  void actualizarPrecio(int index, double precio) {
    if (index >= 0 && index < state.items.length) {
      final newItems = [...state.items];
      newItems[index] = newItems[index].copyWith(precioVenta: precio);
      state = state.copyWith(items: newItems);
    }
  }

  void actualizarAveriado(int index, bool esAveriado) {
    if (index >= 0 && index < state.items.length) {
      final newItems = [...state.items];
      newItems[index] = newItems[index].copyWith(esAveriado: esAveriado);
      state = state.copyWith(items: newItems);
    }
  }

  void actualizarLoteProductoId(int index, int? loteProductoId) {
    if (index >= 0 && index < state.items.length) {
      final newItems = [...state.items];
      newItems[index] = newItems[index].copyWith(loteProductoId: loteProductoId);
      state = state.copyWith(items: newItems);
    }
  }

  void limpiar() {
    state = const CarritoState(items: []);
  }
}

// ============================================================================
// VENTA PROVIDERS & NOTIFIER
// ============================================================================

class VentaState {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final List<VentaReadModel> ventas;
  final VentaReadModel? ventaCreada;
  final List<ClienteModel> clientes;

  const VentaState({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.ventas = const [],
    this.ventaCreada,
    this.clientes = const [],
  });

  VentaState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    List<VentaReadModel>? ventas,
    VentaReadModel? ventaCreada,
    List<ClienteModel>? clientes,
  }) {
    return VentaState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
      ventas: ventas ?? this.ventas,
      ventaCreada: ventaCreada ?? this.ventaCreada,
      clientes: clientes ?? this.clientes,
    );
  }
}

final ventaProvider =
    NotifierProvider<VentaNotifier, VentaState>(VentaNotifier.new);

class VentaNotifier extends Notifier<VentaState> {
  late final VentaRepository _repository;

  @override
  VentaState build() {
    _repository = ref.watch(ventaRepositoryProvider);
    return const VentaState();
  }

  Future<void> cargarVentas({
    String? tipo,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    final tiendaId = ref.read(authProvider).selectedTiendaId;
    if (tiendaId == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final ventas = await _repository.getVentas(
        tiendaId: tiendaId,
        tipo: tipo,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      );
      state = state.copyWith(isLoading: false, ventas: ventas);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> cargarClientes() async {
    final tiendaId = ref.read(authProvider).selectedTiendaId;
    if (tiendaId == null) return;

    try {
      final clientes = await _repository.getClientes(tiendaId);
      state = state.copyWith(clientes: clientes);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> crearVenta(VentaCreateModel venta) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final ventaCreada = await _repository.crearVenta(venta);
      state = state.copyWith(
        isSaving: false,
        ventaCreada: ventaCreada,
        successMessage: ventaCreada.propuestaSunat != null
            ? 'Venta creada. Confirma la propuesta SUNAT'
            : 'Venta creada exitosamente',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> confirmarSunat(
    int ventaId,
    List<ConfirmarSunatItem> items,
  ) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final ventaActualizada = await _repository.confirmarSunat(
        ventaId,
        items,
      );
      state = state.copyWith(
        isSaving: false,
        ventaCreada: ventaActualizada,
        successMessage: 'Propuesta SUNAT confirmada exitosamente',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> cancelarVenta(int ventaId) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repository.cancelarVenta(ventaId);
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Venta cancelada exitosamente',
      );
      // Recargar historial
      await cargarVentas();
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString(),
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

// ============================================================================
// CLIENTES CON RUC PROVIDER (para SUNAT Factura)
// ============================================================================

/// FutureProvider que carga clientes con RUC (tipo_documento = "6")
/// Útil para SUNAT Factura donde se requiere cliente con RUC
final clientesConRucProvider = FutureProvider<List<ClienteModel>>((ref) async {
  final authState = ref.watch(authProvider);
  final tiendaId = authState.selectedTiendaId;

  if (tiendaId == null) {
    return [];
  }

  final repository = ref.watch(ventaRepositoryProvider);
  return repository.getClientesConRuc(tiendaId);
});

// ============================================================================
// RESUMEN VENTA PROVIDER (persistencia de formulario)
// ============================================================================

/// Estado persistente del formulario de resumen de venta
/// Se mantiene mientras el usuario navega entre pasos
class ResumenVentaState {
  final String tipoVenta;
  final String metodoPago;
  final String tipoComprobante;
  final String tipoDocumento;
  final bool usarClienteExistente;
  final int? clienteId;
  final ClienteModel? cliente;
  // Valores de TextFields (strings planos)
  final String nombre;
  final String numeroDocumento;
  final String telefono;
  final String email;
  final String direccion;
  final String telefonoExistente;
  final String emailExistente;
  final String direccionExistente;

  const ResumenVentaState({
    this.tipoVenta = TipoVenta.normal,
    this.metodoPago = MetodoPago.efectivo,
    this.tipoComprobante = TipoComprobante.boleta,
    this.tipoDocumento = '1',
    this.usarClienteExistente = true,
    this.clienteId,
    this.cliente,
    this.nombre = '',
    this.numeroDocumento = '',
    this.telefono = '',
    this.email = '',
    this.direccion = '',
    this.telefonoExistente = '',
    this.emailExistente = '',
    this.direccionExistente = '',
  });

  ResumenVentaState copyWith({
    String? tipoVenta,
    String? metodoPago,
    String? tipoComprobante,
    String? tipoDocumento,
    bool? usarClienteExistente,
    int? clienteId,
    ClienteModel? cliente,
    String? nombre,
    String? numeroDocumento,
    String? telefono,
    String? email,
    String? direccion,
    String? telefonoExistente,
    String? emailExistente,
    String? direccionExistente,
  }) {
    return ResumenVentaState(
      tipoVenta: tipoVenta ?? this.tipoVenta,
      metodoPago: metodoPago ?? this.metodoPago,
      tipoComprobante: tipoComprobante ?? this.tipoComprobante,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      usarClienteExistente: usarClienteExistente ?? this.usarClienteExistente,
      clienteId: clienteId ?? this.clienteId,
      cliente: cliente ?? this.cliente,
      nombre: nombre ?? this.nombre,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      telefonoExistente: telefonoExistente ?? this.telefonoExistente,
      emailExistente: emailExistente ?? this.emailExistente,
      direccionExistente: direccionExistente ?? this.direccionExistente,
    );
  }
}

class ResumenVentaNotifier extends Notifier<ResumenVentaState> {
  @override
  ResumenVentaState build() => const ResumenVentaState();

  void actualizar(ResumenVentaState nuevoEstado) {
    state = nuevoEstado;
  }

  void limpiar() {
    state = const ResumenVentaState();
  }
}

final resumenVentaProvider =
    NotifierProvider<ResumenVentaNotifier, ResumenVentaState>(
  ResumenVentaNotifier.new,
);
