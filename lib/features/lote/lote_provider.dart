import 'package:management_system_ui/core/common_libs.dart';
import 'models/lote_model.dart';

final loteProvider =
    NotifierProvider<LoteNotifier, LoteModel?>(LoteNotifier.new);

class LoteNotifier extends Notifier<LoteModel?> {

  @override
  LoteModel? build() {
    return null; // inicialmente no hay lote creado
  }

  /// Crear lote base (sin productos)
  void initLote({
    required int tienda,
    required String fechaLlegada,
    required String costoOperacion,
    required String costoTransporte,
  }) {
    state = LoteModel(
      tienda: tienda,
      fechaLlegada: fechaLlegada,
      costoOperacion: costoOperacion,
      costoTransporte: costoTransporte,
      productos: [],
    );
  }

  /// Agregar producto
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

  /// Eliminar producto
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

  /// Limpiar todo
  void clear() {
    state = null;
  }
}