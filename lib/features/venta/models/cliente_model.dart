class ClienteModel {
  final int id;
  final String nombre;
  final String tipoDocumento;
  final String tipoDocumentoDisplay;
  final String numeroDocumento;
  final String telefono;
  final String? email;
  final String direccion;
  final String? saldoTotal;

  ClienteModel({
    required this.id,
    required this.nombre,
    required this.tipoDocumento,
    required this.tipoDocumentoDisplay,
    required this.numeroDocumento,
    required this.telefono,
    this.email,
    required this.direccion,
    this.saldoTotal,
  });

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    return ClienteModel(
      id: (json['id'] as int?) ?? 0,
      nombre: json['nombre']?.toString() ?? '',
      tipoDocumento: json['tipo_documento'] ?? '1',
      tipoDocumentoDisplay: json['tipo_documento_display'] ?? 'DNI',
      numeroDocumento: json['numero_documento'] ?? '',
      telefono: json['telefono'] ?? '',
      email: json['email'],
      direccion: json['direccion'] ?? '',
      saldoTotal: json['saldo_total'],
    );
  }
}

/// Cliente nuevo para crear en una venta
///
/// Estructura flexible que permite campos opcionales en el modelo,
/// pero la VALIDACIÓN (VentaCreateModel.validate()) exige diferentes campos
/// según el tipo de venta. Usa ClienteFormConfig para saber qué campos mostrar
/// como requeridos en la UI.
///
/// Campos requeridos por tipo de venta:
/// - NORMAL: solo nombre
/// - CREDITO: nombre, tipoDocumento, numeroDocumento, telefono, email, direccion (TODOS)
/// - SUNAT Boleta: nombre, numeroDocumento (tipoDocumento opcional, default "1", no puede ser "6")
/// - SUNAT Factura: nombre, tipoDocumento="6", numeroDocumento (RUC 11 dígitos)
class ClienteNuevoInput {
  final String nombre;
  final String tipoDocumento;
  final String numeroDocumento;
  final String telefono;
  final String email;
  final String direccion;

  ClienteNuevoInput({
    required this.nombre,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.telefono,
    required this.email,
    required this.direccion,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'nombre': nombre,
    };

    // Solo agregar campos no vacíos
    if (tipoDocumento.isNotEmpty) {
      map['tipo_documento'] = tipoDocumento;
    }

    if (numeroDocumento.isNotEmpty) {
      map['numero_documento'] = numeroDocumento;
    }

    if (telefono.isNotEmpty) {
      map['telefono'] = telefono;
    }

    if (email.isNotEmpty) {
      map['email'] = email;
    }

    if (direccion.isNotEmpty) {
      map['direccion'] = direccion;
    }

    return map;
  }

  ClienteNuevoInput copyWith({
    String? nombre,
    String? tipoDocumento,
    String? numeroDocumento,
    String? telefono,
    String? email,
    String? direccion,
  }) {
    return ClienteNuevoInput(
      nombre: nombre ?? this.nombre,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
    );
  }
}
