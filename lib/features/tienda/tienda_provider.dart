import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'tienda_repository.dart';

class TiendaState {
  final bool isLoading;
  final String? errorMessage;
  final List<StoreModel> tiendas;
  final bool isSuccess;

  const TiendaState({
    this.isLoading = false,
    this.errorMessage,
    this.tiendas = const [],
    this.isSuccess = false,
  });

  TiendaState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<StoreModel>? tiendas,
    bool? isSuccess,
  }) {
    return TiendaState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      tiendas: tiendas ?? this.tiendas,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class TiendaNotifier extends Notifier<TiendaState> {
  late final TiendaRepository _repository;

  @override
  TiendaState build() {
    _repository = ref.watch(tiendaRepositoryProvider);
    return const TiendaState();
  }

  Future<void> cargarTiendas() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final tiendas = await _repository.getTiendas();
      state = state.copyWith(isLoading: false, tiendas: tiendas);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> actualizarTienda({
    required int id,
    required String nombreSede,
    required String direccion,
    required String ubigeo,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      final updated = await _repository.actualizarTienda(
        id: id,
        nombreSede: nombreSede,
        direccion: direccion,
        ubigeo: ubigeo,
      );
      final nuevaLista = state.tiendas
          .map((t) => t.id == id ? updated : t)
          .toList();
      state = state.copyWith(
        isLoading: false,
        tiendas: nuevaLista,
        isSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> desactivarTienda(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.desactivarTienda(id);
      final nuevaLista = state.tiendas.where((t) => t.id != id).toList();
      state = state.copyWith(isLoading: false, tiendas: nuevaLista);

      final selectedId = ref.read(authProvider).selectedTiendaId;
      if (selectedId == id) {
        await ref.read(authProvider.notifier).selectTienda(
          nuevaLista.isNotEmpty ? nuevaLista.first.id : 0,
        );
      }
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
    required int empresaId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      final nueva = await _repository.crearTienda(
        nombreSede: nombreSede,
        direccion: direccion,
        ubigeo: ubigeo,
        serieFactura: serieFactura,
        serieBoleta: serieBoleta,
        serieTicket: serieTicket,
        empresaId: empresaId,
      );
      state = state.copyWith(
        isLoading: false,
        tiendas: [...state.tiendas, nueva],
        isSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void resetSuccess() => state = state.copyWith(isSuccess: false);
  void resetError() => state = state.copyWith(errorMessage: null);
}

final tiendaProvider =
    NotifierProvider<TiendaNotifier, TiendaState>(TiendaNotifier.new);

final tiendaActivaProvider = Provider<StoreModel?>((ref) {
  final selectedId = ref.watch(authProvider).selectedTiendaId;
  final tiendas = ref.watch(tiendaProvider).tiendas;
  if (selectedId == null || tiendas.isEmpty) return null;
  try {
    return tiendas.firstWhere((t) => t.id == selectedId);
  } catch (_) {
    return tiendas.isNotEmpty ? tiendas.first : null;
  }
});