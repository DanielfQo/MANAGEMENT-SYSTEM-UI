class UsuarioTiendaModel {
  final int id;
  final int usuarioId;
  final String usuarioNombre;
  final bool usuarioIsActive;
  final int tiendaId;
  final String tiendaNombre;
  final String rol;
  final String rolDisplay;
  final String salario;

  UsuarioTiendaModel({
    required this.id,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.usuarioIsActive,
    required this.tiendaId,
    required this.tiendaNombre,
    required this.rol,
    required this.rolDisplay,
    required this.salario,
  });

  factory UsuarioTiendaModel.fromJson(Map<String, dynamic> json) {
    return UsuarioTiendaModel(
      id: json['id'],
      usuarioId: json['usuario_id'],
      usuarioNombre: json['usuario_nombre'],
      usuarioIsActive: json['usuario_is_active'],
      tiendaId: json['tienda_id'],
      tiendaNombre: json['tienda_nombre'],
      rol: json['rol'],
      rolDisplay: json['rol_display'],
      salario: json['salario'],
    );
  }
}