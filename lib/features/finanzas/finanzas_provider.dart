import 'dart:typed_data';
import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'models/caja_resumen_model.dart';
import 'models/deuda_model.dart';
import 'models/gasto_fijo_create_model.dart';
import 'models/gasto_fijo_resumen_model.dart';
import 'models/gasto_tipo_model.dart';
import 'models/gasto_variable_create_model.dart';
import 'models/gasto_variable_resumen_model.dart';
import 'models/pago_model.dart';
import 'finanzas_repository.dart';

// ============================================================================
// PAGO PDF PROVIDER (almacena el PDF del pago registrado)
// ============================================================================

class PagoPdfNotifier extends Notifier<Uint8List?> {
  @override
  Uint8List? build() => null;

  void guardarPagoPdf(Uint8List bytes) {
    state = bytes;
  }

  void limpiar() {
    state = null;
  }
}

final pagoPdfProvider =
    NotifierProvider<PagoPdfNotifier, Uint8List?>(PagoPdfNotifier.new);

// Main notifier for finanzas state
final finanzasProvider = NotifierProvider<FinanzasNotifier, FinanzasState>(
  FinanzasNotifier.new,
);

// State class
class FinanzasState {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  // Caja
  final CajaResumenModel? cajaResumen;
  // Deudas
  final List<DeudaModel> deudas;
  // Pagos
  final List<PagoModel> pagos;
  // Gastos
  final List<GastoTipoModel> tiposGasto;
  final GastoFijoResumenModel? gastosFijosResumen;
  final GastoVariableResumenModel? gastosVariablesResumen;

  FinanzasState({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.cajaResumen,
    this.deudas = const [],
    this.pagos = const [],
    this.tiposGasto = const [],
    this.gastosFijosResumen,
    this.gastosVariablesResumen,
  });

  FinanzasState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    CajaResumenModel? cajaResumen,
    List<DeudaModel>? deudas,
    List<PagoModel>? pagos,
    List<GastoTipoModel>? tiposGasto,
    GastoFijoResumenModel? gastosFijosResumen,
    GastoVariableResumenModel? gastosVariablesResumen,
  }) {
    return FinanzasState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
      cajaResumen: cajaResumen ?? this.cajaResumen,
      deudas: deudas ?? this.deudas,
      pagos: pagos ?? this.pagos,
      tiposGasto: tiposGasto ?? this.tiposGasto,
      gastosFijosResumen: gastosFijosResumen ?? this.gastosFijosResumen,
      gastosVariablesResumen:
          gastosVariablesResumen ?? this.gastosVariablesResumen,
    );
  }
}

// Notifier class
class FinanzasNotifier extends Notifier<FinanzasState> {
  late final FinanzasRepository _repository;

  @override
  FinanzasState build() {
    _repository = ref.watch(finanzasRepositoryProvider);
    return FinanzasState();
  }

