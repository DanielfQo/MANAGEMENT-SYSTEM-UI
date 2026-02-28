import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'models/lote_model.dart';
import 'lote_repository.dart';

final loteProvider =
    NotifierProvider<LoteNotifier, LoteModel?>(LoteNotifier.new);
  
final productosProvider = FutureProvider<List<ProductModel>>((ref) async {
  final repository = ref.watch(loteRepositoryProvider);
  return repository.getProductos();
});

class LoteNotifier extends Notifier<LoteModel?> {

  late final LoteRepository _repository;

  @override
  LoteModel? build() {
    _repository = ref.watch(loteRepositoryProvider);
    return null;
  }

  void initLote({
    required String fechaLlegada,
    required String costoOperacion,
    required String costoTransporte,
  }) {
    final tiendaId =
        ref.read(authProvider).selectedTiendaId;

    if (tiendaId == null) return;

    state = LoteModel(
      tienda: tiendaId,
      fechaLlegada: fechaLlegada,
      costoOperacion: costoOperacion,
      costoTransporte: costoTransporte,
      productos: [],
    );
  }

  void addProducto(LoteProducto producto) {
    if (state == null) return;

    state = LoteModel(
      tienda: state!.tienda,
      fechaLlegada: state!.fechaLlegada,
      costoOperacion: state!.costoOperacion,
      costoTransporte: state!.costoTransporte,
      productos: [...state!.productos, producto],
    );
  }

  void removeProducto(LoteProducto producto) {
    if (state == null) return;

    state = LoteModel(
      tienda: state!.tienda,
      fechaLlegada: state!.fechaLlegada,
      costoOperacion: state!.costoOperacion,
      costoTransporte: state!.costoTransporte,
      productos: state!.productos.where((p) => p != producto).toList(),
    );
  }

  Future<void> guardarLote() async {
    if (state == null) return;

    await _repository.crearLote(state!);
    state = null;
  }

  Future<List<ProductModel>> cargarProductos() async {
    return await _repository.getProductos();
  }
}