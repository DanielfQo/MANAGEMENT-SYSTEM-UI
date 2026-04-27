/// Datos transitorios de la nota de crédito devueltos por el backend
/// al emitir una NC para un servicio. El backend NO persiste esta
/// estructura — solo viene en el response inmediato.
class NotaCreditoData {
  final String numero;
  final String estado;
  final String hash;
  final String? xml;
  final String? cdr;
  final String? pdfTicket;
  final String? pdfA4;

  const NotaCreditoData({
    required this.numero,
    required this.estado,
    required this.hash,
    this.xml,
    this.cdr,
    this.pdfTicket,
    this.pdfA4,
  });

  factory NotaCreditoData.fromJson(Map<String, dynamic> json) {
    return NotaCreditoData(
      numero: json['numero']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      hash: json['hash']?.toString() ?? '',
      xml: json['xml'] as String?,
      cdr: json['cdr'] as String?,
      pdfTicket: json['pdf_ticket'] as String?,
      pdfA4: json['pdf_a4'] as String?,
    );
  }
}
