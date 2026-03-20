class EmpresaModel {
  final int id;
  final String ruc;
  final String razonSocial;
  final String nombreComercial;

  EmpresaModel({
    required this.id,
    required this.ruc,
    required this.razonSocial,
    required this.nombreComercial,
  });

  factory EmpresaModel.fromJson(Map<String, dynamic> json) {
    return EmpresaModel(
      id: json['id'],
      ruc: json['ruc'],
      razonSocial: json['razon_social'],
      nombreComercial: json['nombre_comercial'],
    );
  }
}