import 'package:management_system_ui/core/common_libs.dart';
import '../models/producto_catalogo_model.dart';
import '../constants/unidad_medida.dart';

/// Detalle simplificado de producto desde catálogo (solo lectura)
class ProductoDetailSheetCatalogo extends StatelessWidget {
  final ProductoCatalogoModel producto;
  final bool isDueno;

  const ProductoDetailSheetCatalogo({
    required this.producto,
    required this.isDueno,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cantidadAveriada = double.tryParse(producto.cantidadAveriada) ?? 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2F3A8F).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2F3A8F),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Código: ${producto.codigo}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          // Contenido
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Disponibilidad
                _buildSection(
                  'Disponibilidad',
                  [
                    _buildRow(
                      'Cantidad disponible',
                      '${producto.cantidadDisponible} ${UnidadMedida.getLabel(producto.unidadMedida)}',
                      Color.fromARGB(255, 76, 175, 80),
                    ),
                    if (cantidadAveriada > 0)
                      _buildRow(
                        'Cantidad averiada',
                        '${producto.cantidadAveriada} ${UnidadMedida.getLabel(producto.unidadMedida)}',
                        Colors.orange,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Precios
                _buildSection(
                  'Precios',
                  [
                    _buildRow(
                      'Precio venta mercado',
                      'S/. ${producto.precioVentaMercado}',
                      const Color(0xFF2F3A8F),
                    ),
                    if (isDueno && producto.precioVentaBase != null)
                      _buildRow(
                        'Precio venta base',
                        'S/. ${(producto.precioVentaBase is num ? (producto.precioVentaBase as num).toStringAsFixed(2) : producto.precioVentaBase)}',
                        Colors.grey[700]!,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Información de factura
                _buildSection(
                  'Facturación',
                  [
                    _buildRow(
                      'Con factura',
                      producto.tieneConFactura ? 'Sí' : 'No',
                      producto.tieneConFactura ? Colors.green : Colors.red,
                    ),
                    _buildRow(
                      'Sin factura',
                      producto.tieneSinFactura ? 'Sí' : 'No',
                      producto.tieneSinFactura ? Colors.green : Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Estado
                _buildSection(
                  'Estado',
                  [
                    _buildRow(
                      'Activo',
                      producto.isActive ? 'Sí' : 'No',
                      producto.isActive ? Colors.green : Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Otros
                _buildSection(
                  'Otros',
                  [
                    _buildRow('Tipo IGV', producto.tipoIgv, Colors.grey[700]!),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2F3A8F),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
