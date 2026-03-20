import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/auth/auth_repository.dart';
import 'profile_repository.dart';

class ProfileState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const ProfileState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  late final ProfileRepository _repository;
  late final AuthRepository _authRepository;

  @override
  ProfileState build() {
    _repository = ref.watch(profileRepositoryProvider);
    _authRepository = ref.watch(authRepositoryProvider);
    return const ProfileState();
  }

  Future<void> completarPerfil({
    required String firstName,
    required String lastName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _repository.completarPerfil(
        firstName: firstName,
        lastName: lastName,
      );

      final updatedUser = await _authRepository.getMe();
      ref.read(authProvider.notifier).updateUserMe(updatedUser);

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final profileProvider =
    NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);