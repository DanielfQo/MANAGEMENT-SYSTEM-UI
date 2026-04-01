import 'package:management_system_ui/core/common_libs.dart';

class FinanzasHubPage extends ConsumerWidget {
  const FinanzasHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Column(
          children: [
            const CustomAppBar(
              title: 'Finanzas',
              subtitle: 'Gestiona caja, deudas, pagos y gastos',
              icon: Icons.account_balance_wallet_outlined,
              isTiendaTitle: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  children: [
                    _NavCard(
                      icon: Icons.payment_outlined,
                      title: 'Caja',
                      subtitle: 'Resumen del día y cierre de caja',
                      onTap: () => context.go('/finanzas/caja/resumen'),
                    ),
                    const SizedBox(height: 12),
                    _NavCard(
                      icon: Icons.receipt_long_outlined,
                      title: 'Deudas y Pagos',
                      subtitle: 'Gestiona deudas, registra pagos',
                      onTap: () => context.go('/finanzas/deudas'),
                    ),
                    const SizedBox(height: 12),
                    _NavCard(
                      icon: Icons.trending_down_outlined,
                      title: 'Gastos',
                      subtitle: 'Gastos fijos y variables del negocio',
                      onTap: () => context.go('/finanzas/gastos'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2F3A8F).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2F3A8F),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
