import 'package:management_system_ui/core/common_libs.dart';
import 'models/lote_model.dart';
import 'models/lote_response_model.dart';

final loteRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return LoteRepository(dio);
});

class LoteRepository {
  final Dio _dio;
  LoteRepository(this._dio);

  Future<void> crearLote(LoteModel lote) async {
    await _dio.post(
      'inventory/lotes/',
      data: lote.toJson(),
    );
  }

  Future<List<ProductModel>> getProductos() async {
    final response = await _dio.get('inventory/productos/');

    return (response.data as List)
        .map((e) => ProductModel.fromJson(e))
        .toList();
  }

  Future<List<LoteResponse>> getLotes(int tiendaId) async {
    final response = await _dio.get(
      'inventory/lotes/',
      queryParameters: {
        'tienda': tiendaId,
      },
    );

    return (response.data as List)
        .map((e) => LoteResponse.fromJson(e))
        .toList();
  }
}
