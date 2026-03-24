import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'models/lote_model.dart';
import 'models/lote_response_model.dart';
import 'models/producto_model.dart';
import 'models/stock_model.dart';
import 'lote_repository.dart';

// Main notifier for inventory state
final inventarioProvider =
    NotifierProvider<InventarioNotifier, InventarioState>(
  InventarioNotifier.new,
);

// Family providers for detail views
final loteDetalleProvider =
    FutureProvider.family<LoteResponse, int>((ref, id) async {
  final repository = ref.watch(loteRepositoryProvider);
  return repository.getLoteDetalle(id);
});

final productoDetalleProvider =
    FutureProvider.family<ProductoModel, int>((ref, id) async {
  final repository = ref.watch(loteRepositoryProvider);
  return repository.getProductoDetalle(id);
});

// State class
class InventarioState {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final List<LoteResponse> lotes;
  final List<StockModel> stock;
  final List<ProductoModel> productos;

  InventarioState({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.lotes = const [],
    this.stock = const [],
    this.productos = const [],
  });

  InventarioState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    List<LoteResponse>? lotes,
    List<StockModel>? stock,
    List<ProductoModel>? productos,
  }) {
    return InventarioState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
      lotes: lotes ?? this.lotes,
      stock: stock ?? this.stock,
      productos: productos ?? this.productos,
    );
  }
}

// Notifier class
class InventarioNotifier extends Notifier<InventarioState> {
  late final LoteRepository _repository;

  @override
  InventarioState build() {
    _repository = ref.watch(loteRepositoryProvider);
    return InventarioState();
  }

  /// Cargar lotes de la tienda seleccionada
  Future<void> cargarLotes() async {
    final tiendaId = ref.read(authProvider).selectedTiendaId;
    if (tiendaId == null) {
      state = state.copyWith(
        lotes: [],
        errorMessage: 'No hay tienda seleccionada',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final lotes = await _repository.getLotes(tiendaId);
      state = state.copyWith(
        isLoading: false,
        lotes: lotes,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Cargar stock agregado de la tienda seleccionada
  Future<void> cargarStock() async {
    final tiendaId = ref.read(authProvider).selectedTiendaId;
    if (tiendaId == null) {
      state = state.copyWith(
        stock: [],
        errorMessage: 'No hay tienda seleccionada',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final stock = await _repository.getStock(tiendaId);
      state = state.copyWith(
        isLoading: false,
        stock: stock,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Cargar catálogo de productos
  Future<void> cargarProductos() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final productos = await _repository.getProductos();
      state = state.copyWith(
        isLoading: false,
        productos: productos,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Crear un nuevo lote
  Future<void> crearLote(LoteCreateModel lote) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repository.crearLote(lote);
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Lote creado correctamente',
        errorMessage: null,
      );
      // Recargar lotes para reflejar el cambio
      await cargarLotes();
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Desactivar un lote
  Future<void> desactivarLote(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.desactivarLote(id);
      // Remover de la lista local
      state = state.copyWith(
        isLoading: false,
        lotes: state.lotes.where((l) => l.id != id).toList(),
        successMessage: 'Lote desactivado correctamente',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Actualizar un producto
  Future<void> actualizarProducto(
    int id, {
    String? tipoIgv,
    bool? isActive,
    dynamic imagenFile,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repository.actualizarProducto(
        id,
        tipoIgv: tipoIgv,
        isActive: isActive,
        imagenFile: imagenFile,
      );
      // Recargar productos para reflejar el cambio
      await cargarProductos();
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Producto actualizado correctamente',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Limpiar mensajes de estado
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}
