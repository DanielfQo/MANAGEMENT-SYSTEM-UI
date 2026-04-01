import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/core/router.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/finanzas/constants/estados_deuda.dart';
import 'finanzas_provider.dart';
import 'models/deuda_model.dart';
import 'models/pago_model.dart';
import 'widgets/deuda_card.dart';

class DeudasPage extends ConsumerStatefulWidget {
  const DeudasPage({super.key});

  @override
  ConsumerState<DeudasPage> createState() => _DeudasPageState();
}

class _DeudasPageState extends ConsumerState<DeudasPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _filtroEstado;
  late TextEditingController _montoController;
  late TextEditingController _busquedaController;
  int _tipoBusqueda = 0; // 0 = documento, 1 = comprobante

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        final state = ref.read(finanzasProvider);
        if (state.pagos.isEmpty && !state.isLoading) {
          ref.read(finanzasProvider.notifier).cargarPagos();
        }
      }
    });
    _montoController = TextEditingController();
    _busquedaController = TextEditingController();
    Future.microtask(
      () => ref.read(finanzasProvider.notifier).cargarDeudas(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _montoController.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(finanzasProvider);

    ref.listen(authProvider, (previous, next) {
      if (previous?.selectedTiendaId != next.selectedTiendaId) {
        ref.read(finanzasProvider.notifier).cargarDeudas();
      }
    });

    ref.listen(finanzasProvider, (previous, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!)),
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

    final deudasFiltradas = _filtroEstado == null
        ? state.deudas
        : state.deudas.where((d) => d.estado == _filtroEstado).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Deudas y Pagos',
              subtitle: '${deudasFiltradas.length} deuda(s)',
              icon: Icons.receipt_long_outlined,
              isTiendaTitle: true,
              onBack: () => context.go(AppRoutes.finanzas),
            ),
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF2F3A8F),
                indicatorWeight: 3,
                labelColor: const Color(0xFF2F3A8F),
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Deudas'),
                  Tab(text: 'Pagos'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDeudasTab(context, state, deudasFiltradas),
                  _buildPagosTab(state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab Deudas ────────────────────────────────────────────────────────────

  Widget _buildDeudasTab(
    BuildContext context,
    FinanzasState state,
    List<DeudaModel> deudasFiltradas,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Buscar',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _busquedaController,
                      decoration: InputDecoration(
                        labelText: _tipoBusqueda == 0
                            ? 'Número de Documento'
                            : 'Número de Comprobante',
                        hintText:
                            _tipoBusqueda == 0 ? 'DNI/RUC' : 'F001-00001',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _ejecutarBusqueda(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Icon(Icons.search),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(
                          value: 0,
                          label: Text('Por Documento'),
                          icon: Icon(Icons.person),
                        ),
                        ButtonSegment(
                          value: 1,
                          label: Text('Por Comprobante'),
                          icon: Icon(Icons.receipt),
                        ),
                      ],
                      selected: {_tipoBusqueda},
                      onSelectionChanged: (Set<int> newSelection) {
                        setState(() {
                          _tipoBusqueda = newSelection.first;
                          _busquedaController.clear();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () =>
                        ref.read(finanzasProvider.notifier).cargarDeudas(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: DropdownButtonFormField<String?>(
            initialValue: _filtroEstado,
            items: [
              const DropdownMenuItem(value: null, child: Text('Todas')),
              DropdownMenuItem(
                value: EstadosDeuda.activa,
                child: Text(EstadosDeuda.getLabel(EstadosDeuda.activa)),
              ),
              DropdownMenuItem(
                value: EstadosDeuda.pagada,
                child: Text(EstadosDeuda.getLabel(EstadosDeuda.pagada)),
              ),
            ],
            onChanged: (value) => setState(() => _filtroEstado = value),
            decoration: InputDecoration(
              labelText: 'Filtrar por Estado',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.errorMessage != null
                  ? ErrorState(
                      mensaje: state.errorMessage!,
                      onRetry: () =>
                          ref.read(finanzasProvider.notifier).cargarDeudas(),
                    )
                  : deudasFiltradas.isEmpty
                      ? EmptyState(
                          icon: Icons.check_circle_outline,
                          titulo: 'Sin deudas',
                          subtitulo: 'No hay deudas en este estado',
                        )
                      : ListView.builder(
                          itemCount: deudasFiltradas.length,
                          itemBuilder: (context, index) {
                            final deuda = deudasFiltradas[index];
                            return DeudaCard(
                              deuda: deuda,
                              onPayTap:
                                  deuda.estado == EstadosDeuda.activa
                                      ? () => _mostrarDialogoPago(
                                          context, deuda)
                                      : null,
                            );
                          },
                        ),
        ),
      ],
    );
  }

  // ─── Tab Pagos ─────────────────────────────────────────────────────────────

  Widget _buildPagosTab(FinanzasState state) {
    return state.isLoading
        ? const Center(child: CircularProgressIndicator())
        : state.errorMessage != null
            ? ErrorState(
                mensaje: state.errorMessage!,
                onRetry: () =>
                    ref.read(finanzasProvider.notifier).cargarPagos(),
              )
            : state.pagos.isEmpty
                ? EmptyState(
                    icon: Icons.check_circle_outline,
                    titulo: 'Sin pagos',
                    subtitulo: 'No hay pagos registrados',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: state.pagos.length,
                    itemBuilder: (context, index) {
                      final pago = state.pagos[index];
                      return _PagoCard(pago: pago);
                    },
                  );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _ejecutarBusqueda() {
    final busqueda = _busquedaController.text.trim();
    if (busqueda.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un término de búsqueda'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_tipoBusqueda == 0) {
      ref
          .read(finanzasProvider.notifier)
          .buscarDeudasPorDocumento(busqueda);
    } else {
      ref
          .read(finanzasProvider.notifier)
          .buscarDeudasPorComprobante(busqueda);
    }
  }

  void _mostrarDialogoPago(BuildContext context, DeudaModel deuda) {
    _montoController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Registrar Pago',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saldo: S/ ${deuda.saldo}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _montoController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Monto a Pagar',
                  hintText: '0.00',
                  prefixText: 'S/ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => _registrarPago(context, deuda),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F3A8F),
              ),
              child: const Text(
                'Pagar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _registrarPago(BuildContext context, DeudaModel deuda) async {
    final monto = _montoController.text;
    if (monto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un monto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final montoDouble = double.tryParse(monto) ?? 0;
    if (montoDouble <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El monto debe ser mayor a 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final pdfBytes = await ref
          .read(finanzasProvider.notifier)
          .registrarPago(
            deudaId: deuda.id,
            monto: monto,
          );

      if (pdfBytes != null && mounted) {
        navigator.pop();
        router.push(
          '/finanzas/pago-resumen',
          extra: {'deuda': deuda, 'monto': monto},
        );
      } else {
        navigator.pop();
      }
    } catch (e) {
      navigator.pop();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error al registrar pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ─── Pago Card ─────────────────────────────────────────────────────────────

class _PagoCard extends StatelessWidget {
  final PagoModel pago;

  const _PagoCard({required this.pago});

  IconData get _icon {
    switch (pago.tipoOrigen.toUpperCase()) {
      case 'VENTA':
        return Icons.shopping_cart_outlined;
      case 'SERVICIO':
        return Icons.build_outlined;
      default:
        return Icons.receipt_outlined;
    }
  }

  Color get _color {
    switch (pago.tipoOrigen.toUpperCase()) {
      case 'VENTA':
        return Colors.blue;
      case 'SERVICIO':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String get _origenLabel {
    final tipo = pago.tipoOrigen.toUpperCase();
    if (tipo == 'VENTA') return 'Pago de Venta';
    if (tipo == 'SERVICIO') return 'Pago de Servicio';
    return 'Pago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
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
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: _color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _origenLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.tag, size: 12, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text(
                      'Comprobante #${pago.origenId}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text(
                      pago.fecha,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'S/ ${pago.monto}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
