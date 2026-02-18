class AuthResponseModel {
  final String access;
  final String refresh;

  AuthResponseModel({required this.access, required this.refresh});

  // Convierte el JSON de Django a este objeto
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      access: json['access'],
      refresh: json['refresh'],
    );
  }
}