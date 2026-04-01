class GastoVariableResumenModel {
  final String tienda;
  final String totalMes;
  final bool mesCerrado;

  GastoVariableResumenModel({
    required this.tienda,
    required this.totalMes,
    this.mesCerrado = false,
  });

  factory GastoVariableResumenModel.fromJson(Map<String, dynamic> json) {
    return GastoVariableResumenModel(
      tienda: json['tienda'] ?? '',
      totalMes: json['total_mes']?.toString() ?? '0',
      mesCerrado: json['mes_cerrado'] ?? false,
    );
  }
}
