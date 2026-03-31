import 'package:management_system_ui/features/venta/models/cliente_model.dart';

class ServicioCreateModel {
  final int tiendaId;
  final String? descripcion;
  final String fechaInicio;
  final String fechaFin;
  final String total;
  final String tipo;
  final String metodoPago;
  final String? tipoComprobante;
  final int? clienteId;
  final ClienteNuevoInput? clienteNuevo;
  final Map<String, String>? camposFaltantesClienteExistente;

  ServicioCreateModel({
    required this.tiendaId,
    this.descripcion,
    required this.fechaInicio,
    required this.fechaFin,
    required this.total,
    required this.tipo,
    required this.metodoPago,
    this.tipoComprobante,
    this.clienteId,
    this.clienteNuevo,
    this.camposFaltantesClienteExistente,
  });

  String? validate() {
    if (tiendaId <= 0) {
      return 'Tienda es requerida';
    }

    if (fechaInicio.isEmpty) {
      return 'Fecha de inicio es requerida';
    }

    if (fechaFin.isEmpty) {
      return 'Fecha de fin es requerida';
    }

    final totalNum = double.tryParse(total);
    if (totalNum == null || totalNum <= 0) {
      return 'El total debe ser un número mayor a 0';
    }

    if (metodoPago.isEmpty) {
      return 'Método de pago es requerido';
    }

    switch (tipo.toUpperCase()) {
      case 'NORMAL':
        return null;

      case 'CREDITO':
        return _validateCredito();

      case 'SUNAT':
        return _validateSunat();

      default:
        return 'Tipo de servicio no válido: $tipo';
    }
  }

  String? _validateCredito() {
    if (clienteId == null && clienteNuevo == null) {
      return 'Cliente es requerido para servicios a crédito';
    }

    if (clienteNuevo != null) {
      return _validateClienteCredito();
    }

    return null;
  }

  String? _validateSunat() {
    if (tipoComprobante == null || tipoComprobante!.isEmpty) {
      return 'Tipo de comprobante es requerido para servicios SUNAT';
    }

    if (tipoComprobante != '01' && tipoComprobante != '03') {
      return 'Tipo de comprobante debe ser 01 (Factura) o 03 (Boleta)';
    }

    if (tipoComprobante == '01') {
      if (clienteId == null && clienteNuevo == null) {
        return 'Cliente es requerido para facturas';
      }

      if (clienteNuevo != null) {
        return _validateClienteSunatFactura();
      }
    }

    if (tipoComprobante == '03' && clienteNuevo != null) {
      return _validateClienteSunatBoleta();
    }

    return null;
  }

  String? _validateClienteCredito() {
    if (clienteNuevo == null) return null;

    if (clienteNuevo!.nombre.trim().isEmpty) {
      return 'Nombre de cliente es requerido para crédito';
    }
    if (clienteNuevo!.tipoDocumento.trim().isEmpty) {
      return 'Tipo de documento es requerido para crédito';
    }
    if (clienteNuevo!.numeroDocumento.trim().isEmpty) {
      return 'Número de documento es requerido para crédito';
    }
    if (clienteNuevo!.telefono.trim().isEmpty) {
      return 'Teléfono es requerido para crédito';
    }
    if (clienteNuevo!.email.trim().isEmpty) {
      return 'Email es requerido para crédito';
    }
    if (clienteNuevo!.direccion.trim().isEmpty) {
      return 'Dirección es requerida para crédito';
    }

    return null;
  }

  String? _validateClienteSunatFactura() {
    if (clienteNuevo == null) return null;

    if (clienteNuevo!.nombre.trim().isEmpty) {
      return 'Nombre de cliente/empresa es requerido para factura';
    }

    final tipoDoc = clienteNuevo!.tipoDocumento.trim();
    if (tipoDoc.isEmpty || tipoDoc != '6') {
      return 'Tipo de documento DEBE ser RUC (tipo_documento: 6) para factura';
    }

    final numDoc = clienteNuevo!.numeroDocumento.trim();
    if (numDoc.isEmpty) {
      return 'RUC es requerido para factura';
    }

    if (numDoc.length != 11 || !RegExp(r'^\d+$').hasMatch(numDoc)) {
      return 'RUC debe ser exactamente 11 dígitos numéricos';
    }

    return null;
  }

  String? _validateClienteSunatBoleta() {
    if (clienteNuevo == null) return null;

    if (clienteNuevo!.nombre.trim().isEmpty) {
      return 'Nombre de cliente es requerido para boleta';
    }

    if (clienteNuevo!.numeroDocumento.trim().isEmpty) {
      return 'Número de documento es requerido para boleta';
    }

    final tipoDoc = clienteNuevo!.tipoDocumento.trim();
    if (tipoDoc.isNotEmpty && tipoDoc == '6') {
      return 'Para boletas no puede usar RUC (tipo_documento: 6)';
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'tienda_id': tiendaId,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
      'total': total,
      'tipo': tipo,
      'metodo_pago': metodoPago,
    };

    if (descripcion != null && descripcion!.isNotEmpty) {
      map['descripcion'] = descripcion;
    }

    if (tipo.toUpperCase() == 'SUNAT' &&
        tipoComprobante != null &&
        tipoComprobante!.isNotEmpty) {
      map['tipo_comprobante'] = tipoComprobante;
    }

    if (clienteId != null && clienteId! > 0) {
      map['cliente_id'] = clienteId;
      if (camposFaltantesClienteExistente != null &&
          camposFaltantesClienteExistente!.isNotEmpty) {
        map['cliente_campos_adicionales'] = camposFaltantesClienteExistente;
      }
    } else if (clienteNuevo != null) {
      map['cliente'] = clienteNuevo!.toJson();
    }

    return map;
  }
}
