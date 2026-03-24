class StoreModel {
  final int id;
  final String nombreSede;
  final String direccion;
  final String ubigeo;
  final String serieFactura;
  final String serieBoleta;
  final String serieTicket;
  final DateTime? createdAt;

  StoreModel({
    required this.id,
    required this.nombreSede,
    required this.direccion,
    required this.ubigeo,
    required this.serieFactura,
    required this.serieBoleta,
    required this.serieTicket,
    this.createdAt,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'],
      nombreSede: json['nombre_sede'],
      direccion: json['direccion'],
      ubigeo: json['ubigeo'],
      serieFactura: json['serie_factura'] ?? '',
      serieBoleta: json['serie_boleta'] ?? '',
      serieTicket: json['serie_ticket'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  factory StoreModel.fromUserTienda(dynamic userTienda) {
    return StoreModel(
      id: userTienda.tiendaId,
      nombreSede: userTienda.tiendaNombre,
      direccion: '',
      ubigeo: '',
      serieFactura: '',
      serieBoleta: '',
      serieTicket: '',
    );
  }

  StoreModel copyWith({
    String? nombreSede,
    String? direccion,
    String? ubigeo,
  }) {
    return StoreModel(
      id: id,
      nombreSede: nombreSede ?? this.nombreSede,
      direccion: direccion ?? this.direccion,
      ubigeo: ubigeo ?? this.ubigeo,
      serieFactura: serieFactura,
      serieBoleta: serieBoleta,
      serieTicket: serieTicket,
      createdAt: createdAt,
    );
  }
}