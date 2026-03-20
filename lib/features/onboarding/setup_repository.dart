import 'package:management_system_ui/core/common_libs.dart';
import 'models/empresa_model.dart';

export 'models/empresa_model.dart';

final setupRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return SetupRepository(dio);
});

class SetupRepository {
  final Dio _dio;
  SetupRepository(this._dio);

  Future<List<EmpresaModel>> getEmpresas() async {
    try {
      final response = await _dio.get('store/empresa/');
      return (response.data as List)
          .map((e) => EmpresaModel.fromJson(e))
          .toList();
    } on DioException catch (_) {
      throw Exception('Error al obtener las empresas');
    }
  }

  Future<EmpresaModel> crearEmpresa({
    required String ruc,
    required String razonSocial,
    required String nombreComercial,
  }) async {
    try {
      final response = await _dio.post(
        'store/empresa/',
        data: {
          'ruc': ruc,
          'razon_social': razonSocial,
          'nombre_comercial': nombreComercial,
        },
      );
      return EmpresaModel.fromJson(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Error al crear la empresa';
      if (data is Map) {
        final values = data.values.first;
        message = values is List ? values.first.toString() : values.toString();
      }
      throw Exception(message);
    }
  }

  Future<void> crearTienda({
    required String nombreSede,
    required String direccion,
    required String ubigeo,
    required String serieFactura,
    required String serieBoleta,
    required String serieTicket,
    required int empresaId,
  }) async {
    try {
      await _dio.post(
        'store/',
        data: {
          'nombre_sede': nombreSede,
          'direccion': direccion,
          'ubigeo': ubigeo,
          'serie_factura': serieFactura,
          'serie_boleta': serieBoleta,
          'serie_ticket': serieTicket,
          'empresa_id': empresaId,
        },
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Error al crear la tienda';
      if (data is Map) {
        final values = data.values.first;
        message = values is List ? values.first.toString() : values.toString();
      }
      throw Exception(message);
    }
  }
}