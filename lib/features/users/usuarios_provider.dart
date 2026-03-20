import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/core/constants/constants.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/invitation/models/store_model.dart';
import 'package:management_system_ui/features/invitation/invitation_repository.dart';
import 'usuarios_repository.dart';


class UsuariosState {
  final bool isLoading;
  final String? errorMessage;
  final List<UsuarioTiendaModel> usuarios;
  final int? tiendaSeleccionadaId;

  final bool isRefreshing;
  final String? invitationLink;

  const UsuariosState({
    this.isLoading = false,
    this.errorMessage,
    this.usuarios = const [],
    this.tiendaSeleccionadaId,
    this.isRefreshing = false,
    this.invitationLink,
  });

  UsuariosState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<UsuarioTiendaModel>? usuarios,
    int? tiendaSeleccionadaId,
    bool? isRefreshing,
    String? invitationLink,
  }) {
    return UsuariosState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      usuarios: usuarios ?? this.usuarios,
      tiendaSeleccionadaId:
          tiendaSeleccionadaId ?? this.tiendaSeleccionadaId,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      invitationLink: invitationLink ?? this.invitationLink,
    );
  }
}

class UsuariosNotifier extends Notifier<UsuariosState> {
  late final UsuariosRepository _repository;

  @override
  UsuariosState build() {
    _repository = ref.watch(usuariosRepositoryProvider);

    final tiendaId = ref.read(authProvider).selectedTiendaId;
    Future.microtask(() => cargarUsuarios(tiendaId: tiendaId));

    return UsuariosState(tiendaSeleccionadaId: tiendaId);
  }

  Future<void> cargarUsuarios({int? tiendaId}) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      tiendaSeleccionadaId: tiendaId,
    );

    try {
      final usuarios = await _repository.getUsuarios(tiendaId: tiendaId);
      state = state.copyWith(isLoading: false, usuarios: usuarios);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void seleccionarTienda(int? tiendaId) {
    cargarUsuarios(tiendaId: tiendaId);
  }

  Future<void> refrescarInvitacion(int usuarioId) async {
    state = state.copyWith(isRefreshing: true, errorMessage: null, invitationLink: null);

    try {
      final response = await _repository.refrescarInvitacion(usuarioId);
      final link = '${AppConstants.inviteBaseUrl}?token=${response.token}';

      state = state.copyWith(
        isRefreshing: false,
        invitationLink: link,
      );
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clearInvitationLink() {
    state = state.copyWith(invitationLink: null);
  }
}

final usuariosProvider =
    NotifierProvider<UsuariosNotifier, UsuariosState>(UsuariosNotifier.new);