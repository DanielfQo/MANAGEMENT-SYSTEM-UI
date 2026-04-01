class PagoCreateModel {
  final int deudaId;
  final String monto;

  PagoCreateModel({
    required this.deudaId,
    required this.monto,
  });

  Map<String, dynamic> toJson() {
    return {
      'deuda_id': deudaId,
      'monto': monto,
    };
  }
}
