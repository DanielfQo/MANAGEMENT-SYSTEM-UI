class StoreModel {
  final int id;
  final String nombreSede;
  final String direccion;
  final String ubigeo;

  StoreModel({
    required this.id,
    required this.nombreSede,
    required this.direccion,
    required this.ubigeo,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'],
      nombreSede: json['nombre_sede'],
      direccion: json['direccion'],
      ubigeo: json['ubigeo'],
    );
  }
}