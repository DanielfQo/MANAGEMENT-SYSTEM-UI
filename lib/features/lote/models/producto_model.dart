class ProductoModel {
  final int id;
  final String nombre;
  final String codigo;
  final String tipoIgv;
  final String tipoIgvDisplay;
  final String? imagen;
  final bool isActive;

  ProductoModel({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.tipoIgv,
    required this.tipoIgvDisplay,
    this.imagen,
    required this.isActive,
  });

  factory ProductoModel.fromJson(Map<String, dynamic> json) {
    return ProductoModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String,
      tipoIgv: json['tipo_igv'] as String,
      tipoIgvDisplay: json['tipo_igv_display'] as String,
      imagen: json['imagen'] as String?,
      isActive: json['is_active'] as bool,
    );
  }
}
