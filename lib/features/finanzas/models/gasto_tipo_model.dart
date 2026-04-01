class GastoTipoModel {
  final String valor;
  final String etiqueta;

  GastoTipoModel({
    required this.valor,
    required this.etiqueta,
  });

  factory GastoTipoModel.fromJson(Map<String, dynamic> json) {
    return GastoTipoModel(
      valor: json['valor'] ?? '',
      etiqueta: json['etiqueta'] ?? '',
    );
  }
}
