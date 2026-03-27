import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/invitation/invitation_provider.dart';
import 'package:management_system_ui/core/models/store_model.dart';
import 'package:management_system_ui/core/widgets/invitation_link_sheet.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'usuarios_provider.dart';
import 'models/usuario_tienda_model.dart';

class UsuariosPage extends ConsumerStatefulWidget {
  const UsuariosPage({super.key});

  @override
  ConsumerState<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends ConsumerState<UsuariosPage> {
  String? _rolSeleccionado;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<Map<String, String?>> _roles = [
    {'value': null, 'label': 'Todos los roles'},
    {'value': Roles.dueno, 'label': 'Dueño'},
    {'value': Roles.administrador, 'label': 'Administrador'},
    {'value': Roles.trabajador, 'label': 'Trabajador'},
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(tiendasProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Diálogo de edición ───────────────────────────────────────────────────

  Future<void> _mostrarEdicion(
    BuildContext context,
    UsuarioTiendaModel usuario,
    List<StoreModel> tiendas,
  ) async {
    final salarioController =
        TextEditingController(text: usuario.salario);
    String? rolSeleccionado =
        usuario.rol == Roles.dueno ? null : usuario.rol;
    StoreModel? tiendaSeleccionada =
        tiendas.where((t) => t.id == usuario.tiendaId).firstOrNull;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    const Color(0xFF2F3A8F).withValues(alpha: 0.1),
                child: Text(
                  !usuario.usuarioIsActive &&
                          usuario.usuarioEmail.isNotEmpty
                      ? usuario.usuarioEmail[0].toUpperCase()
                      : usuario.usuarioNombre.isNotEmpty
                          ? usuario.usuarioNombre[0].toUpperCase()
                          : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F3A8F),
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  usuario.usuarioNombre,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rol',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: usuario.rol == Roles.dueno
                      ? Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'Dueño (no modificable)',
                            style:
                                TextStyle(color: Colors.grey.shade500),
                          ),
                        )
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: rolSeleccionado,
                            isExpanded: true,
                            hint: const Text('Selecciona un rol'),
                            items: [
                              Roles.administrador,
                              Roles.trabajador,
                            ]
                                .map((r) => DropdownMenuItem(
                                      value: r,
                                      child: Text(
                                          r[0].toUpperCase() +
                                              r
                                                  .substring(1)
                                                  .toLowerCase()),
                                    ))
                                .toList(),
                            onChanged: (v) => setDialogState(
                                () => rolSeleccionado = v),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                const Text('Tienda',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<StoreModel?>(
                      value: tiendaSeleccionada,
                      isExpanded: true,
                      hint: const Text('Selecciona una tienda'),
                      items: tiendas
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.nombreSede),
                              ))
                          .toList(),
                      onChanged: (v) => setDialogState(
                          () => tiendaSeleccionada = v),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Salario',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: salarioController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: InputDecoration(
                    hintText: 'ej: 1500.00',
                    prefixIcon:
                        const Icon(Icons.attach_money_outlined),
                    filled: true,
                    fillColor: const Color(0xFFF6F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
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
                ref.read(usuariosProvider.notifier).editarUsuario(
                  id: usuario.id,
                  tiendaId: tiendaSeleccionada?.id,
                  rol: usuario.rol == Roles.dueno
                      ? null
                      : rolSeleccionado,
                  salario: salarioController.text.trim().isEmpty
                      ? null
                      : salarioController.text.trim(),
                );
              },
              child: const Text('Guardar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Confirmación reenvío ─────────────────────────────────────────────────

  Future<void> _confirmarReenvio(
      BuildContext context, UsuarioTiendaModel usuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Reenviar invitación',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          '¿Deseas reenviar la invitación a ${!usuario.usuarioIsActive && usuario.usuarioEmail.isNotEmpty ? usuario.usuarioEmail : usuario.usuarioNombre}?\n\n'
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
                  borderRadius: BorderRadius.circular(10)),
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

  List<UsuarioTiendaModel> _filtrarUsuarios(
      List<UsuarioTiendaModel> usuarios) {
    if (_searchQuery.isEmpty) return usuarios;
    final query = _searchQuery.toLowerCase();
    return usuarios.where((u) {
      return u.usuarioNombre.toLowerCase().contains(query) ||
          u.usuarioEmail.toLowerCase().contains(query);
    }).toList();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usuariosProvider);
    final userMe = ref.watch(authProvider).userMe;
    final esDueno = userMe?.isDueno ?? false;
    final tiendasAsync = esDueno
        ? ref.watch(tiendasProvider)
        : AsyncValue.data(
            (userMe?.tiendas ?? [])
                .map((t) => StoreModel.fromUserTienda(t))
                .toList(),
          );

    ref.listen(usuariosProvider, (prev, next) {
      if ((prev?.isEditing ?? false) &&
          !next.isEditing &&
          next.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Usuario actualizado correctamente'),
            ]),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (next.errorMessage != null && prev?.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(next.errorMessage!)),
            ]),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (next.invitationLink != null && prev?.invitationLink == null) {
        InvitationLinkSheet.show(
          context,
          link: next.invitationLink!,
          onClose: () => ref
              .read(usuariosProvider.notifier)
              .clearInvitationLink(),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header - CustomAppBar Unificado ──────────────────────
            CustomAppBar(
              title: 'Mis Usuarios',
              subtitle: 'Gestiona a tu equipo',
              icon: Icons.people,
              isTiendaTitle: esDueno,
            ),

            const SizedBox(height: 12),

            // ── Acciones rápidas ────────────────────────────────────
            if (esDueno)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildAccionButton(
                        icon: Icons.person_add_alt_1,
                        label: 'Invitar',
                        onTap: () => context.go('/invitation/new'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAccionButton(
                        icon: Icons.access_time_filled,
                        label: 'Asistencia',
                        onTap: () => context.go('/asistencia'),
                      ),
                    ),
                  ],
                ),
              ),

            if (esDueno) const SizedBox(height: 12),

            // ── Filtros ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildDropdownFiltro<String?>(
                icon: Icons.badge_outlined,
                hint: 'Todos los roles',
                value: _rolSeleccionado,
                items: _roles
                    .map((r) => DropdownMenuItem<String?>(
                          value: r['value'],
                          child: Text(r['label'] ?? ''),
                        ))
                    .toList(),
                onChanged: (rol) {
                  setState(() => _rolSeleccionado = rol);
                  ref
                      .read(usuariosProvider.notifier)
                      .seleccionarRol(rol);
                },
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o correo...',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: Colors.grey),
                          onPressed: () => setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          }),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Lista ─────────────────────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF2F3A8F)))
                  : state.errorMessage != null
                      ? ErrorState(
                          mensaje: state.errorMessage!,
                          onRetry: () => ref
                              .read(usuariosProvider.notifier)
                              .cargarUsuarios(),
                        )
                      : _filtrarUsuarios(state.usuarios).isEmpty
                          ? const EmptyState(
                              icon: Icons.people_outline,
                              titulo: 'Sin usuarios',
                              subtitulo:
                                  'No hay usuarios con estos filtros',
                            )
                          : tiendasAsync.when(
                              loading: () => const SizedBox(),
                              error: (_, _) => const SizedBox(),
                              data: (tiendas) {
                                final usuarios =
                                    _filtrarUsuarios(state.usuarios);
                                return RefreshIndicator(
                                  color: const Color(0xFF2F3A8F),
                                  onRefresh: () => ref
                                      .read(usuariosProvider.notifier)
                                      .cargarUsuarios(
                                        rol: _rolSeleccionado,
                                      ),
                                  child: usuarios.isEmpty
                                      ? const EmptyState(
                                          icon: Icons.people_outline,
                                          titulo: 'Sin usuarios',
                                          subtitulo:
                                              'No hay usuarios con estos filtros',
                                        )
                                      : ListView.separated(
                                          padding:
                                              const EdgeInsets.fromLTRB(
                                                  16, 0, 16, 16),
                                          itemCount: usuarios.length,
                                          separatorBuilder: (_, _) =>
                                              const SizedBox(height: 10),
                                          itemBuilder: (context, index) {
                                            final usuario =
                                                usuarios[index];
                                            return _buildUsuarioCard(
                                              context,
                                              usuario,
                                              state,
                                              tiendas,
                                              esDueno,
                                            );
                                          },
                                        ),
                                );
                              },
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
    List<StoreModel> tiendas,
    bool esDueno,
  ) {
    final isPendiente = !usuario.usuarioIsActive &&
        usuario.usuarioNombre.trim().isEmpty;
    final isInactivo = !usuario.usuarioIsActive &&
        usuario.usuarioNombre.trim().isNotEmpty;
    final miUsuarioId = ref.watch(authProvider).userMe?.id;
    final esMiCuenta = usuario.usuarioId == miUsuarioId;

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
            backgroundColor: isPendiente
                ? Colors.orange.withValues(alpha: 0.15)
                : const Color(0xFF2F3A8F).withValues(alpha: 0.1),
            child: Text(
              isPendiente && usuario.usuarioEmail.isNotEmpty
                  ? usuario.usuarioEmail[0].toUpperCase()
                  : usuario.usuarioNombre.isNotEmpty
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

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPendiente && usuario.usuarioEmail.isNotEmpty
                      ? usuario.usuarioEmail
                      : usuario.usuarioNombre,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StatusBadge(
                      label: usuario.rolDisplay,
                      color: const Color(0xFF2F3A8F),
                    ),
                    const SizedBox(width: 6),
                    StatusBadge(
                      label: isPendiente
                          ? 'Pendiente'
                          : isInactivo
                              ? 'Inactivo'
                              : 'Activo',
                      color: isPendiente
                          ? Colors.orange
                          : isInactivo
                              ? Colors.red
                              : Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(usuario.tiendaNombre,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),

          if (esDueno && !esMiCuenta)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (value) async {
                if (value == 'editar') {
                  await _mostrarEdicion(context, usuario, tiendas);
                } else if (value == 'toggle') {
                  await ref
                      .read(usuariosProvider.notifier)
                      .toggleEstado(usuario.id);
                } else if (value == 'reenviar') {
                  await _confirmarReenvio(context, usuario);
                }
              },
              itemBuilder: (ctx) => [
                if (usuario.rol != Roles.dueno)
                  const PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 18, color: Color(0xFF2F3A8F)),
                        SizedBox(width: 10),
                        Text('Editar'),
                      ],
                    ),
                  ),
                if (!esMiCuenta && !isPendiente)
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          isInactivo
                              ? Icons.check_circle_outline
                              : Icons.block_outlined,
                          size: 18,
                          color:
                              isInactivo ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 10),
                        Text(isInactivo ? 'Activar' : 'Desactivar'),
                      ],
                    ),
                  ),
                if (isPendiente)
                  const PopupMenuItem(
                    value: 'reenviar',
                    child: Row(
                      children: [
                        Icon(Icons.send_outlined,
                            size: 18, color: Colors.orange),
                        SizedBox(width: 10),
                        Text('Reenviar invitación'),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // ─── Botón de acción ─────────────────────────────────────────────────────

  Widget _buildAccionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2F3A8F),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helper dropdown filtro ───────────────────────────────────────────────

  Widget _buildDropdownFiltro<T>({
    required IconData icon,
    required String hint,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
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
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(icon, color: Colors.grey, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(hint,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}