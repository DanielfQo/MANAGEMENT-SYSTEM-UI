import 'dart:typed_data';
import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/venta/models/cliente_model.dart';
import 'package:management_system_ui/features/venta/models/venta_read_model.dart';
import 'package:management_system_ui/features/servicio/models/servicio_read_model.dart';
import 'models/caja_cierre_model.dart';
import 'models/caja_resumen_model.dart';
import 'models/deuda_model.dart';
import 'models/gasto_fijo_create_model.dart';
import 'models/gasto_fijo_resumen_model.dart';
import 'models/gasto_tipo_model.dart';
import 'models/gasto_variable_create_model.dart';
import 'models/gasto_variable_resumen_model.dart';
import 'models/pago_model.dart';

final finanzasRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return FinanzasRepository(dio);
});

class FinanzasRepository {
  final Dio _dio;
  FinanzasRepository(this._dio);

  /// Obtener resumen del día de caja
  Future<CajaResumenModel> getCajaResumen({required int tiendaId}) async {
    try {
      final response = await _dio.get(
        'finances/caja/resumen/',
        queryParameters: {'tienda_id': tiendaId},
      );
      return CajaResumenModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Cerrar caja
  Future<CajaCierreModel> cerrarCaja({
    required int tiendaId,
    required String montoReal,
    required String observaciones,
  }) async {
    try {
      final response = await _dio.post(
        'finances/caja/cerrar/',
        data: {
          'tienda_id': tiendaId,
          'monto_real': montoReal,
          'observaciones': observaciones,
        },
      );
      return CajaCierreModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Obtener lista de deudas con filtros
  Future<List<DeudaModel>> getDeudas({
    int? cliente,
    String? estado,
    String? ordering,
    int? servicio,
    int? venta,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (cliente != null) queryParams['cliente'] = cliente;
      if (estado != null) queryParams['estado'] = estado;
      if (ordering != null) queryParams['ordering'] = ordering;
      if (servicio != null) queryParams['servicio'] = servicio;
      if (venta != null) queryParams['venta'] = venta;

      final response = await _dio.get(
        'finances/deudas/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = response.data;
      final List results;
      if (data is List) {
        results = data;
      } else {
        results = [];
      }

      return results
          .map((e) => DeudaModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Obtener lista de pagos con filtros
  Future<List<PagoModel>> getPagos({
    int? deudaCliente,
    String? deudaEstado,
    int? deudaServicio,
    int? deudaVenta,
    String? ordering,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (deudaCliente != null) queryParams['deuda__cliente'] = deudaCliente;
      if (deudaEstado != null) queryParams['deuda__estado'] = deudaEstado;
      if (deudaServicio != null) queryParams['deuda__servicio'] = deudaServicio;
      if (deudaVenta != null) queryParams['deuda__venta'] = deudaVenta;
      if (ordering != null) queryParams['ordering'] = ordering;

      final response = await _dio.get(
        'finances/pagos/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = response.data;
      final List results;
      if (data is List) {
        results = data;
      } else {
        results = [];
      }

      return results
          .map((e) => PagoModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Registrar pago de deuda y obtener comprobante en PDF
  Future<Uint8List> registrarPago({
    required int deudaId,
    required String monto,
  }) async {
    try {
      final response = await _dio.post(
        'finances/pagos/',
        data: {
          'deuda_id': deudaId,
          'monto': monto,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as Uint8List;
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Obtener resumen de gastos fijos para un mes, año y tienda
  Future<GastoFijoResumenModel> getGastosFijosResumen({
    required int tiendaId,
    required int mes,
    required int anio,
  }) async {
    try {
      final response = await _dio.get(
        'finances/gastos/resumen/',
        queryParameters: {
          'tienda_id': tiendaId,
          'mes': mes,
          'anio': anio,
          'tipo': 'fijo',
        },
      );
      return GastoFijoResumenModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Obtener tipos de gastos disponibles
  Future<List<GastoTipoModel>> getTiposGasto() async {
    try {
      final response = await _dio.get('finances/gastos/tipos/');

      final data = response.data;
      final List results;
      if (data is List) {
        results = data;
      } else {
        results = [];
      }

      return results
          .map((e) => GastoTipoModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Crear gasto fijo manual
  Future<void> crearGastoFijo(GastoFijoCreateModel gasto) async {
    try {
      await _dio.post(
        'finances/gastos/manual/',
        data: gasto.toJson(),
      );
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Obtener resumen de gastos variables para un mes, año y tienda
  Future<GastoVariableResumenModel> getGastosVariablesResumen({
    required int tiendaId,
    required int mes,
    required int anio,
  }) async {
    try {
      final response = await _dio.get(
        'finances/gastos-variable/resumen/',
        queryParameters: {
          'tienda_id': tiendaId,
          'mes': mes,
          'anio': anio,
        },
      );
      return GastoVariableResumenModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Crear gasto variable
  Future<void> crearGastoVariable(GastoVariableCreateModel gasto) async {
    try {
      await _dio.post(
        'finances/gastos-variable/crear/',
        data: gasto.toJson(),
      );
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Cerrar mes de gastos para una tienda
  Future<void> cerrarMesGastos({
    required int tiendaId,
    required int mes,
    required int anio,
  }) async {
    try {
      await _dio.post(
        'finances/gastos/cerrar-mes/',
        data: {
          'tienda_id': tiendaId,
          'mes': mes,
          'anio': anio,
        },
      );
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Buscar cliente por número de documento
  Future<ClienteModel?> buscarClientePorDocumento(String numeroDocumento) async {
    try {
      final response = await _dio.get(
        'sales/clientes/',
        queryParameters: {'search': numeroDocumento},
      );

      final data = response.data;
      final List results;
      if (data is Map && data.containsKey('results')) {
        results = data['results'] as List;
      } else if (data is List) {
        results = data;
      } else {
        results = [];
      }

      if (results.isEmpty) return null;
      return ClienteModel.fromJson(results.first as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Buscar venta por número de comprobante
  Future<VentaReadModel?> buscarVentaPorComprobante(
      String numeroComprobante) async {
    try {
      final response = await _dio.get('sales/ventas/$numeroComprobante/');
      return VentaReadModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // 404 significa que no existe
      if (e.response?.statusCode == 404) {
        return null;
      }
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Buscar servicio por número de comprobante
  Future<ServicioReadModel?> buscarServicioPorComprobante(
      String numeroComprobante) async {
    try {
      final response = await _dio.get('services/servicio/$numeroComprobante/');
      return ServicioReadModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // 404 significa que no existe
      if (e.response?.statusCode == 404) {
        return null;
      }
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Extrae mensaje de error de la respuesta de la API
  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final values = data.values.first;
      if (values is List) {
        return values.first.toString();
      }
      return values.toString();
    }
    return 'Error en la operación';
  }
}
