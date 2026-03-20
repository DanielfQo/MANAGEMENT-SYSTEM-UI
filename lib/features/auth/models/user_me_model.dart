import 'package:management_system_ui/core/constants/constants.dart';

class UserMeModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? rol;
  final List<UserTiendaModel> tiendas;

  UserMeModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.rol,
    required this.tiendas,
  });

  bool get isProfileIncomplete =>
      firstName.trim().isEmpty || lastName.trim().isEmpty;
  
  bool get isDueno => rol == Roles.dueno;

  factory UserMeModel.fromJson(Map<String, dynamic> json) {
    return UserMeModel(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      rol: json['rol'],
      tiendas: (json['tiendas'] as List)
          .map((e) => UserTiendaModel.fromJson(e))
          .toList(),
    );
  }
}

class UserTiendaModel {
  final int tiendaId;
  final String tiendaNombre;

  UserTiendaModel({
    required this.tiendaId,
    required this.tiendaNombre,
  });

  factory UserTiendaModel.fromJson(Map<String, dynamic> json) {
    return UserTiendaModel(
      tiendaId: json['tienda_id'],
      tiendaNombre: json['tienda_nombre'],
    );
  }
}