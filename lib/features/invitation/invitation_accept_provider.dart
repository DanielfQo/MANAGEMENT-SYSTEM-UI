import 'package:management_system_ui/core/common_libs.dart';
import 'invitation_accept_repository.dart';

// ─── Estado ──────────────────────────────────────────────────────────────────

enum InvitationAcceptStatus {
  validating, // validando token al entrar a la pantalla
  valid,      // token válido, mostrar formulario
  expired,    // token expirado o inválido
  loading,    // enviando contraseña
  success,    // registro completado
}

class InvitationAcceptState {
  final InvitationAcceptStatus status;
  final String? username;
  final String? errorMessage;

  const InvitationAcceptState({
    this.status = InvitationAcceptStatus.validating,
    this.username,
    this.errorMessage,
  });

  InvitationAcceptState copyWith({
    InvitationAcceptStatus? status,
    String? username,
    String? errorMessage,
  }) {
    return InvitationAcceptState(
      status: status ?? this.status,
      username: username ?? this.username,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class InvitationAcceptNotifier extends Notifier<InvitationAcceptState> {
  late final InvitationAcceptRepository _repository;

  @override
  InvitationAcceptState build() {
    _repository = ref.watch(invitationAcceptRepositoryProvider);
    return const InvitationAcceptState(
      status: InvitationAcceptStatus.validating,
    );
  }

  Future<void> validarToken(String? token) async {
    if (token == null) {
      state = state.copyWith(status: InvitationAcceptStatus.expired);
      return;
    }

    state = state.copyWith(status: InvitationAcceptStatus.validating);

    try {
      final response = await _repository.validarToken(token);
      state = state.copyWith(
        status: InvitationAcceptStatus.valid,
        username: response.usuario,
      );
    } catch (e) {
      state = state.copyWith(
        status: InvitationAcceptStatus.expired,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> completarRegistro({
    required String token,
    required String password,
    required String confirmarPassword,
  }) async {
    state = state.copyWith(
      status: InvitationAcceptStatus.loading,
      errorMessage: null,
    );

    try {
      await _repository.completarInvitacion(
        token: token,
        password: password,
        confirmarPassword: confirmarPassword,
      );
      state = state.copyWith(status: InvitationAcceptStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: InvitationAcceptStatus.valid,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final invitationAcceptProvider =
    NotifierProvider<InvitationAcceptNotifier, InvitationAcceptState>(
  InvitationAcceptNotifier.new,
);