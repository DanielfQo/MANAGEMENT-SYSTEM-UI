class TiendaGastoFijoDetalle {
  final String tienda;
  final Map<String, String> detalle;
  final String totalGeneral;
  final bool mesCerrado;

  TiendaGastoFijoDetalle({
    required this.tienda,
    required this.detalle,
    required this.totalGeneral,
    required this.mesCerrado,
  });

  factory TiendaGastoFijoDetalle.fromJson(Map<String, dynamic> json) {
    final detalleRaw = json['detalle'] as Map<String, dynamic>?;
    final detalle = detalleRaw?.map(
          (key, value) => MapEntry(key, value?.toString() ?? '0'),
        ) ??
        {};

    return TiendaGastoFijoDetalle(
      tienda: json['tienda'] ?? '',
      detalle: detalle,
      totalGeneral: json['total_general']?.toString() ?? '0',
      mesCerrado: json['mes_cerrado'] ?? false,
    );
  }
}

class GastoFijoResumenModel {
  final List<TiendaGastoFijoDetalle> tiendas;
  final String totalGlobal;

  GastoFijoResumenModel({
    required this.tiendas,
    required this.totalGlobal,
  });

  factory GastoFijoResumenModel.fromJson(Map<String, dynamic> json) {
    // Si la respuesta tiene 'tiendas' (múltiples tiendas)
    if (json.containsKey('tiendas')) {
      return GastoFijoResumenModel(
        tiendas: (json['tiendas'] as List?)
                ?.map((t) => TiendaGastoFijoDetalle.fromJson(t))
                .toList() ??
            [],
        totalGlobal: json['total_global']?.toString() ?? '0',
      );
    }

    // Si la respuesta es una tienda única (filtrada por tienda_id)
    return GastoFijoResumenModel(
      tiendas: [TiendaGastoFijoDetalle.fromJson(json)],
      totalGlobal: json['total_general']?.toString() ?? '0',
    );
  }
}
