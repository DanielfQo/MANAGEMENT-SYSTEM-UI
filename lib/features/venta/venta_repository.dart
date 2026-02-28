import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:management_system_ui/core/network/api_client.dart';

import 'package:management_system_ui/features/venta/models/venta_model.dart';
import 'package:management_system_ui/features/venta/models/cliente_model.dart';
import 'package:management_system_ui/features/venta/models/lote_stock_model.dart';


final ventaRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return VentaRepository(dio);
});

class VentaRepository {
  final Dio _dio;
  VentaRepository(this._dio);

  Future<void> crearVenta(VentaModel venta) async {
    await _dio.post(
      '/sales/ventas/',
      data: venta.toJson(),
    );
  }

  Future<List<ClienteModel>> getClientes() async {
    final response = await _dio.get('/sales/clientes/');

    return (response.data as List)
        .map((e) => ClienteModel.fromJson(e))
        .toList();
  }

  Future<List<LoteStockModel>> getStock(int tiendaId) async {
    final response = await _dio.get('/inventory/lotes/');

    final List<LoteStockModel> productos = [];

    for (var lote in response.data) {
      if (lote['tienda']['id'] != tiendaId) continue;

      for (var producto in lote['productos']) {
        if (producto['cantidad_actual'] > 0) {
          productos.add(
            LoteStockModel.fromJson(producto),
          );
        }
      }
    }

    return productos;
  }

}
