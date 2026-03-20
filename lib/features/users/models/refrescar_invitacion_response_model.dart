class RefrescarInvitacionResponse {
  final String token;
  final String usuario;
  final String expiracion;

  RefrescarInvitacionResponse({
    required this.token,
    required this.usuario,
    required this.expiracion,
  });

  factory RefrescarInvitacionResponse.fromJson(Map<String, dynamic> json) {
    return RefrescarInvitacionResponse(
      token: json['token'],
      usuario: json['usuario'],
      expiracion: json['expiracion'],
    );
  }
}