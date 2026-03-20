import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/auth/auth_repository.dart';
import 'setup_repository.dart';

enum SetupStep { empresa, tienda }

class SetupState {
  final bool isLoading;
  final String? errorMessage;
  final SetupStep currentStep;
  final EmpresaModel? empresaCreada;
  final bool isSuccess;

  const SetupState({
    this.isLoading = false,
    this.errorMessage,
    this.currentStep = SetupStep.empresa,
    this.empresaCreada,
    this.isSuccess = false,
  });

  SetupState copyWith({
    bool? isLoading,
    String? errorMessage,
    SetupStep? currentStep,
    EmpresaModel? empresaCreada,
    bool? isSuccess,
  }) {
    return SetupState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      currentStep: currentStep ?? this.currentStep,
      empresaCreada: empresaCreada ?? this.empresaCreada,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class SetupNotifier extends Notifier<SetupState> {
  late final SetupRepository _repository;
  late final AuthRepository _authRepository;

  @override
  SetupState build() {
    _repository = ref.watch(setupRepositoryProvider);
    _authRepository = ref.watch(authRepositoryProvider);
    return const SetupState();
  }

  Future<void> crearEmpresa({
    required String ruc,
    required String razonSocial,
    required String nombreComercial,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final empresa = await _repository.crearEmpresa(
        ruc: ruc,
        razonSocial: razonSocial,
        nombreComercial: nombreComercial,
      );

      state = state.copyWith(
        isLoading: false,
        empresaCreada: empresa,
        currentStep: SetupStep.tienda,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> crearTienda({
    required String nombreSede,
    required String direccion,
    required String ubigeo,
    required String serieFactura,
    required String serieBoleta,
    required String serieTicket,
  }) async {
    if (state.empresaCreada == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _repository.crearTienda(
        nombreSede: nombreSede,
        direccion: direccion,
        ubigeo: ubigeo,
        serieFactura: serieFactura,
        serieBoleta: serieBoleta,
        serieTicket: serieTicket,
        empresaId: state.empresaCreada!.id,
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
  void volverAEmpresa() {
    state = state.copyWith(
      currentStep: SetupStep.empresa,
      errorMessage: null,
    );
  }
  void avanzarATienda() {
    state = state.copyWith(
      currentStep: SetupStep.tienda,
      errorMessage: null,
    );
  }
}

final setupProvider =
    NotifierProvider<SetupNotifier, SetupState>(SetupNotifier.new);