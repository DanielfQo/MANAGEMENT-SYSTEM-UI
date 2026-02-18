import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/storage_service.dart';
import 'auth_repository.dart';
import 'models/auth_response_model.dart';


class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final AuthResponseModel? authData; // Guardamos el modelo aquí

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.authData,
  });

  bool get isAuthenticated => authData != null;

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    AuthResponseModel? authData,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      authData: authData ?? this.authData,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {

  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    return const AuthState();
  }

  Future<void> login(String username, String password) async {
  state = state.copyWith(isLoading: true, errorMessage: null);

  try {
    
    final authResponse = await _repository.login(username, password);

    await StorageService.saveToken(authResponse.access);

    state = state.copyWith(
      isLoading: false,
      authData: authResponse,
    );
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      errorMessage: e.toString().replaceFirst('Exception: ', ''),
    );
  }
}
}


final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
