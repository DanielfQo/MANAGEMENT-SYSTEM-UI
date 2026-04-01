class PagoModel {
  final int id;
  final int clienteId;
  final int origenId;
  final String tipoOrigen;
  final String fecha;
  final String monto;

  PagoModel({
    required this.id,
    required this.clienteId,
    required this.origenId,
    required this.tipoOrigen,
    required this.fecha,
    required this.monto,
  });

  factory PagoModel.fromJson(Map<String, dynamic> json) {
    return PagoModel(
      id: json['id'] ?? 0,
      clienteId: json['cliente_id'] ?? 0,
      origenId: json['origen_id'] ?? 0,
      tipoOrigen: json['tipo_origen'] ?? '',
      fecha: json['fecha'] ?? '',
      monto: json['monto']?.toString() ?? '0',
    );
  }
}
