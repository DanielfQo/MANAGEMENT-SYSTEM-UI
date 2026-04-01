import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/core/router.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'finanzas_provider.dart';
import 'models/gasto_fijo_create_model.dart';
import 'models/gasto_fijo_resumen_model.dart';
import 'models/gasto_variable_create_model.dart';
import 'models/gasto_variable_resumen_model.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────

const _meses = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

IconData _iconForTipo(String tipo) {
  switch (tipo.toUpperCase()) {
    case 'ALQUILER':
      return Icons.home_outlined;
    case 'AGUA':
      return Icons.water_drop_outlined;
    case 'LUZ':
    case 'ELECTRICIDAD':
      return Icons.bolt_outlined;
    case 'INTERNET':
      return Icons.wifi_outlined;
    case 'TELEFONO':
    case 'TELÉFONO':
      return Icons.phone_outlined;
    case 'LIMPIEZA':
      return Icons.cleaning_services_outlined;
    case 'SEGURIDAD':
      return Icons.security_outlined;
    case 'MANTENIMIENTO':
      return Icons.build_outlined;
    case 'PUBLICIDAD':
      return Icons.campaign_outlined;
    default:
      return Icons.receipt_long_outlined;
  }
}

Color _colorForTipo(String tipo) {
  switch (tipo.toUpperCase()) {
    case 'ALQUILER':
      return Colors.indigo;
    case 'AGUA':
      return Colors.blue;
    case 'LUZ':
    case 'ELECTRICIDAD':
      return Colors.amber[700]!;
    case 'INTERNET':
      return Colors.teal;
    case 'TELEFONO':
    case 'TELÉFONO':
      return Colors.green;
    case 'LIMPIEZA':
      return Colors.cyan;
    case 'SEGURIDAD':
      return Colors.red;
    case 'MANTENIMIENTO':
      return Colors.orange;
    case 'PUBLICIDAD':
      return Colors.purple;
    default:
      return const Color(0xFF2F3A8F);
  }
}

// ─── Page ────────────────────────────────────────────────────────────────────

class GastosPage extends ConsumerStatefulWidget {
  const GastosPage({super.key});

  @override
  ConsumerState<GastosPage> createState() => _GastosPageState();
}

