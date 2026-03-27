import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMe = ref.watch(authProvider).userMe;
    final esDueno = userMe?.isDueno ?? false;

    return Scaffold(
      backgroundColor: const Color(0xfff3f4f6),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER - CustomAppBar Unificado
              CustomAppBar(
                title: 'Inicio',
                subtitle: 'Panel de control',
                icon: Icons.home,
                isTiendaTitle: esDueno,
              ),

              const SizedBox(height: 20),

              /// CARDS
              _card("Ventas Hoy", "\$1,250.00", "+12.5%", Colors.green),
              const SizedBox(height: 12),
              _card("Caja Actual", "\$4,800.00", "+5.2%", Colors.green),
              const SizedBox(height: 12),
              _card("Alertas de Stock", "5", "Crítico", Colors.red),

              const SizedBox(height: 24),

              /// ACCIONES RAPIDAS
              const Text(
                "Acciones Rápidas",
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  _actionButton(
                    context,
                    icon: Icons.shopping_cart,
                    label: "Nueva Venta",
                    color: AppColors.primary,
                    onTap: () => context.go('/ventas'),
                  ),
                  const SizedBox(width: 12),
                  _actionButton(
                    context,
                    icon: Icons.point_of_sale,
                    label: "Cierre Caja",
                    color: Colors.white,
                    border: true,
                    onTap: () => context.go('/caja'),
                  ),
                  if (esDueno) ...[
                    const SizedBox(width: 12),
                    _actionButton(
                      context,
                      icon: Icons.person_add_alt_1,
                      label: "Invitar",
                      color: AppColors.primary,
                      onTap: () => context.go('/invitation/new'),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              /// ACTIVIDAD RECIENTE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Actividad Reciente",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    "VER TODO",
                    style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold),
                  )
                ],
              ),

              const SizedBox(height: 16),

              _activity(
                icon: Icons.shopping_bag,
                title: "Venta completada #V-9082",
                subtitle: "Hace 5 minutos • Caja 01",
                amount: "+\$42.50",
              ),
              const SizedBox(height: 10),
              _activity(
                icon: Icons.build,
                title: "Reparación de Herramientas",
                subtitle: "Hace 1 hora • Taller",
                amount: "-\$15.00",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _card(String title, String value, String badge, Color color) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          blurRadius: 10,
          color: Colors.black.withValues(alpha: 0.05),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold),
        )
      ],
    ),
  );
}

Widget _actionButton(
  BuildContext context, {
  required IconData icon,
  required String label,
  required Color color,
  bool border = false,
  required VoidCallback onTap,
}) {
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: border ? Border.all(color: Colors.grey.shade300) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: border ? Colors.black : Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: border ? Colors.black : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    ),
  );
}

Widget _activity({
  required IconData icon,
  required String title,
  required String subtitle,
  required String amount,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.green.withValues(alpha: 0.15),
          child: Icon(icon, color: Colors.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style:
                      const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle,
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        Text(amount,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}