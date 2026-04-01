class GastoVariableCreateModel {
  final String descripcion;
  final String monto;
  final String fecha;
  final int? tiendaId;

  GastoVariableCreateModel({
    required this.descripcion,
    required this.monto,
    required this.fecha,
    this.tiendaId,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'descripcion': descripcion,
      'monto': monto,
      'fecha': fecha,
    };
    // Solo incluir tienda_id si está presente (dueño con múltiples tiendas)
    if (tiendaId != null) {
      data['tienda_id'] = tiendaId!;
    }
    return data;
  }
}