class _GastosPageState extends ConsumerState<GastosPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _mesSeleccionado;
  late int _anioSeleccionado;
  late TextEditingController _montoFijoController;
  late TextEditingController _descripcionController;
  late TextEditingController _montoVariableController;
  late TextEditingController _fechaController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    final ahora = DateTime.now();
    _mesSeleccionado = ahora.month;
    _anioSeleccionado = ahora.year;
    _montoFijoController = TextEditingController();
    _descripcionController = TextEditingController();
    _montoVariableController = TextEditingController();
    _fechaController = TextEditingController();

    Future.microtask(() {
      ref.read(finanzasProvider.notifier).cargarGastosFijosResumen(
            mes: _mesSeleccionado,
            anio: _anioSeleccionado,
          );
      ref.read(finanzasProvider.notifier).cargarTiposGasto();
      ref.read(finanzasProvider.notifier).cargarGastosVariablesResumen(
            mes: _mesSeleccionado,
            anio: _anioSeleccionado,
          );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _montoFijoController.dispose();
    _descripcionController.dispose();
    _montoVariableController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  void _anteriorMes() {
    setState(() {
      if (_mesSeleccionado == 1) {
        _mesSeleccionado = 12;
        _anioSeleccionado--;
      } else {
        _mesSeleccionado--;
      }
    });
    _recargarMes();
  }

  void _siguienteMes() {
    setState(() {
      if (_mesSeleccionado == 12) {
        _mesSeleccionado = 1;
        _anioSeleccionado++;
      } else {
        _mesSeleccionado++;
      }
    });
    _recargarMes();
  }

  void _recargarMes() {
    ref.read(finanzasProvider.notifier).cargarGastosFijosResumen(
          mes: _mesSeleccionado,
          anio: _anioSeleccionado,
        );
    ref.read(finanzasProvider.notifier).cargarGastosVariablesResumen(
          mes: _mesSeleccionado,
          anio: _anioSeleccionado,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(finanzasProvider);

    ref.listen(finanzasProvider, (previous, next) {
      if (next.successMessage != null &&
          (previous?.successMessage ?? '') != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(next.successMessage!),
            ]),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(finanzasProvider.notifier).clearMessages();
      }
      if (next.errorMessage != null &&
          (previous?.errorMessage ?? '') != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            CustomAppBar(
              title: 'Gastos',
              subtitle: 'Fijos y variables del negocio',
              icon: Icons.trending_down_outlined,
              isTiendaTitle: true,
              onBack: () => context.go(AppRoutes.finanzas),
            ),
            const SizedBox(height: 8),

            // ── Selector de período con flechas ──────────────────────────
            _PeriodSelector(
              mes: _mesSeleccionado,
              anio: _anioSeleccionado,
              onAnterior: _anteriorMes,
              onSiguiente: _siguienteMes,
            ),

            // ── TabBar ───────────────────────────────────────────────────
            Container(
              color: Colors.white,
              margin: const EdgeInsets.only(top: 8),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF2F3A8F),
                indicatorWeight: 3,
                labelColor: const Color(0xFF2F3A8F),
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.receipt_long_outlined, size: 18),
                    text: 'Fijos',
                    iconMargin: EdgeInsets.only(bottom: 2),
                  ),
                  Tab(
                    icon: Icon(Icons.attach_money_outlined, size: 18),
                    text: 'Variables',
                    iconMargin: EdgeInsets.only(bottom: 2),
                  ),
                ],
              ),
            ),

            // ── Contenido ────────────────────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildGastosFijos(state),
                        _buildGastosVariables(state),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _mostrarDialogoAgregarGastoFijo();
          } else {
            _mostrarDialogoAgregarGastoVariable();
          }
        },
        backgroundColor: const Color(0xFF1F2A7C),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'Gasto Fijo' : 'Gasto Variable',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // ─── Gastos Fijos Tab ──────────────────────────────────────────────────────

  Widget _buildGastosFijos(FinanzasState state) {
    if (state.errorMessage != null) {
      return ErrorState(mensaje: state.errorMessage!, onRetry: _recargarMes);
    }
    if (state.gastosFijosResumen == null) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        titulo: 'Sin gastos fijos',
        subtitulo: 'No hay registros para este período',
      );
    }
    return _buildResumenFijos(state.gastosFijosResumen!);
  }

  Widget _buildResumenFijos(GastoFijoResumenModel resumen) {
    final mesCerrado =
        resumen.tiendas.firstOrNull?.mesCerrado ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        children: [
          // ── Banner total global ──────────────────────────────────────
          _TotalBanner(
            titulo: 'Total Gastos Fijos',
            monto: resumen.totalGlobal,
            periodo: '${_meses[_mesSeleccionado - 1]} $_anioSeleccionado',
            mesCerrado: mesCerrado,
            onCerrarMes: mesCerrado ? null : _mostrarDialogoCerrarMes,
          ),
          const SizedBox(height: 16),

          // ── Cards por tienda ────────────────────────────────────────
          ...resumen.tiendas.map(
            (tienda) => _TiendaGastosCard(tienda: tienda),
          ),
        ],
      ),
    );
  }

  // ─── Gastos Variables Tab ──────────────────────────────────────────────────

  Widget _buildGastosVariables(FinanzasState state) {
    if (state.errorMessage != null) {
      return ErrorState(mensaje: state.errorMessage!, onRetry: _recargarMes);
    }
    if (state.gastosVariablesResumen == null) {
      return EmptyState(
        icon: Icons.attach_money_outlined,
        titulo: 'Sin gastos variables',
        subtitulo: 'No hay registros para este período',
      );
    }
    return _buildResumenVariables(state.gastosVariablesResumen!);
  }

  Widget _buildResumenVariables(GastoVariableResumenModel resumen) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        children: [
          // ── Banner total ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withValues(alpha: 0.15),
                  Colors.orange.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.attach_money,
                      color: Colors.orange, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resumen.tienda,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Total Gastos Variables',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_meses[_mesSeleccionado - 1]} $_anioSeleccionado',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'S/ ${resumen.totalMes}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'del mes',
                        style: TextStyle(
                            fontSize: 11, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Info card ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F3A8F).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Color(0xFF2F3A8F),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Qué son gastos variables?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Son gastos que varían mes a mes: compras de insumos, materiales, servicios ocasionales, etc. Toca el botón + para registrar uno.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Dialogs ───────────────────────────────────────────────────────────────

  void _mostrarDialogoAgregarGastoFijo() {
    _montoFijoController.clear();
    String? tipoGastoSeleccionado;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final state = ref.watch(finanzasProvider);
        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F3A8F).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: Color(0xFF2F3A8F),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nuevo Gasto Fijo',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Gasto recurrente mensual',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  initialValue: tipoGastoSeleccionado,
                  items: state.tiposGasto
                      .map(
                        (tipo) => DropdownMenuItem(
                          value: tipo.valor,
                          child: Row(
                            children: [
                              Icon(
                                _iconForTipo(tipo.valor),
                                size: 18,
                                color: _colorForTipo(tipo.valor),
                              ),
                              const SizedBox(width: 8),
                              Text(tipo.etiqueta),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setModalState(() => tipoGastoSeleccionado = value);
                  },
                  decoration: InputDecoration(
                    labelText: 'Tipo de Gasto',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _montoFijoController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Monto',
                    prefixText: 'S/ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async =>
                        await _agregarGastoFijo(tipoGastoSeleccionado),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F2A7C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Agregar Gasto',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarDialogoAgregarGastoVariable() {
    _descripcionController.clear();
    _montoVariableController.clear();
    _fechaController.text = DateTime.now().toString().split(' ')[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.attach_money_outlined,
                    color: Colors.orange,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nuevo Gasto Variable',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Gasto adicional o esporádico',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _descripcionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                hintText: 'Ej: Compra de materiales',
                prefixIcon: const Icon(Icons.edit_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _montoVariableController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monto',
                prefixText: 'S/ ',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fechaController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Fecha',
                suffixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onTap: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (fecha != null) {
                  _fechaController.text =
                      fecha.toString().split(' ')[0];
                }
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async => await _agregarGastoVariable(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2A7C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Agregar Gasto',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoCerrarMes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_outline,
                  color: Colors.orange, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Cerrar Mes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text(
          '¿Deseas cerrar ${_meses[_mesSeleccionado - 1]} $_anioSeleccionado?\n\n'
          'Una vez cerrado, no se podrán agregar ni modificar gastos fijos de este período.',
          style: const TextStyle(color: Colors.grey, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(finanzasProvider.notifier).cerrarMesGastos(
                    mes: _mesSeleccionado,
                    anio: _anioSeleccionado,
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cerrar Mes',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _agregarGastoFijo(String? tipo) async {
    if (tipo == null || _montoFijoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final tiendaId = ref.read(authProvider).selectedTiendaId;
    if (tiendaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay tienda seleccionada'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await ref.read(finanzasProvider.notifier).crearGastoFijo(
          GastoFijoCreateModel(
            tiendaId: tiendaId,
            tipoGasto: tipo,
            mes: _mesSeleccionado,
            anio: _anioSeleccionado,
            monto: _montoFijoController.text,
          ),
        );

    if (mounted) Navigator.pop(context);
  }

  Future<void> _agregarGastoVariable() async {
    if (_descripcionController.text.isEmpty ||
        _montoVariableController.text.isEmpty ||
        _fechaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authState = ref.read(authProvider);
    final userMe = authState.userMe;
    final tiendas = userMe?.tiendas ?? [];
    final isDueno = userMe?.isDueno ?? false;

    int? tiendaId;
    if (isDueno || tiendas.length > 1) {
      tiendaId = authState.selectedTiendaId;
      if (tiendaId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay tienda seleccionada'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    await ref.read(finanzasProvider.notifier).crearGastoVariable(
          GastoVariableCreateModel(
            descripcion: _descripcionController.text,
            monto: _montoVariableController.text,
            fecha: _fechaController.text,
            tiendaId: tiendaId,
          ),
        );

    if (mounted) Navigator.pop(context);
  }
}

// ─── Period Selector ──────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final int mes;
  final int anio;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;

  const _PeriodSelector({
    required this.mes,
    required this.anio,
    required this.onAnterior,
    required this.onSiguiente,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onAnterior,
            icon: const Icon(Icons.chevron_left),
            color: const Color(0xFF2F3A8F),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _meses[mes - 1],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F3A8F),
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '$anio',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSiguiente,
            icon: const Icon(Icons.chevron_right),
            color: const Color(0xFF2F3A8F),
          ),
        ],
      ),
    );
  }
}

// ─── Total Banner ─────────────────────────────────────────────────────────────

class _TotalBanner extends StatelessWidget {
  final String titulo;
  final String monto;
  final String periodo;
  final bool mesCerrado;
  final VoidCallback? onCerrarMes;

  const _TotalBanner({
    required this.titulo,
    required this.monto,
    required this.periodo,
    required this.mesCerrado,
    this.onCerrarMes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2F3A8F).withValues(alpha: 0.12),
            const Color(0xFF2F3A8F).withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF2F3A8F).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF2F3A8F).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: Color(0xFF2F3A8F),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'S/ $monto',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F3A8F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  periodo,
                  style:
                      const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCerrarMes,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: mesCerrado
                    ? Colors.grey[200]
                    : Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: mesCerrado
                      ? Colors.grey[300]!
                      : Colors.orange.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    mesCerrado ? Icons.lock : Icons.lock_open_outlined,
                    size: 14,
                    color: mesCerrado ? Colors.grey : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    mesCerrado ? 'Cerrado' : 'Cerrar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: mesCerrado ? Colors.grey : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tienda Gastos Card ───────────────────────────────────────────────────────

class _TiendaGastosCard extends StatelessWidget {
  final TiendaGastoFijoDetalle tienda;

  const _TiendaGastosCard({required this.tienda});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header de tienda ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2F3A8F).withValues(alpha: 0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F3A8F).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.store_outlined,
                      color: Color(0xFF2F3A8F), size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tienda.tienda,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                StatusBadge(
                  label: tienda.mesCerrado ? 'Cerrado' : 'Abierto',
                  color: tienda.mesCerrado ? Colors.grey : Colors.green,
                ),
              ],
            ),
          ),

          // ── Filas de categorías ─────────────────────────────────────
          ...tienda.detalle.entries.map(
            (entry) => _GastoCategoryRow(
              categoria: entry.key,
              monto: entry.value.toString(),
            ),
          ),

          // ── Total ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.04),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(20)),
              border: Border(
                top: BorderSide(
                    color: Colors.red.withValues(alpha: 0.15), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'S/ ${tienda.totalGeneral}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GastoCategoryRow extends StatelessWidget {
  final String categoria;
  final String monto;

  const _GastoCategoryRow({
    required this.categoria,
    required this.monto,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorForTipo(categoria);
    final icon = _iconForTipo(categoria);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _capitalize(categoria),
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          Text(
            'S/ $monto',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}
