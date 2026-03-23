import 'package:flutter/material.dart';
import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String selectedStore = 'Todas las Tiendas';

  final List<String> stores = [
    'Todas las Tiendas',
    'Tienda Centro',
    'Tienda Norte',
    'Tienda Sur'
  ];

  @override
  Widget build(BuildContext context) {
    final esDueno = ref.watch(authProvider).userMe?.isDueno ?? false;

    return Scaffold(
      backgroundColor: const Color(0xfff3f4f6),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// HEADER
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xff1f2a7c),
                    child: Icon(Icons.store, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButton<String>(
                          value: selectedStore,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: stores.map((String store) {
                            return DropdownMenuItem<String>(
                              value: store,
                              child: Text(store),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedStore = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_none)),
                  IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.person_outline)),
                ],
              ),

              const SizedBox(height: 20),

              /// CARDS
              _card("Ingresos", "\$1,250.00", "+12.5%", Colors.green),
              const SizedBox(height: 12),
              _card("Egresos", "\$4,800.00", "+5.2%", Colors.green),
              const SizedBox(height: 12),
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
                    color: const Color(0xff1f2a7c),
                    onTap: () => context.go('/ventas'),
                  ),
                  const SizedBox(width: 12),
                  _actionButton(
                    context,
                    icon: Icons.point_of_sale,
                    label: "Cierre Caja",
                    color: Colors.white,
                    border: true,
                    onTap: () {},
                  ),
                  if (esDueno) ...[
                    const SizedBox(width: 12),
                    _actionButton(
                      context,
                      icon: Icons.person_add_alt_1,
                      label: "Invitar",
                      color: const Color(0xff1f2a7c),
                      onTap: () => context.go('/invitation/new'),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              

              
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