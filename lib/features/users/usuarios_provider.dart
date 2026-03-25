import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'usuarios_repository.dart';

class UsuariosState {
  final bool isLoading;
  final String? errorMessage;
  final List<UsuarioTiendaModel> usuarios;
  final int? tiendaSeleccionadaId;
  final String? rolSeleccionado;
  final bool isRefreshing;
  final bool isEditing;
  final String? invitationLink;

  const UsuariosState({
    this.isLoading = false,
    this.errorMessage,
    this.usuarios = const [],
    this.tiendaSeleccionadaId,
    this.rolSeleccionado,
    this.isRefreshing = false,
    this.isEditing = false,
    this.invitationLink,
  });

  UsuariosState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<UsuarioTiendaModel>? usuarios,
    int? tiendaSeleccionadaId,
    String? rolSeleccionado,
    bool? isRefreshing,
    bool? isEditing,
    String? invitationLink,
    bool clearInvitationLink = false,
    bool clearRol = false,
  }) {
    return UsuariosState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      usuarios: usuarios ?? this.usuarios,
      tiendaSeleccionadaId:
          tiendaSeleccionadaId ?? this.tiendaSeleccionadaId,
      rolSeleccionado:
          clearRol ? null : (rolSeleccionado ?? this.rolSeleccionado),
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isEditing: isEditing ?? this.isEditing,
      invitationLink: clearInvitationLink
          ? null
          : (invitationLink ?? this.invitationLink),
    );
  }
}

class UsuariosNotifier extends Notifier<UsuariosState> {
  late final UsuariosRepository _repository;

  @override
  UsuariosState build() {
    _repository = ref.watch(usuariosRepositoryProvider);
    final tiendaId = ref.read(authProvider).selectedTiendaId;

    // Escuchar cambios en selectedTiendaId para recargar usuarios
    ref.listen(
      authProvider.select((auth) => auth.selectedTiendaId),
      (previous, next) {
        if (previous != null && next != previous) {
          cargarUsuarios();
        }
      },
    );

    Future.microtask(() => cargarUsuarios());
    return UsuariosState(tiendaSeleccionadaId: tiendaId);
  }

  Future<void> cargarUsuarios({String? rol}) async {
    final tiendaId = ref.read(authProvider).selectedTiendaId;
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      tiendaSeleccionadaId: tiendaId,
    );
    try {
      final usuarios = await _repository.getUsuarios(
        tiendaId: tiendaId,
        rol: rol ?? state.rolSeleccionado,
      );
      state = state.copyWith(isLoading: false, usuarios: usuarios);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void seleccionarRol(String? rol) {
    state = rol == null
        ? state.copyWith(clearRol: true)
        : state.copyWith(rolSeleccionado: rol);
    cargarUsuarios(rol: rol);
  }

  Future<void> editarUsuario({
    required int id,
    int? tiendaId,
    String? rol,
    String? salario,
  }) async {
    state = state.copyWith(isEditing: true, errorMessage: null);
    try {
      final actualizado = await _repository.editarUsuario(
        id: id,
        tiendaId: tiendaId,
        rol: rol,
        salario: salario,
      );
      final nuevaLista = state.usuarios
          .map((u) => u.id == id ? actualizado : u)
          .toList();
      state = state.copyWith(isEditing: false, usuarios: nuevaLista);
    } catch (e) {
      state = state.copyWith(
        isEditing: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> toggleEstado(int id) async {
    state = state.copyWith(isEditing: true, errorMessage: null);
    try {
      final actualizado = await _repository.toggleEstado(id);
      final nuevaLista = state.usuarios
          .map((u) => u.id == id ? actualizado : u)
          .toList();
      state = state.copyWith(isEditing: false, usuarios: nuevaLista);
    } catch (e) {
      state = state.copyWith(
        isEditing: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> refrescarInvitacion(int usuarioId) async {
    state = state.copyWith(
        isRefreshing: true, errorMessage: null, invitationLink: null);
    try {
      final response = await _repository.refrescarInvitacion(usuarioId);
      final link = '${AppConstants.inviteBaseUrl}?token=${response.token}';
      state = state.copyWith(isRefreshing: false, invitationLink: link);
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clearInvitationLink() {
    state = state.copyWith(clearInvitationLink: true);
  }
}

final usuariosProvider =
    NotifierProvider<UsuariosNotifier, UsuariosState>(UsuariosNotifier.new);