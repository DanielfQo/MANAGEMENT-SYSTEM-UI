import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/invitation/invitation_provider.dart';
import 'package:management_system_ui/features/invitation/models/store_model.dart';
import 'usuarios_provider.dart';
import 'models/usuario_tienda_model.dart';

class UsuariosPage extends ConsumerStatefulWidget {
  const UsuariosPage({super.key});

  @override
  ConsumerState<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends ConsumerState<UsuariosPage> {
  StoreModel? _tiendaSeleccionada;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(tiendasProvider);
    });
  }

  void _shareLink(String link, String usuarioNombre) {
    Share.share(
      '¡Hola $usuarioNombre! Te reenvío tu invitación al sistema. '
      'Toca el link para completar tu registro:\n$link',
      subject: 'Invitación al sistema de gestión',
    );
  }

  Future<void> _confirmarReenvio(
      BuildContext context, UsuarioTiendaModel usuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Reenviar invitación',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Deseas reenviar la invitación a ${usuario.usuarioNombre}?\n\n'
          'La invitación anterior quedará invalidada.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F3A8F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reenviar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await ref
          .read(usuariosProvider.notifier)
          .refrescarInvitacion(usuario.usuarioId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usuariosProvider);
    final tiendasAsync = ref.watch(tiendasProvider);

    // Cuando el link está listo → compartir automáticamente
    ref.listen(usuariosProvider, (prev, next) {
      if (next.invitationLink != null && prev?.invitationLink == null) {
        final link = next.invitationLink!;
        final usuario = next.usuarios.firstWhere(
          (u) => !u.usuarioIsActive,
          orElse: () => next.usuarios.first,
        );
        _shareLink(link, usuario.usuarioNombre);
        ref.read(usuariosProvider.notifier).clearInvitationLink();
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
                    child: Icon(Icons.people, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mis Usuarios',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Gestiona a tu equipo',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref
                        .read(usuariosProvider.notifier)
                        .cargarUsuarios(
                            tiendaId: _tiendaSeleccionada?.id),
                    icon: const Icon(Icons.refresh,
                        color: Color(0xFF2F3A8F)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Filtro de tienda ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: tiendasAsync.when(
                loading: () => _dropdownSkeleton('Cargando tiendas...'),
                error: (_, __) =>
                    _dropdownSkeleton('Error al cargar tiendas'),
                data: (tiendas) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
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
                            .read(usuariosProvider.notifier)
                            .seleccionarTienda(tienda?.id);
                      },
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Lista de usuarios ─────────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF2F3A8F)))
                  : state.errorMessage != null
                      ? _buildError(state.errorMessage!)
                      : state.usuarios.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              color: const Color(0xFF2F3A8F),
                              onRefresh: () => ref
                                  .read(usuariosProvider.notifier)
                                  .cargarUsuarios(
                                      tiendaId:
                                          _tiendaSeleccionada?.id),
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 16),
                                itemCount: state.usuarios.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final usuario =
                                      state.usuarios[index];
                                  return _buildUsuarioCard(
                                      context, usuario, state);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Card de usuario ───────────────────────────────────────────────────────

  Widget _buildUsuarioCard(
    BuildContext context,
    UsuarioTiendaModel usuario,
    UsuariosState state,
  ) {
    final isPendiente = !usuario.usuarioIsActive;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          // Avatar con inicial
          CircleAvatar(
            radius: 22,
            backgroundColor: isPendiente
                ? Colors.orange.withOpacity(0.15)
                : const Color(0xFF2F3A8F).withOpacity(0.1),
            child: Text(
              usuario.usuarioNombre.isNotEmpty
                  ? usuario.usuarioNombre[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPendiente
                    ? Colors.orange
                    : const Color(0xFF2F3A8F),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usuario.usuarioNombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F3A8F).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        usuario.rolDisplay,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2F3A8F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPendiente
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isPendiente ? 'Pendiente' : 'Activo',
                        style: TextStyle(
                          fontSize: 11,
                          color: isPendiente
                              ? Colors.orange
                              : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  usuario.tiendaNombre,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),

          // Botón reenviar
          if (isPendiente)
            state.isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2F3A8F)),
                  )
                : IconButton(
                    onPressed: () =>
                        _confirmarReenvio(context, usuario),
                    icon: const Icon(
                      Icons.send_outlined,
                      color: Color(0xFF2F3A8F),
                    ),
                    tooltip: 'Reenviar invitación',
                  ),
        ],
      ),
    );
  }

  // ─── Estados vacío y error ────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE9EEF6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.people_outline,
                size: 44, color: Color(0xFF2F3A8F)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin usuarios',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'No hay usuarios en esta tienda',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String mensaje) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              size: 44, color: Colors.red),
          const SizedBox(height: 12),
          Text(mensaje,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F3A8F),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () => ref
                .read(usuariosProvider.notifier)
                .cargarUsuarios(tiendaId: _tiendaSeleccionada?.id),
            child: const Text('Reintentar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _dropdownSkeleton(String label) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      alignment: Alignment.centerLeft,
      child: Text(label, style: const TextStyle(color: Colors.grey)),
    );
  }
}