  /// Cargar resumen del día de caja
  Future<void> cargarCajaResumen() async {
    final tiendaId = ref.read(authProvider).selectedTiendaId;
    if (tiendaId == null) {
      state = state.copyWith(
        cajaResumen: null,
        errorMessage: 'No hay tienda seleccionada',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final resumen = await _repository.getCajaResumen(tiendaId: tiendaId);
      state = state.copyWith(
        isLoading: false,
        cajaResumen: resumen,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Cerrar caja
  Future<void> cerrarCaja({
    required int tiendaId,
    required String montoReal,
    required String observaciones,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repository.cerrarCaja(
        tiendaId: tiendaId,
        montoReal: montoReal,
        observaciones: observaciones,
      );
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Caja cerrada correctamente',
        errorMessage: null,
      );
      // Recargar resumen
      await cargarCajaResumen();
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Cargar deudas con filtros opcionales
  Future<void> cargarDeudas({
    int? cliente,
    String? estado,
    String? ordering,
    int? servicio,
    int? venta,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final deudas = await _repository.getDeudas(
        cliente: cliente,
        estado: estado,
        ordering: ordering,
        servicio: servicio,
        venta: venta,
      );
      state = state.copyWith(
        isLoading: false,
        deudas: deudas,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Cargar pagos con filtros opcionales
  Future<void> cargarPagos({
    int? deudaCliente,
    String? deudaEstado,
    int? deudaServicio,
    int? deudaVenta,
    String? ordering,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final pagos = await _repository.getPagos(
        deudaCliente: deudaCliente,
        deudaEstado: deudaEstado,
        deudaServicio: deudaServicio,
        deudaVenta: deudaVenta,
        ordering: ordering,
      );
      state = state.copyWith(
        isLoading: false,
        pagos: pagos,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Registrar pago de deuda y obtener comprobante PDF
  Future<Uint8List?> registrarPago({
    required int deudaId,
    required String monto,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final pdfBytes = await _repository.registrarPago(
        deudaId: deudaId,
        monto: monto,
      );

      // Guardar PDF en el provider
      ref.read(pagoPdfProvider.notifier).guardarPagoPdf(pdfBytes);

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Pago registrado correctamente',
        errorMessage: null,
      );
      // Recargar deudas y pagos
      await Future.wait([cargarDeudas(), cargarPagos()]);
      return pdfBytes;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  /// Cargar tipos de gastos disponibles
  Future<void> cargarTiposGasto() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final tipos = await _repository.getTiposGasto();
      state = state.copyWith(
        isLoading: false,
        tiposGasto: tipos,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Cargar resumen de gastos fijos
  Future<void> cargarGastosFijosResumen({
    required int mes,
    required int anio,
  }) async {
    final tiendaId = ref.read(authProvider).selectedTiendaId;
    if (tiendaId == null) {
      state = state.copyWith(
        gastosFijosResumen: null,
        errorMessage: 'No hay tienda seleccionada',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final resumen = await _repository.getGastosFijosResumen(
        tiendaId: tiendaId,
        mes: mes,
        anio: anio,
      );
      state = state.copyWith(
        isLoading: false,
        gastosFijosResumen: resumen,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Crear gasto fijo
  Future<void> crearGastoFijo(GastoFijoCreateModel gasto) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final gastoConTienda = GastoFijoCreateModel(
        tiendaId: gasto.tiendaId,
        tipoGasto: gasto.tipoGasto,
        mes: gasto.mes,
        anio: gasto.anio,
        monto: gasto.monto,
      );
      await _repository.crearGastoFijo(gastoConTienda);
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Gasto fijo registrado correctamente',
        errorMessage: null,
      );
      // Recargar resumen
      await cargarGastosFijosResumen(mes: gasto.mes, anio: gasto.anio);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Cargar resumen de gastos variables
  Future<void> cargarGastosVariablesResumen({
    required int mes,
    required int anio,
  }) async {
    final tiendaId = ref.read(authProvider).selectedTiendaId;
    if (tiendaId == null) {
      state = state.copyWith(
        gastosVariablesResumen: null,
        errorMessage: 'No hay tienda seleccionada',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final resumen = await _repository.getGastosVariablesResumen(
        tiendaId: tiendaId,
        mes: mes,
        anio: anio,
      );
      state = state.copyWith(
        isLoading: false,
        gastosVariablesResumen: resumen,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Crear gasto variable
  Future<void> crearGastoVariable(GastoVariableCreateModel gasto) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repository.crearGastoVariable(gasto);
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Gasto variable registrado correctamente',
        errorMessage: null,
      );
      // Recargar resumen - extraer mes y año de la fecha (YYYY-MM-DD)
      final fecha = gasto.fecha.split('-');
      if (fecha.length == 3) {
        final anio = int.tryParse(fecha[0]) ?? DateTime.now().year;
        final mes = int.tryParse(fecha[1]) ?? DateTime.now().month;
        await cargarGastosVariablesResumen(mes: mes, anio: anio);
      }
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Buscar deudas por número de documento del cliente
  Future<void> buscarDeudasPorDocumento(String numeroDocumento) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final cliente =
          await _repository.buscarClientePorDocumento(numeroDocumento);

      if (cliente == null) {
        state = state.copyWith(
          isLoading: false,
          deudas: [],
          errorMessage: 'Cliente no encontrado',
        );
        return;
      }

      final deudas = await _repository.getDeudas(cliente: cliente.id);
      state = state.copyWith(
        isLoading: false,
        deudas: deudas,
        successMessage: deudas.isEmpty
            ? 'No hay deudas activas para este cliente'
            : 'Deudas cargadas exitosamente',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        deudas: [],
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Buscar deudas por número de comprobante (venta o servicio)
  Future<void> buscarDeudasPorComprobante(String numeroComprobante) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // Buscar en ambos endpoints en paralelo, capturando errores individuales
      final ventaFuture = _repository
          .buscarVentaPorComprobante(numeroComprobante)
          .catchError((e) => null);
      final servicioFuture = _repository
          .buscarServicioPorComprobante(numeroComprobante)
          .catchError((e) => null);

      final venta = await ventaFuture;
      final servicio = await servicioFuture;

      if (venta == null && servicio == null) {
        state = state.copyWith(
          isLoading: false,
          deudas: [],
          errorMessage: 'Comprobante no encontrado',
        );
        return;
      }

      List<DeudaModel> deudas = [];
      if (venta != null) {
        deudas = await _repository.getDeudas(venta: venta.id);
      } else if (servicio != null) {
        deudas = await _repository.getDeudas(servicio: servicio.id);
      }

      state = state.copyWith(
        isLoading: false,
        deudas: deudas,
        successMessage: deudas.isEmpty
            ? 'No hay deudas para este comprobante'
            : 'Deudas cargadas exitosamente',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        deudas: [],
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Cerrar mes de gastos para una tienda
  Future<void> cerrarMesGastos({
    required int mes,
    required int anio,
  }) async {
    final tiendaId = ref.read(authProvider).selectedTiendaId;
    if (tiendaId == null) {
      state = state.copyWith(
        errorMessage: 'No hay tienda seleccionada',
      );
      return;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repository.cerrarMesGastos(
        tiendaId: tiendaId,
        mes: mes,
        anio: anio,
      );
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Mes de gastos cerrado correctamente',
        errorMessage: null,
      );
      // Recargar resúmenes
      await Future.wait([
        cargarGastosFijosResumen(mes: mes, anio: anio),
        cargarGastosVariablesResumen(mes: mes, anio: anio),
      ]);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Limpiar mensajes de estado
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}
