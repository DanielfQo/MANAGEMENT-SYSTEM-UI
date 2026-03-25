import 'package:flutter/material.dart';
import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/invitation/invitation_provider.dart';
import 'package:management_system_ui/features/invitation/models/store_model.dart';
import 'package:management_system_ui/core/widgets/empty_state.dart';
import 'package:management_system_ui/core/widgets/dropdown_skeleton.dart';
import 'asistencia_provider.dart';
import 'models/asistencia_resumen_model.dart';

class AsistenciaPage extends ConsumerStatefulWidget {
  const AsistenciaPage({super.key});

  @override
  ConsumerState<AsistenciaPage> createState() => _AsistenciaPageState();
}

class _AsistenciaPageState extends ConsumerState<AsistenciaPage>
    with SingleTickerProviderStateMixin {
  StoreModel? _tiendaSeleccionada;
  late TabController _tabController;

  static const _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        final state = ref.read(asistenciaProvider);
        if (state.resumen.isEmpty && !state.isLoadingResumen) {
          ref.read(asistenciaProvider.notifier).cargarResumen();
        }
      }
    });
    Future.microtask(() => ref.invalidate(tiendasProvider));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Diálogo de salida ────────────────────────────────────────────────────

  Future<void> _confirmarSalida(
      BuildContext context, UsuarioConAsistencia item) async {
    bool almuerzo = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Marcar Salida',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '¿Confirmar salida de ${item.usuario.usuarioNombre}?',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.restaurant_outlined,
                            color: Colors.grey, size: 20),
                        SizedBox(width: 8),
                        Text('Almorzó'),
                      ],
                    ),
                    Switch(
                      value: almuerzo,
                      activeThumbColor: const Color(0xFF2F3A8F),
                      onChanged: (v) =>
                          setDialogState(() => almuerzo = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F3A8F),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                ref.read(asistenciaProvider.notifier).marcarSalida(
                      usuarioTiendaId: item.usuario.id,
                      almuerzo: almuerzo,
                    );
              },
              child: const Text('Confirmar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(asistenciaProvider);
    final userMe = ref.watch(authProvider).userMe;
    final esDueno = userMe?.isDueno ?? false;
    final tiendasAsync = esDueno
        ? ref.watch(tiendasProvider)
        : AsyncValue.data(
            (userMe?.tiendas ?? [])
                .map((t) => StoreModel(
                      id: t.tiendaId,
                      nombreSede: t.tiendaNombre,
                      direccion: '',
                      ubigeo: '',
                    ))
                .toList(),
          );

    final now = DateTime.now();
    final fechaDisplay =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    ref.listen(asistenciaProvider, (prev, next) {
      if (next.successMessage != null && prev?.successMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(next.successMessage!),
            ]),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(asistenciaProvider.notifier).clearMessages();
      }
      if (next.errorMessage != null && prev?.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(next.errorMessage!)),
            ]),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(asistenciaProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFF1F2A7C),
                    child: Icon(Icons.access_time, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Asistencia',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        Text('Hoy $fechaDisplay',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_tabController.index == 0) {
                        ref
                            .read(asistenciaProvider.notifier)
                            .cargarAsistenciasHoy(
                                tiendaId: _tiendaSeleccionada?.id);
                      } else {
                        ref
                            .read(asistenciaProvider.notifier)
                            .cargarResumen();
                      }
                    },
                    icon: const Icon(Icons.refresh,
                        color: Color(0xFF2F3A8F)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Filtro de tienda (solo DUEÑO) ─────────────────────────
            if (esDueno)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: tiendasAsync.when(
                  loading: () => const DropdownSkeleton(
                      label: 'Cargando tiendas...'),
                  error: (_, _) => const DropdownSkeleton(
                      label: 'Error al cargar tiendas'),
                  data: (tiendas) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<StoreModel?>(
                        value: _tiendaSeleccionada,
                        isExpanded: true,
                        hint: const Row(
                          children: [
                            Icon(Icons.store_outlined,
                                color: Colors.grey, size: 20),
                            SizedBox(width: 10),
                            Text('Todas las tiendas',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        items: [
                          const DropdownMenuItem<StoreModel?>(
                            value: null,
                            child: Text('Todas las tiendas'),
                          ),
                          ...tiendas.map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.nombreSede),
                              )),
                        ],
                        onChanged: (tienda) {
                          setState(() => _tiendaSeleccionada = tienda);
                          ref
                              .read(asistenciaProvider.notifier)
                              .seleccionarTienda(tienda?.id);
                        },
                      ),
                    ),
                  ),
                ),
              ),

            if (esDueno) const SizedBox(height: 12),

            // ── TabBar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF2F3A8F),
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: const Color(0xFF2F3A8F),
                unselectedLabelColor: Colors.grey,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Hoy'),
                  Tab(text: 'Resumen mensual'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Contenido por tab ─────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── Tab 1: Hoy ──────────────────────────────────────
                  state.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF2F3A8F)))
                      : state.usuariosHoy.isEmpty
                          ? const EmptyState(
                              icon: Icons.access_time,
                              titulo: 'Sin usuarios activos',
                              subtitulo:
                                  'No hay usuarios activos en esta tienda',
                            )
                          : RefreshIndicator(
                              color: const Color(0xFF2F3A8F),
                              onRefresh: () => ref
                                  .read(asistenciaProvider.notifier)
                                  .cargarAsistenciasHoy(
                                      tiendaId: _tiendaSeleccionada?.id),
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 16),
                                itemCount: state.usuariosHoy.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final item = state.usuariosHoy[index];
                                  return _buildAsistenciaCard(
                                      context, item, state);
                                },
                              ),
                            ),

                  // ── Tab 2: Resumen mensual ──────────────────────────
                  _buildResumenTab(state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab resumen ──────────────────────────────────────────────────────────

  Widget _buildResumenTab(AsistenciaState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Mes
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: state.mesResumen,
                      isExpanded: true,
                      items: List.generate(
                        12,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text(_meses[i]),
                        ),
                      ),
                      onChanged: (mes) {
                        if (mes != null) {
                          ref
                              .read(asistenciaProvider.notifier)
                              .cargarResumen(mes: mes);
                        }
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Año
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: state.anioResumen,
                    items: List.generate(
                      3,
                      (i) {
                        final year = DateTime.now().year - i;
                        return DropdownMenuItem(
                          value: year,
                          child: Text('$year'),
                        );
                      },
                    ),
                    onChanged: (anio) {
                      if (anio != null) {
                        ref
                            .read(asistenciaProvider.notifier)
                            .cargarResumen(anio: anio);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Expanded(
          child: state.isLoadingResumen
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF2F3A8F)))
              : state.resumen.isEmpty
                  ? const EmptyState(
                      icon: Icons.bar_chart,
                      titulo: 'Sin registros',
                      subtitulo: 'No hay asistencias en este período',
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: state.resumen.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = state.resumen[index];
                        return _buildResumenCard(item);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildResumenCard(AsistenciaResumenModel item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                const Color(0xFF2F3A8F).withValues(alpha: 0.1),
            child: Text(
              item.usuarioNombre.isNotEmpty
                  ? item.usuarioNombre[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F3A8F),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.usuarioNombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  '${item.diasTrabajados} días · ${item.horasTotales.toStringAsFixed(1)} horas',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2F3A8F).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${item.diasTrabajados}d',
              style: const TextStyle(
                color: Color(0xFF2F3A8F),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Card asistencia del día ──────────────────────────────────────────────

  Widget _buildAsistenciaCard(
    BuildContext context,
    UsuarioConAsistencia item,
    AsistenciaState state,
  ) {
    final usuario = item.usuario;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                const Color(0xFF2F3A8F).withValues(alpha: 0.1),
            child: Text(
              usuario.usuarioNombre.isNotEmpty
                  ? usuario.usuarioNombre[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F3A8F)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(usuario.usuarioNombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                _buildEstadoAsistencia(item),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (state.isMarking)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF2F3A8F)),
            )
          else
            _buildAccion(context, item),
        ],
      ),
    );
  }

  Widget _buildEstadoAsistencia(UsuarioConAsistencia item) {
    if (item.completo) {
      return Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 14),
          const SizedBox(width: 4),
          Text(
            '${_formatHora(item.asistencia!.horaEntrada)} → ${_formatHora(item.asistencia!.horaSalida)}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          if (item.asistencia!.almuerzo) ...[
            const SizedBox(width: 6),
            const Icon(Icons.restaurant,
                color: Colors.orange, size: 14),
          ],
        ],
      );
    }
    if (item.tieneEntrada) {
      return Row(
        children: [
          const Icon(Icons.login, color: Color(0xFF2F3A8F), size: 14),
          const SizedBox(width: 4),
          Text(
            'Entrada: ${_formatHora(item.asistencia!.horaEntrada)}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      );
    }
    return const Text('Sin asistencia hoy',
        style: TextStyle(color: Colors.grey, fontSize: 12));
  }

  Widget _buildAccion(BuildContext context, UsuarioConAsistencia item) {
    if (item.completo) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Completo',
            style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      );
    }
    if (item.tieneEntrada) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () => _confirmarSalida(context, item),
        child: const Text('Salida',
            style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      );
    }
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2F3A8F),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () => ref
          .read(asistenciaProvider.notifier)
          .marcarEntrada(item.usuario.id),
      child: const Text('Entrada',
          style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500)),
    );
  }

  String _formatHora(String? hora) {
    if (hora == null) return '--';
    return hora.length >= 5 ? hora.substring(0, 5) : hora;
  }
}