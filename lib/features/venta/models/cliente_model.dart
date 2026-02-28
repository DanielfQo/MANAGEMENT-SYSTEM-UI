class ClienteModel {
  final int id;
  final String nombre;
  final String telefono;
  final String email;
  final String saldoTotal;

  ClienteModel({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.email,
    required this.saldoTotal,
  });

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    return ClienteModel(
      id: json['id'],
      nombre: json['nombre'],
      telefono: json['telefono'],
      email: json['email'],
      saldoTotal: json['saldo_total'],
    );
  }
}
