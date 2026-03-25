import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/core/network/auth_events.dart';
import 'auth_repository.dart';
import 'models/auth_response_model.dart';
import 'models/user_me_model.dart';


class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final AuthResponseModel? authData; // Guardamos el modelo aquí
  final UserMeModel? userMe;
  final int? selectedTiendaId;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.authData,
    this.userMe,
    this.selectedTiendaId,
  });

  bool get isAuthenticated => authData != null;

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    AuthResponseModel? authData,
    UserMeModel? userMe,
    int? selectedTiendaId,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      authData: authData ?? this.authData,
      userMe: userMe ?? this.userMe,
      selectedTiendaId: selectedTiendaId ?? this.selectedTiendaId,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {

  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    final sub = authEventController.stream.listen((event) {
      if (event == AuthEvent.logout) {
        state = const AuthState();
      }
    });
    ref.onDispose(() => sub.cancel());
    return const AuthState();
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {

      final authResponse = await _repository.login(username, password);

      final userData = await _repository.getMe();

      int? tiendaActivac;

      if (userData.tiendas.isNotEmpty) {
        // Intentar cargar la última tienda usada
        final lastTiendaId = await StorageService.getLastTiendaId();
        final tiendaExiste = userData.tiendas.any((t) => t.tiendaId == lastTiendaId);

        tiendaActivac = tiendaExiste ? lastTiendaId : userData.tiendas.first.tiendaId;
      }

      state = state.copyWith(
        isLoading: false,
        authData: authResponse,
        userMe: userData,
        selectedTiendaId: tiendaActivac,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await StorageService.clearToken();
    state = const AuthState();
  }

  Future<void> selectTienda(int tiendaId) async {
    await StorageService.setLastTiendaId(tiendaId);
    state = state.copyWith(selectedTiendaId: tiendaId);
  }

  void updateUserMe(UserMeModel userMe) {
    state = state.copyWith(userMe: userMe);
  }
}


final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
