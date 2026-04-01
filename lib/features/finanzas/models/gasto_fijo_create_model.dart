class GastoFijoCreateModel {
  final int tiendaId;
  final String tipoGasto;
  final int mes;
  final int anio;
  final String monto;

  GastoFijoCreateModel({
    required this.tiendaId,
    required this.tipoGasto,
    required this.mes,
    required this.anio,
    required this.monto,
  });

  Map<String, dynamic> toJson() {
    return {
      'tienda_id': tiendaId,
      'tipo_gasto': tipoGasto,
      'mes': mes,
      'anio': anio,
      'monto': monto,
    };
  }
}
