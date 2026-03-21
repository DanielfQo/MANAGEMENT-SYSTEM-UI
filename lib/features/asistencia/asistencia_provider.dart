import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/users/usuarios_repository.dart';
import 'asistencia_repository.dart';

// ─── Combina usuario con su asistencia del día ────────────────────────────────

class UsuarioConAsistencia {
  final UsuarioTiendaModel usuario;
  final AsistenciaModel? asistencia;

  const UsuarioConAsistencia({
    required this.usuario,
    this.asistencia,
  });

  bool get tieneEntrada => asistencia?.horaEntrada != null;
  bool get tieneSalida => asistencia?.horaSalida != null;
  bool get completo => tieneEntrada && tieneSalida;
}

// ─── Estado ──────────────────────────────────────────────────────────────────

class AsistenciaState {
  final bool isLoading;
  final bool isMarking;
  final bool isLoadingResumen;
  final String? errorMessage;
  final String? successMessage;

  final List<UsuarioConAsistencia> usuariosHoy;
  final List<AsistenciaResumenModel> resumen;

  final int? tiendaSeleccionadaId;
  final int mesResumen;
  final int anioResumen;

  const AsistenciaState({
    this.isLoading = false,
    this.isMarking = false,
    this.isLoadingResumen = false,
    this.errorMessage,
    this.successMessage,
    this.usuariosHoy = const [],
    this.resumen = const [],
    this.tiendaSeleccionadaId,
    required this.mesResumen,
    required this.anioResumen,
  });

  AsistenciaState copyWith({
    bool? isLoading,
    bool? isMarking,
    bool? isLoadingResumen,
    String? errorMessage,
    String? successMessage,
    List<UsuarioConAsistencia>? usuariosHoy,
    List<AsistenciaResumenModel>? resumen,
    int? tiendaSeleccionadaId,
    int? mesResumen,
    int? anioResumen,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AsistenciaState(
      isLoading: isLoading ?? this.isLoading,
      isMarking: isMarking ?? this.isMarking,
      isLoadingResumen: isLoadingResumen ?? this.isLoadingResumen,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      usuariosHoy: usuariosHoy ?? this.usuariosHoy,
      resumen: resumen ?? this.resumen,
      tiendaSeleccionadaId:
          tiendaSeleccionadaId ?? this.tiendaSeleccionadaId,
      mesResumen: mesResumen ?? this.mesResumen,
      anioResumen: anioResumen ?? this.anioResumen,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class AsistenciaNotifier extends Notifier<AsistenciaState> {
  late final AsistenciaRepository _repository;
  late final UsuariosRepository _usuariosRepository;

  @override
  AsistenciaState build() {
    _repository = ref.watch(asistenciaRepositoryProvider);
    _usuariosRepository = ref.watch(usuariosRepositoryProvider);

    final now = DateTime.now();
    final tiendaId = ref.read(authProvider).selectedTiendaId;

    Future.microtask(() => cargarAsistenciasHoy(tiendaId: tiendaId));

    return AsistenciaState(
      tiendaSeleccionadaId: tiendaId,
      mesResumen: now.month,
      anioResumen: now.year,
    );
  }

  String _fechaHoy() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> cargarAsistenciasHoy({int? tiendaId}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      tiendaSeleccionadaId: tiendaId,
    );

    try {
      final usuarios = await _usuariosRepository.getUsuarios(tiendaId: tiendaId);
      final asistencias = await _repository.getAsistencias(fecha: _fechaHoy());

      final usuariosHoy = usuarios
          .where((u) => u.usuarioIsActive && u.rol != Roles.dueno)
          .map((u) {
            final asistencia = asistencias
                .where((a) => a.usuarioTienda == u.id)
                .firstOrNull;
            return UsuarioConAsistencia(usuario: u, asistencia: asistencia);
          })
          .toList();

      state = state.copyWith(isLoading: false, usuariosHoy: usuariosHoy);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> cargarResumen({int? mes, int? anio, int? tiendaId}) async {
    final mesActual = mes ?? state.mesResumen;
    final anioActual = anio ?? state.anioResumen;

    state = state.copyWith(
      isLoadingResumen: true,
      clearError: true,
      mesResumen: mesActual,
      anioResumen: anioActual,
    );

    try {
      final resumen = await _repository.getResumen(
        mes: mesActual,
        anio: anioActual,
      );
      state = state.copyWith(isLoadingResumen: false, resumen: resumen);
    } catch (e) {
      state = state.copyWith(
        isLoadingResumen: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void seleccionarTienda(int? tiendaId) {
    cargarAsistenciasHoy(tiendaId: tiendaId);
    cargarResumen(tiendaId: tiendaId);
  }

  Future<void> marcarEntrada(int usuarioTiendaId) async {
    state = state.copyWith(isMarking: true, clearError: true);
    try {
      await _repository.marcarEntrada(usuarioTiendaId);
      state = state.copyWith(
          isMarking: false, successMessage: 'Entrada registrada');
      try {
        await cargarAsistenciasHoy(tiendaId: state.tiendaSeleccionadaId);
      } catch (_) {}
    } catch (e) {
      state = state.copyWith(
        isMarking: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> marcarSalida({
    required int usuarioTiendaId,
    required bool almuerzo,
  }) async {
    state = state.copyWith(isMarking: true, clearError: true);
    try {
      await _repository.marcarSalida(
          usuarioTiendaId: usuarioTiendaId, almuerzo: almuerzo);
      state = state.copyWith(
          isMarking: false, successMessage: 'Salida registrada');
      try {
        await cargarAsistenciasHoy(tiendaId: state.tiendaSeleccionadaId);
      } catch (_) {}
    } catch (e) {
      state = state.copyWith(
        isMarking: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final asistenciaProvider =
    NotifierProvider<AsistenciaNotifier, AsistenciaState>(
        AsistenciaNotifier.new);