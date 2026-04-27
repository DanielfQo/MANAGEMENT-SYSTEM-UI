class PagoInfo {
  final String fecha;
  final String monto;

  PagoInfo({
    required this.fecha,
    required this.monto,
  });

  factory PagoInfo.fromJson(Map<String, dynamic> json) {
    return PagoInfo(
      fecha: json['fecha'] ?? '',
      monto: json['monto']?.toString() ?? '0',
    );
  }
}

class DeudaModel {
  final int id;
  final int origenId;
  final String tipoOrigen;
  final String? numeroComprobante;
  final String montoTotal;
  final String saldo;
  final String estado;
  final List<PagoInfo> pagos;

  DeudaModel({
    required this.id,
    required this.origenId,
    required this.tipoOrigen,
    this.numeroComprobante,
    required this.montoTotal,
    required this.saldo,
    required this.estado,
    required this.pagos,
  });

  factory DeudaModel.fromJson(Map<String, dynamic> json) {
    return DeudaModel(
      id: json['id'] ?? 0,
      origenId: json['origen_id'] ?? 0,
      tipoOrigen: json['tipo_origen'] ?? '',
      numeroComprobante: json['numero_comprobante'] as String?,
      montoTotal: json['monto_total']?.toString() ?? '0',
      saldo: json['saldo']?.toString() ?? '0',
      estado: json['estado'] ?? 'ACTIVA',
      pagos: (json['pagos'] as List?)
              ?.map((p) => PagoInfo.fromJson(p))
              .toList() ??
          [],
    );
  }
}
