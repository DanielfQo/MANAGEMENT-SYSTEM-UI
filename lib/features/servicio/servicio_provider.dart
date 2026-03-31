import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/venta/models/cliente_model.dart';
import 'package:management_system_ui/features/venta/constants/tipo_venta.dart';
import 'package:management_system_ui/features/venta/constants/metodo_pago.dart';
import 'package:management_system_ui/features/venta/constants/tipo_comprobante.dart';
import 'package:management_system_ui/features/servicio/models/servicio_create_model.dart';
import 'package:management_system_ui/features/servicio/models/servicio_read_model.dart';
import 'package:management_system_ui/features/servicio/servicio_repository.dart' show ServicioRepository, servicioRepositoryProvider;

// ============================================================================
// SERVICIO FORM STATE (persistencia del formulario paso 0)
// ============================================================================

class ServicioFormState {
  final String descripcion;
  final String fechaInicio;
  final String fechaFin;
  final String total;

  const ServicioFormState({
    this.descripcion = '',
    this.fechaInicio = '',
    this.fechaFin = '',
    this.total = '',
  });

  ServicioFormState copyWith({
    String? descripcion,
    String? fechaInicio,
    String? fechaFin,
    String? total,
  }) {
    return ServicioFormState(
      descripcion: descripcion ?? this.descripcion,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      total: total ?? this.total,
    );
  }
}

class ServicioFormNotifier extends Notifier<ServicioFormState> {
  @override
  ServicioFormState build() => const ServicioFormState();

  void actualizar(ServicioFormState nuevoEstado) {
    state = nuevoEstado;
  }

  void limpiar() {
    state = const ServicioFormState();
  }
}

final servicioFormProvider =
    NotifierProvider<ServicioFormNotifier, ServicioFormState>(
  ServicioFormNotifier.new,
);

// ============================================================================
// SERVICIO STATE & NOTIFIER (estado principal)
// ============================================================================

class ServicioState {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final List<ServicioReadModel> servicios;
  final ServicioReadModel? servicioCreado;

  const ServicioState({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.servicios = const [],
    this.servicioCreado,
  });

  ServicioState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    List<ServicioReadModel>? servicios,
    ServicioReadModel? servicioCreado,
  }) {
    return ServicioState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
      servicios: servicios ?? this.servicios,
      servicioCreado: servicioCreado ?? this.servicioCreado,
    );
  }
}

final servicioProvider =
    NotifierProvider<ServicioNotifier, ServicioState>(ServicioNotifier.new);

class ServicioNotifier extends Notifier<ServicioState> {
  late final ServicioRepository _repository;

  @override
  ServicioState build() {
    _repository = ref.watch(servicioRepositoryProvider);
    return const ServicioState();
  }

  Future<void> cargarServicios({
    String? tipo,
    String? search,
  }) async {
    final tiendaId = ref.read(authProvider).selectedTiendaId;
    if (tiendaId == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final servicios = await _repository.getServicios(
        tiendaId: tiendaId,
        tipo: tipo,
        search: search,
      );
      state = state.copyWith(isLoading: false, servicios: servicios);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> crearServicio(ServicioCreateModel servicio) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final servicioConPdf = await _repository.crearServicio(servicio);

      state = state.copyWith(
        isSaving: false,
        servicioCreado: servicioConPdf.servicio,
        successMessage: 'Servicio registrado exitosamente',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> eliminarServicio(String numeroComprobante) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repository.eliminarServicio(numeroComprobante);
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Servicio eliminado exitosamente',
      );
      await cargarServicios();
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> anularServicio(
    String numeroComprobante, {
    required String motivo,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repository.anularServicio(
        numeroComprobante,
        motivo: motivo,
      );
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Servicio anulado exitosamente',
      );
      await cargarServicios();
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> emitirNotaCredito(
    String numeroComprobante, {
    required String motivo,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repository.emitirNotaCredito(
        numeroComprobante,
        motivo: motivo,
      );
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Nota de crédito emitida exitosamente',
      );
      await cargarServicios();
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString(),
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

// ============================================================================
// RESUMEN SERVICIO STATE (persistencia del paso 1)
// ============================================================================

class ResumenServicioState {
  final String tipoVenta;
  final String metodoPago;
  final String tipoComprobante;
  final String tipoDocumento;
  final bool usarClienteExistente;
  final int? clienteId;
  final ClienteModel? cliente;
  final String nombre;
  final String numeroDocumento;
  final String telefono;
  final String email;
  final String direccion;
  final String telefonoExistente;
  final String emailExistente;
  final String direccionExistente;

  const ResumenServicioState({
    this.tipoVenta = TipoVenta.normal,
    this.metodoPago = MetodoPago.efectivo,
    this.tipoComprobante = TipoComprobante.boleta,
    this.tipoDocumento = '1',
    this.usarClienteExistente = true,
    this.clienteId,
    this.cliente,
    this.nombre = '',
    this.numeroDocumento = '',
    this.telefono = '',
    this.email = '',
    this.direccion = '',
    this.telefonoExistente = '',
    this.emailExistente = '',
    this.direccionExistente = '',
  });

  ResumenServicioState copyWith({
    String? tipoVenta,
    String? metodoPago,
    String? tipoComprobante,
    String? tipoDocumento,
    bool? usarClienteExistente,
    int? clienteId,
    ClienteModel? cliente,
    String? nombre,
    String? numeroDocumento,
    String? telefono,
    String? email,
    String? direccion,
    String? telefonoExistente,
    String? emailExistente,
    String? direccionExistente,
  }) {
    return ResumenServicioState(
      tipoVenta: tipoVenta ?? this.tipoVenta,
      metodoPago: metodoPago ?? this.metodoPago,
      tipoComprobante: tipoComprobante ?? this.tipoComprobante,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      usarClienteExistente: usarClienteExistente ?? this.usarClienteExistente,
      clienteId: clienteId ?? this.clienteId,
      cliente: cliente ?? this.cliente,
      nombre: nombre ?? this.nombre,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      telefonoExistente: telefonoExistente ?? this.telefonoExistente,
      emailExistente: emailExistente ?? this.emailExistente,
      direccionExistente: direccionExistente ?? this.direccionExistente,
    );
  }
}

class ResumenServicioNotifier extends Notifier<ResumenServicioState> {
  @override
  ResumenServicioState build() => const ResumenServicioState();

  void actualizar(ResumenServicioState nuevoEstado) {
    state = nuevoEstado;
  }

  void limpiar() {
    state = const ResumenServicioState();
  }
}

final resumenServicioProvider =
    NotifierProvider<ResumenServicioNotifier, ResumenServicioState>(
  ResumenServicioNotifier.new,
);

// ============================================================================
// TICKET PDF PROVIDER (almacena temporalmente el PDF del ticket generado)
// ============================================================================
