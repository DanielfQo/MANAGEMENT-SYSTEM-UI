import 'package:management_system_ui/features/venta/models/cliente_model.dart';

class TiendaInfo {
  final int id;
  final String nombreSede;

  TiendaInfo({
    required this.id,
    required this.nombreSede,
  });

  factory TiendaInfo.fromJson(Map<String, dynamic> json) {
    return TiendaInfo(
      id: json['id'],
      nombreSede: json['nombre_sede'] ?? '',
    );
  }
}

class UsuarioInfo {
  final int id;
  final String nombre;

  UsuarioInfo({
    required this.id,
    required this.nombre,
  });

  factory UsuarioInfo.fromJson(Map<String, dynamic> json) {
    return UsuarioInfo(
      id: json['id'],
      nombre: json['nombre'] ?? '',
    );
  }
}

class VentaLineaModel {
  final int id;
  final String productoNombre;
  final String productoCodigo;
  final String unidadMedida;
  final String cantidad;
  final String precio;
  final String subtotal;
  final bool esAveriado;

  VentaLineaModel({
    required this.id,
    required this.productoNombre,
    required this.productoCodigo,
    required this.unidadMedida,
    required this.cantidad,
    required this.precio,
    required this.subtotal,
    required this.esAveriado,
  });

  factory VentaLineaModel.fromJson(Map<String, dynamic> json) {
    return VentaLineaModel(
      id: json['id'],
      productoNombre: json['producto_nombre'] ?? '',
      productoCodigo: json['producto_codigo'] ?? '',
      unidadMedida: json['unidad_medida'] ?? '',
      cantidad: json['cantidad']?.toString() ?? '0',
      precio: json['precio']?.toString() ?? '0',
      subtotal: json['subtotal']?.toString() ?? '0',
      esAveriado: json['es_averiado'] ?? false,
    );
  }
}

class VentaSunatLineaModel {
  final int id;
  final String productoNombre;
  final String productoCodigo;
  final String unidadMedida;
  final String tipoAfectacionIgv;
  final String cantidad;
  final String precio;
  final String valorUnitarioSinIgv;
  final String subtotal;
  final bool esRelleno;
  final String? productoOriginalNombre;

  VentaSunatLineaModel({
    required this.id,
    required this.productoNombre,
    required this.productoCodigo,
    required this.unidadMedida,
    required this.tipoAfectacionIgv,
    required this.cantidad,
    required this.precio,
    required this.valorUnitarioSinIgv,
    required this.subtotal,
    required this.esRelleno,
    this.productoOriginalNombre,
  });

  factory VentaSunatLineaModel.fromJson(Map<String, dynamic> json) {
    return VentaSunatLineaModel(
      id: json['id'],
      productoNombre: json['producto_nombre'] ?? '',
      productoCodigo: json['producto_codigo'] ?? '',
      unidadMedida: json['unidad_medida'] ?? '',
      tipoAfectacionIgv: json['tipo_afectacion_igv'] ?? '',
      cantidad: json['cantidad']?.toString() ?? '0',
      precio: json['precio']?.toString() ?? '0',
      valorUnitarioSinIgv: json['valor_unitario_sin_igv']?.toString() ?? '0',
      subtotal: json['subtotal']?.toString() ?? '0',
      esRelleno: json['es_relleno'] ?? false,
      productoOriginalNombre: json['producto_original_nombre'],
    );
  }
}

class PropuestaSunatItem {
  final int loteProductoId;
  final String loteProductoNombre;
  final String cantidad;
  final String precio;
  final String subtotal;
  final bool esRelleno;
  final int? loteProductoOriginalId;

  PropuestaSunatItem({
    required this.loteProductoId,
    required this.loteProductoNombre,
    required this.cantidad,
    required this.precio,
    required this.subtotal,
    required this.esRelleno,
    this.loteProductoOriginalId,
  });

  factory PropuestaSunatItem.fromJson(Map<String, dynamic> json) {
    return PropuestaSunatItem(
      loteProductoId: json['lote_producto_id'],
      loteProductoNombre: json['lote_producto_nombre'] ?? '',
      cantidad: json['cantidad']?.toString() ?? '0',
      precio: json['precio']?.toString() ?? '0',
      subtotal: json['subtotal']?.toString() ?? '0',
      esRelleno: json['es_relleno'] ?? false,
      loteProductoOriginalId: json['lote_producto_original_id'],
    );
  }
}

class NotaCreditoModel {
  final int id;
  final String tipoComprobante;
  final String tipoComprobanteDisplay;
  final String numeroComprobante;
  final String hashCpe;
  final String? urlXml;
  final String? urlPdfA4;
  final String? urlPdfTicket;
  final String? urlCdr;
  final String motivo;
  final String fecha;

  NotaCreditoModel({
    required this.id,
    required this.tipoComprobante,
    required this.tipoComprobanteDisplay,
    required this.numeroComprobante,
    required this.hashCpe,
    this.urlXml,
    this.urlPdfA4,
    this.urlPdfTicket,
    this.urlCdr,
    required this.motivo,
    required this.fecha,
  });

  factory NotaCreditoModel.fromJson(Map<String, dynamic> json) {
    return NotaCreditoModel(
      id: json['id'],
      tipoComprobante: json['tipo_comprobante'] ?? '',
      tipoComprobanteDisplay: json['tipo_comprobante_display'] ?? '',
      numeroComprobante: json['numero_comprobante'] ?? '',
      hashCpe: json['hash_cpe'] ?? '',
      urlXml: json['url_xml'],
      urlPdfA4: json['url_pdf_a4'],
      urlPdfTicket: json['url_pdf_ticket'],
      urlCdr: json['url_cdr'],
      motivo: json['motivo'] ?? '',
      fecha: json['fecha'] ?? '',
    );
  }
}

class VentaReadModel {
  final int id;
  final TiendaInfo tienda;
  final UsuarioInfo usuarioTienda;
  final ClienteModel? cliente;
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
  final String fecha;
  final double total;
  final bool isActive;
  final List<VentaLineaModel> detalle;
  final List<VentaSunatLineaModel> lineasSunat;
  final List<PropuestaSunatItem>? propuestaSunat;
  final NotaCreditoModel? notaCredito;

  VentaReadModel({
    required this.id,
    required this.tienda,
    required this.usuarioTienda,
    this.cliente,
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
    required this.fecha,
    required this.total,
    required this.isActive,
    required this.detalle,
    required this.lineasSunat,
    this.propuestaSunat,
    this.notaCredito,
  });

  factory VentaReadModel.fromJson(Map<String, dynamic> json) {
    return VentaReadModel(
      id: json['id'],
      tienda: TiendaInfo.fromJson(json['tienda'] ?? {}),
      usuarioTienda: UsuarioInfo.fromJson(json['usuario_tienda'] ?? {}),
      cliente: json['cliente'] != null
          ? ClienteModel.fromJson(json['cliente'])
          : null,
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
      fecha: json['fecha'] ?? '',
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] ?? true,
      detalle: (json['detalle'] as List?)
              ?.map((d) => VentaLineaModel.fromJson(d))
              .toList() ??
          [],
      lineasSunat: (json['lineas_sunat'] as List?)
              ?.map((l) => VentaSunatLineaModel.fromJson(l))
              .toList() ??
          [],
      propuestaSunat: (json['propuesta_sunat'] as List?)
          ?.map((p) => PropuestaSunatItem.fromJson(p))
          .toList(),
      notaCredito: json['nota_credito'] != null
          ? NotaCreditoModel.fromJson(json['nota_credito'])
          : null,
    );
  }
}
