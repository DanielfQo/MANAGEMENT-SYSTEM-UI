import 'package:management_system_ui/features/venta/models/cliente_model.dart';
import 'package:management_system_ui/features/venta/models/venta_read_model.dart';

class ServicioReadModel {
  final int id;
  final ClienteModel? cliente;
  final TiendaInfo tienda;
  final UsuarioInfo usuarioTienda;
  final String tipo;
  final String tipoDisplay;
  final String metodoPago;
  final String metodoPagoDisplay;
  final String estadoSunat;
  final String estadoSunatDisplay;
  final String tipoComprobante;
  final String tipoComprobanteDisplay;
  final String numeroComprobante;
  final String hashCpe;
  final String? urlXml;
  final String? urlPdfA4;
  final String? urlPdfTicket;
  final String? urlCdr;
  final String motivoRechazo;
  final String descripcion;
  final String fechaInicio;
  final String fechaFin;
  final double total;
  final bool isActive;
  final String fecha;
  final double deuda;

  ServicioReadModel({
    required this.id,
    this.cliente,
    required this.tienda,
    required this.usuarioTienda,
    required this.tipo,
    required this.tipoDisplay,
    required this.metodoPago,
    required this.metodoPagoDisplay,
    required this.estadoSunat,
    required this.estadoSunatDisplay,
    required this.tipoComprobante,
    required this.tipoComprobanteDisplay,
    required this.numeroComprobante,
    required this.hashCpe,
    this.urlXml,
    this.urlPdfA4,
    this.urlPdfTicket,
    this.urlCdr,
    required this.motivoRechazo,
    required this.descripcion,
    required this.fechaInicio,
    required this.fechaFin,
    required this.total,
    required this.isActive,
    required this.fecha,
    required this.deuda,
  });

  factory ServicioReadModel.fromJson(Map<String, dynamic> json) {
    return ServicioReadModel(
      id: json['id'],
      cliente: json['cliente'] != null
          ? ClienteModel.fromJson(json['cliente'])
          : null,
      tienda: TiendaInfo.fromJson(json['tienda'] ?? {}),
      usuarioTienda: UsuarioInfo.fromJson(json['usuario_tienda'] ?? {}),
      tipo: json['tipo'] ?? '',
      tipoDisplay: json['tipo_display'] ?? '',
      metodoPago: json['metodo_pago'] ?? '',
      metodoPagoDisplay: json['metodo_pago_display'] ?? '',
      estadoSunat: json['estado_sunat'] ?? 'NO_APLICA',
      estadoSunatDisplay: json['estado_sunat_display'] ?? '',
      tipoComprobante: json['tipo_comprobante'] ?? '',
      tipoComprobanteDisplay: json['tipo_comprobante_display'] ?? '',
      numeroComprobante: json['numero_comprobante'] ?? '',
      hashCpe: json['hash_cpe'] ?? '',
      urlXml: json['url_xml'],
      urlPdfA4: json['url_pdf_a4'],
      urlPdfTicket: json['url_pdf_ticket'],
      urlCdr: json['url_cdr'],
      motivoRechazo: json['motivo_rechazo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      fechaInicio: json['fecha_inicio'] ?? '',
      fechaFin: json['fecha_fin'] ?? '',
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] ?? true,
      fecha: json['fecha'] ?? '',
      deuda: double.tryParse(json['deuda']?.toString() ?? '0') ?? 0,
    );
  }
}
