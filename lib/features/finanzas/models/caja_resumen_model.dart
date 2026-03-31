class OperacionInfo {
  final int id;
  final String total;
  final String tipo;
  final String metodoPago;
  final String tipoOperacion;

  OperacionInfo({
    required this.id,
    required this.total,
    required this.tipo,
    required this.metodoPago,
    required this.tipoOperacion,
  });

  factory OperacionInfo.fromJson(Map<String, dynamic> json) {
    return OperacionInfo(
      id: json['id'] ?? 0,
      total: json['total']?.toString() ?? '0',
      tipo: json['tipo'] ?? '',
      metodoPago: json['metodo_pago'] ?? '',
      tipoOperacion: json['tipo_operacion'] ?? 'Venta',
    );
  }
}

class ResumenOperaciones {
  final String totalGeneral;
  final String totalContado;
  final String totalCredito;
  final String totalEfectivo;
  final String totalYape;
  final String totalPlin;
  final String totalTransferencia;
  final String totalTarjeta;

  ResumenOperaciones({
    required this.totalGeneral,
    required this.totalContado,
    required this.totalCredito,
    required this.totalEfectivo,
    required this.totalYape,
    required this.totalPlin,
    required this.totalTransferencia,
    required this.totalTarjeta,
  });

  factory ResumenOperaciones.fromJson(Map<String, dynamic> json) {
    return ResumenOperaciones(
      totalGeneral: json['total_general']?.toString() ?? '0',
      totalContado: json['total_contado']?.toString() ?? '0',
      totalCredito: json['total_credito']?.toString() ?? '0',
      totalEfectivo: json['total_efectivo']?.toString() ?? '0',
      totalYape: json['total_yape']?.toString() ?? '0',
      totalPlin: json['total_plin']?.toString() ?? '0',
      totalTransferencia: json['total_transferencia']?.toString() ?? '0',
      totalTarjeta: json['total_tarjeta']?.toString() ?? '0',
    );
  }
}

class CajaResumenModel {
  final String fecha;
  final int tiendaId;
  final List<OperacionInfo> ventas;
  final List<OperacionInfo> servicios;
  final ResumenOperaciones? resumenVentas;
  final ResumenOperaciones? resumenServicios;
  final String totalEfectivo;
  final String totalYape;
  final String totalPlin;
  final String totalTransferencia;
  final String totalTarjeta;
  final String totalContado;
  final String totalCredito;
  final String totalGeneral;

  CajaResumenModel({
    required this.fecha,
    required this.tiendaId,
    required this.ventas,
    required this.servicios,
    this.resumenVentas,
    this.resumenServicios,
    required this.totalEfectivo,
    required this.totalYape,
    required this.totalPlin,
    required this.totalTransferencia,
    required this.totalTarjeta,
    required this.totalContado,
    required this.totalCredito,
    required this.totalGeneral,
  });

  factory CajaResumenModel.fromJson(Map<String, dynamic> json) {
    return CajaResumenModel(
      fecha: json['fecha'] ?? '',
      tiendaId: json['tienda_id'] ?? 0,
      ventas: (json['ventas'] as List?)
              ?.map((v) => OperacionInfo.fromJson(v))
              .toList() ??
          [],
      servicios: (json['servicios'] as List?)
              ?.map((s) => OperacionInfo.fromJson(s))
              .toList() ??
          [],
      resumenVentas: json['resumen_ventas'] != null
          ? ResumenOperaciones.fromJson(json['resumen_ventas'])
          : null,
      resumenServicios: json['resumen_servicios'] != null
          ? ResumenOperaciones.fromJson(json['resumen_servicios'])
          : null,
      totalEfectivo: json['total_efectivo']?.toString() ?? '0',
      totalYape: json['total_yape']?.toString() ?? '0',
      totalPlin: json['total_plin']?.toString() ?? '0',
      totalTransferencia: json['total_transferencia']?.toString() ?? '0',
      totalTarjeta: json['total_tarjeta']?.toString() ?? '0',
      totalContado: json['total_contado']?.toString() ?? '0',
      totalCredito: json['total_credito']?.toString() ?? '0',
      totalGeneral: json['total_general']?.toString() ?? '0',
    );
  }
}
