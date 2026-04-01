class CajaCierreModel {
  final int id;
  final int tienda;
  final int usuarioTienda;
  final String fechaHora;
  final String montoEsperado;
  final String montoReal;
  final String diferencia;
  final String estado;
  final String observaciones;

  CajaCierreModel({
    required this.id,
    required this.tienda,
    required this.usuarioTienda,
    required this.fechaHora,
    required this.montoEsperado,
    required this.montoReal,
    required this.diferencia,
    required this.estado,
    required this.observaciones,
  });

  factory CajaCierreModel.fromJson(Map<String, dynamic> json) {
    return CajaCierreModel(
      id: json['id'] ?? 0,
      tienda: json['tienda'] ?? 0,
      usuarioTienda: json['usuario_tienda'] ?? 0,
      fechaHora: json['fecha_hora'] ?? '',
      montoEsperado: json['monto_esperado']?.toString() ?? '0',
      montoReal: json['monto_real']?.toString() ?? '0',
      diferencia: json['diferencia']?.toString() ?? '0',
      estado: json['estado'] ?? '',
      observaciones: json['observaciones'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tienda_id': tienda,
      'monto_real': montoReal,
      'observaciones': observaciones,
    };
  }
}
