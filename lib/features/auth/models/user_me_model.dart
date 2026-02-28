class UserMeModel {
  final int id;
  final String username;
  final String email;
  final List<UserTiendaModel> tiendas;

  UserMeModel({
    required this.id,
    required this.username,
    required this.email,
    required this.tiendas,
  });

  factory UserMeModel.fromJson(Map<String, dynamic> json) {
    return UserMeModel(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      tiendas: (json['tiendas'] as List)
          .map((e) => UserTiendaModel.fromJson(e))
          .toList(),
    );  
  }
}

class UserTiendaModel {
  final int tiendaId;
  final String tiendaNombre;
  final String rol;

  UserTiendaModel({
    required this.tiendaId,
    required this.tiendaNombre,
    required this.rol,
  });

  factory UserTiendaModel.fromJson(Map<String, dynamic> json) {
    return UserTiendaModel(
      tiendaId: json['tienda_id'],
      tiendaNombre: json['tienda_nombre'],
      rol: json['rol'],
    );
  }
}
