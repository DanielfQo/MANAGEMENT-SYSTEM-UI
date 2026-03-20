class InvitationResponseModel {
  final String mensaje;
  final String token;
  final String expiracion;

  InvitationResponseModel({
    required this.mensaje,
    required this.token,
    required this.expiracion,
  });

  factory InvitationResponseModel.fromJson(Map<String, dynamic> json) {
    return InvitationResponseModel(
      mensaje: json['mensaje'],
      token: json['token'],
      expiracion: json['expiracion'],
    );
  }
}