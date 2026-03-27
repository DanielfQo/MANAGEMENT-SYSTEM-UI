/// Configuración de qué campos son requeridos para cada tipo de venta
class ClienteFormConfig {
  /// Define qué campos de cliente son requeridos según el tipo de venta
  static ClienteFieldsConfig getConfig(String tipoVenta) {
    switch (tipoVenta.toUpperCase()) {
      case 'NORMAL':
        return ClienteFieldsConfig(
          nombre: true,
          tipoDocumento: false,
          numeroDocumento: false,
          telefono: false,
          email: false,
          direccion: false,
        );

      case 'CREDITO':
        return ClienteFieldsConfig(
          nombre: true,
          tipoDocumento: true,
          numeroDocumento: true,
          telefono: true,
          email: true,
          direccion: true,
        );

      case 'SUNAT':
        // Será reemplazado por sunat-boleta o sunat-factura
        return ClienteFieldsConfig(
          nombre: true,
          tipoDocumento: false,
          numeroDocumento: false,
          telefono: false,
          email: false,
          direccion: false,
        );

      case 'SUNAT_BOLETA':
        return ClienteFieldsConfig(
          nombre: true,
          tipoDocumento: false, // opcional, default "1"
          numeroDocumento: true,
          telefono: false,
          email: false,
          direccion: false,
        );

      case 'SUNAT_FACTURA':
        return ClienteFieldsConfig(
          nombre: true,
          tipoDocumento: true, // debe ser "6"
          numeroDocumento: true, // RUC de 11 dígitos
          telefono: false,
          email: false,
          direccion: false,
        );

      default:
        return ClienteFieldsConfig(
          nombre: true,
          tipoDocumento: false,
          numeroDocumento: false,
          telefono: false,
          email: false,
          direccion: false,
        );
    }
  }

  /// Retorna si el cliente es opcional para este tipo de venta
  static bool esClienteOpcional(String tipoVenta) {
    switch (tipoVenta.toUpperCase()) {
      case 'NORMAL':
      case 'SUNAT_BOLETA':
        return true;

      case 'CREDITO':
      case 'SUNAT_FACTURA':
        return false;

      default:
        return true;
    }
  }

  /// Retorna el tipo de comprobante requerido para SUNAT
  static String? getComprobanteRequerido(String tipoVenta) {
    if (tipoVenta.toUpperCase() == 'SUNAT') {
      return null; // Requiere especificar en el formulario
    }
    return null;
  }
}

/// Configuración de campos para cliente nuevo
class ClienteFieldsConfig {
  final bool nombre;
  final bool tipoDocumento;
  final bool numeroDocumento;
  final bool telefono;
  final bool email;
  final bool direccion;

  ClienteFieldsConfig({
    required this.nombre,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.telefono,
    required this.email,
    required this.direccion,
  });

  /// Retorna lista de campos requeridos
  List<String> get camposRequeridos {
    final campos = <String>[];
    if (nombre) campos.add('nombre');
    if (tipoDocumento) campos.add('tipo_documento');
    if (numeroDocumento) campos.add('numero_documento');
    if (telefono) campos.add('telefono');
    if (email) campos.add('email');
    if (direccion) campos.add('direccion');
    return campos;
  }

  /// Verifica si un campo es requerido
  bool esRequerido(String campo) {
    switch (campo) {
      case 'nombre':
        return nombre;
      case 'tipo_documento':
        return tipoDocumento;
      case 'numero_documento':
        return numeroDocumento;
      case 'telefono':
        return telefono;
      case 'email':
        return email;
      case 'direccion':
        return direccion;
      default:
        return false;
    }
  }
}
