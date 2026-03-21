class AsistenciaModel {
  final int id;
  final int usuarioTienda;
  final String usuarioNombre;
  final String fecha;
  final String? horaEntrada;
  final String? horaSalida;
  final bool almuerzo;
  final double? horasTrabajadas;

  AsistenciaModel({
    required this.id,
    required this.usuarioTienda,
    required this.usuarioNombre,
    required this.fecha,
    this.horaEntrada,
    this.horaSalida,
    required this.almuerzo,
    this.horasTrabajadas,
  });

  factory AsistenciaModel.fromJson(Map<String, dynamic> json) {
    return AsistenciaModel(
      id: json['id'],
      usuarioTienda: json['usuario_tienda'],
      usuarioNombre: json['usuario_nombre'] ?? '',
      fecha: json['fecha'],
      horaEntrada: json['hora_entrada'],
      horaSalida: json['hora_salida'],
      almuerzo: json['almuerzo'] ?? false,
      horasTrabajadas: json['horas_trabajadas'] != null
          ? (json['horas_trabajadas'] as num).toDouble()
          : null,
    );
  }
}