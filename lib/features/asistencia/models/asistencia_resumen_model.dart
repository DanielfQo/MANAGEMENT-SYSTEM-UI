class AsistenciaResumenModel {
  final int usuarioTiendaId;
  final String usuarioNombre;
  final int mes;
  final int anio;
  final int diasTrabajados;
  final double horasTotales;

  AsistenciaResumenModel({
    required this.usuarioTiendaId,
    required this.usuarioNombre,
    required this.mes,
    required this.anio,
    required this.diasTrabajados,
    required this.horasTotales,
  });

  factory AsistenciaResumenModel.fromJson(Map<String, dynamic> json) {
    return AsistenciaResumenModel(
      usuarioTiendaId: json['usuario_tienda_id'],
      usuarioNombre: json['usuario_nombre'] ?? '',
      mes: json['mes'],
      anio: json['anio'],
      diasTrabajados: json['dias_trabajados'],
      horasTotales: (json['horas_totales'] as num).toDouble(),
    );
  }
}