import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'models/lote_model.dart';
import 'models/lote_response_model.dart';
import 'models/producto_model.dart';
import 'models/producto_catalogo_model.dart';
import 'models/stock_model.dart';
import 'lote_repository.dart';

// Main notifier for inventory state
final inventarioProvider =
    NotifierProvider<InventarioNotifier, InventarioState>(
  InventarioNotifier.new,
);

// Product catalog notifier with pagination and search
final productoCatalogoProvider =
    NotifierProvider<ProductoCatalogoNotifier, ProductoCatalogoState>(
  ProductoCatalogoNotifier.new,
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
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;

  InventarioState({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.lotes = const [],
    this.stock = const [],
    this.productos = const [],
    this.nextCursor,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  InventarioState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    List<LoteResponse>? lotes,
    List<StockModel>? stock,
    List<ProductoModel>? productos,
    String? nextCursor,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return InventarioState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
      lotes: lotes ?? this.lotes,
      stock: stock ?? this.stock,
      productos: productos ?? this.productos,
      nextCursor: nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
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

  /// Cargar lotes de la tienda seleccionada (resetea paginación)
  Future<void> cargarLotes() async {
    final tiendaId = ref.read(authProvider).selectedTiendaId;
    if (tiendaId == null) {
      state = state.copyWith(
        lotes: [],
        errorMessage: 'No hay tienda seleccionada',
        nextCursor: null,
        hasMore: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repository.getLotes(tiendaId);
      state = state.copyWith(
        isLoading: false,
        lotes: result.lotes,
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor != null,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Cargar más lotes (para infinite scroll)
  Future<void> cargarMasLotes() async {
    if (state.isLoadingMore || !state.hasMore) return;
    final tiendaId = ref.read(authProvider).selectedTiendaId;
    if (tiendaId == null) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _repository.getLotes(
        tiendaId,
        cursor: state.nextCursor,
      );
      state = state.copyWith(
        isLoadingMore: false,
        lotes: [...state.lotes, ...result.lotes],
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor != null,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
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

// Product Catalog State
class ProductoCatalogoState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final List<ProductoCatalogoModel> productos;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;
  final String? searchQuery;

  ProductoCatalogoState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.productos = const [],
    this.nextCursor,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.searchQuery,
  });

  ProductoCatalogoState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    List<ProductoCatalogoModel>? productos,
    String? nextCursor,
    bool? hasMore,
    bool? isLoadingMore,
    String? searchQuery,
  }) {
    return ProductoCatalogoState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      productos: productos ?? this.productos,
      nextCursor: nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// Product Catalog Notifier
class ProductoCatalogoNotifier extends Notifier<ProductoCatalogoState> {
  late final LoteRepository _repository;

  @override
  ProductoCatalogoState build() {
    _repository = ref.watch(loteRepositoryProvider);
    return ProductoCatalogoState();
  }

  /// Cargar catálogo (primera página o con búsqueda)
  Future<void> cargarCatalogo({String? search}) async {
    final tiendaId = ref.read(authProvider).selectedTiendaId;
    if (tiendaId == null) {
      state = state.copyWith(
        productos: [],
        errorMessage: 'No hay tienda seleccionada',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, searchQuery: search);
    try {
      final result = await _repository.getCatalogo(tiendaId, search: search);
      state = state.copyWith(
        isLoading: false,
        productos: result.productos,
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor != null,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Cargar más productos (para infinite scroll)
  Future<void> cargarMasProductos() async {
    if (state.isLoadingMore || !state.hasMore) return;
    final tiendaId = ref.read(authProvider).selectedTiendaId;
    if (tiendaId == null) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _repository.getCatalogo(
        tiendaId,
        cursor: state.nextCursor,
        search: state.searchQuery,
      );
      state = state.copyWith(
        isLoadingMore: false,
        productos: [...state.productos, ...result.productos],
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor != null,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Limpiar mensajes de estado
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}
