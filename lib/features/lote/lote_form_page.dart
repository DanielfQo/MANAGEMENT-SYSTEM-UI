import 'package:flutter/services.dart';
import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'models/lote_model.dart';
import 'models/producto_model.dart';
import 'lote_provider.dart';
import 'constants/unidad_medida.dart';

class LoteFormPage extends ConsumerStatefulWidget {
  const LoteFormPage({super.key});

  @override
  ConsumerState<LoteFormPage> createState() => _LoteFormPageState();
}

class _LoteFormPageState extends ConsumerState<LoteFormPage> {
  late final TextEditingController _fechaCtrl;
  late final TextEditingController _costoOperacionCtrl;
  late final TextEditingController _costoTransporteCtrl;
  late final TextEditingController _cantidadCtrl;
  late final TextEditingController _cantidadAveriadaCtrl;
  late final TextEditingController _costoTotalCtrl;
  late final TextEditingController _precioVentaBaseCtrl;
  late final TextEditingController _precioVentaMercadoCtrl;
  late final TextEditingController _nuevoNombreCtrl;

  late final GlobalKey<FormState> _formKey;
  String _unidadMedidaSeleccionada = UnidadMedida.unidad;
  bool _conFactura = true;
  int? _selectedProductoId;
  bool _usarProductoExistente = true;
  final List<LoteProductoInput> _productosAgregados = [];

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _fechaCtrl = TextEditingController();
    _costoOperacionCtrl = TextEditingController();
    _costoTransporteCtrl = TextEditingController();
    _cantidadCtrl = TextEditingController();
    _cantidadAveriadaCtrl = TextEditingController(); // Vacío por defecto
    _costoTotalCtrl = TextEditingController();
    _precioVentaBaseCtrl = TextEditingController();
    _precioVentaMercadoCtrl = TextEditingController();
    _nuevoNombreCtrl = TextEditingController();

    Future.microtask(() {
      ref.read(inventarioProvider.notifier).cargarProductos();
    });
  }

  @override
  void dispose() {
    _fechaCtrl.dispose();
    _costoOperacionCtrl.dispose();
    _costoTransporteCtrl.dispose();
    _cantidadCtrl.dispose();
    _cantidadAveriadaCtrl.dispose();
    _costoTotalCtrl.dispose();
    _precioVentaBaseCtrl.dispose();
    _precioVentaMercadoCtrl.dispose();
    _nuevoNombreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDueno = ref.watch(authProvider).userMe?.isDueno ?? false;
    final tiendaId = ref.watch(authProvider).selectedTiendaId;
    final productos = ref.watch(inventarioProvider).productos;
    final isSaving = ref.watch(inventarioProvider).isSaving;

    ref.listen(inventarioProvider, (previous, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(next.successMessage!)),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        ref.read(inventarioProvider.notifier).clearMessages();
        final router = GoRouter.of(context);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          router.go('/lotes/lista');
        });
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(next.errorMessage!)),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        ref.read(inventarioProvider.notifier).clearMessages();
      }
    });

    if (!isDueno || tiendaId == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Text(
              isDueno ? 'Selecciona una tienda' : 'Sin permiso',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Nuevo Lote',
              subtitle: 'Registra un lote de productos',
              icon: Icons.add_box_outlined,
              onBack: () => context.go('/lotes'),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Section 1: Datos del lote
                      _sectionTitle('Datos del Lote'),
                      const SizedBox(height: 16),

                      _buildDateField(context),
                      const SizedBox(height: 16),

                      _buildNumberField(
                        controller: _costoOperacionCtrl,
                        label: 'Costo Operación',
                        prefixIcon: Icons.money,
                        prefixText: 'S/. ',
                      ),
                      const SizedBox(height: 16),

                      _buildNumberField(
                        controller: _costoTransporteCtrl,
                        label: 'Costo Transporte',
                        prefixIcon: Icons.local_shipping,
                        prefixText: 'S/. ',
                      ),

                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 20),

                      // Section 2: Agregar Producto
                      _sectionTitle('Agregar Producto'),
                      const SizedBox(height: 16),

                      // Toggle existente/nuevo
                      _buildProductToggle(),
                      const SizedBox(height: 16),

                      // Producto selector o nombre input
                      if (_usarProductoExistente)
                        _buildProductDropdown(productos)
                      else
                        _buildTextFormField(
                          controller: _nuevoNombreCtrl,
                          label: 'Nombre del Producto',
                          hint: 'Ej: Cable electrico 2.5mm',
                          prefixIcon: Icons.label,
                        ),

                      const SizedBox(height: 16),

                      // Unidad de medida
                      _buildUnitDropdown(),
                      const SizedBox(height: 16),

                      // Con factura
                      _buildFacturaSwitch(),
                      const SizedBox(height: 16),

                      // Cantidad
                      _buildDecimalField(
                        controller: _cantidadCtrl,
                        label: 'Cantidad',
                        prefixIcon: Icons.production_quantity_limits,
                      ),
                      const SizedBox(height: 16),

                      // Cantidad averiada
                      _buildDecimalField(
                        controller: _cantidadAveriadaCtrl,
                        label: 'Cantidad Averiada',
                        prefixIcon: Icons.warning_outlined,
                      ),
                      const SizedBox(height: 16),

                      // Costo total
                      _buildNumberField(
                        controller: _costoTotalCtrl,
                        label: 'Costo Total',
                        prefixIcon: Icons.money,
                        prefixText: 'S/. ',
                      ),
                      const SizedBox(height: 16),

                      // Precio venta mercado
                      _buildNumberField(
                        controller: _precioVentaMercadoCtrl,
                        label: 'Precio Venta Mercado',
                        prefixIcon: Icons.price_change,
                        prefixText: 'S/. ',
                      ),
                      const SizedBox(height: 16),

                      // Precio venta base (solo dueño)
                      if (isDueno)
                        _buildNumberField(
                          controller: _precioVentaBaseCtrl,
                          label: 'Precio Venta Base',
                          prefixIcon: Icons.discount,
                          prefixText: 'S/. ',
                        ),

                      const SizedBox(height: 20),

                      // Agregar button
                      _buildAgregarButton(),
                      const SizedBox(height: 24),

                      // Productos agregados
                      if (_productosAgregados.isNotEmpty) ...[
                        _sectionTitle(
                          'Productos Agregados (${_productosAgregados.length})',
                        ),
                        const SizedBox(height: 12),
                        ..._productosAgregados.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final producto = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          producto.nombre ??
                                              'Producto ${producto.productoId}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Cant: ${producto.cantidad} • S/. ${producto.costoTotal}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _productosAgregados.removeAt(idx);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                      ] else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'Aún no agregaste productos',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),

                      // Submit button
                      _buildGuardarButton(isDueno, tiendaId, isSaving),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widgets

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    return TextFormField(
      controller: _fechaCtrl,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Fecha de Llegada',
        prefixIcon: const Icon(Icons.calendar_today,
            color: Color(0xFF1F2A7C)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1F2A7C)),
        ),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          _fechaCtrl.text =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecciona una fecha';
        }
        if (DateTime.tryParse(value) == null) {
          return 'Fecha inválida';
        }
        return null;
      },
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF1F2A7C)),
        prefixText: prefixText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1F2A7C)),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo es requerido';
        }
        if (double.tryParse(value) == null) {
          return 'Ingresa un número válido';
        }
        if (double.parse(value) <= 0) {
          return 'Debe ser mayor a 0';
        }
        return null;
      },
    );
  }

  Widget _buildDecimalField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Déjalo vacío para 0',
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF1F2A7C)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1F2A7C)),
        ),
      ),
      validator: (value) {
        // Si está vacío, válido (se envía como 0)
        if (value == null || value.isEmpty) {
          return null;
        }
        if (double.tryParse(value) == null) {
          return 'Ingresa un número válido';
        }
        if (double.parse(value) < 0) {
          return 'No puede ser negativo';
        }
        return null;
      },
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF1F2A7C)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1F2A7C)),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo es requerido';
        }
        return null;
      },
    );
  }

  Widget _buildProductToggle() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: _usarProductoExistente
                  ? const Color(0xFF1F2A7C)
                  : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(
                color: _usarProductoExistente
                    ? const Color(0xFF1F2A7C)
                    : Colors.grey[300]!,
              ),
            ),
            onPressed: () {
              setState(() {
                _usarProductoExistente = true;
                _selectedProductoId = null;
                _nuevoNombreCtrl.clear();
              });
            },
            child: Text(
              'Existente',
              style: TextStyle(
                color: _usarProductoExistente ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: !_usarProductoExistente
                  ? const Color(0xFF1F2A7C)
                  : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(
                color: !_usarProductoExistente
                    ? const Color(0xFF1F2A7C)
                    : Colors.grey[300]!,
              ),
            ),
            onPressed: () {
              setState(() {
                _usarProductoExistente = false;
                _selectedProductoId = null;
                _nuevoNombreCtrl.clear();
              });
            },
            child: Text(
              'Nuevo',
              style: TextStyle(
                color: !_usarProductoExistente ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductDropdown(List<ProductoModel> productos) {
    return DropdownButtonFormField<int>(
      initialValue: _selectedProductoId,
      decoration: InputDecoration(
        labelText: 'Selecciona un producto',
        prefixIcon: const Icon(Icons.shopping_cart,
            color: Color(0xFF1F2A7C)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1F2A7C)),
        ),
      ),
      items: productos.map((prod) {
        return DropdownMenuItem<int>(
          value: prod.id,
          child: Text(
            prod.nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedProductoId = value);
      },
      validator: (value) {
        if (_usarProductoExistente && value == null) {
          return 'Selecciona un producto';
        }
        return null;
      },
    );
  }

  Widget _buildUnitDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _unidadMedidaSeleccionada,
      decoration: InputDecoration(
        labelText: 'Unidad de Medida',
        prefixIcon:
            const Icon(Icons.straighten, color: Color(0xFF1F2A7C)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1F2A7C)),
        ),
      ),
      items: UnidadMedida.values.map((code) {
        return DropdownMenuItem<String>(
          value: code,
          child: Text(UnidadMedida.getLabel(code)),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _unidadMedidaSeleccionada = value);
        }
      },
    );
  }

  Widget _buildFacturaSwitch() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Con factura',
            style: TextStyle(fontSize: 14),
          ),
          Switch(
            value: _conFactura,
            onChanged: (value) {
              setState(() => _conFactura = value);
            },
            activeThumbColor: const Color(0xFF1F2A7C),
          ),
        ],
      ),
    );
  }

  Widget _buildAgregarButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.add_circle, color: Colors.white),
        label: const Text(
          'Agregar Producto',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: _agregarProducto,
      ),
    );
  }

  void _agregarProducto() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validaciones específicas
    final cantidad = double.tryParse(_cantidadCtrl.text);
    final cantidadAveriada = double.tryParse(_cantidadAveriadaCtrl.text);
    final precioMercado = double.tryParse(_precioVentaMercadoCtrl.text);
    final precioBase =
        _precioVentaBaseCtrl.text.isNotEmpty
            ? double.tryParse(_precioVentaBaseCtrl.text)
            : null;

    if (cantidadAveriada != null &&
        cantidad != null &&
        cantidadAveriada > cantidad) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La cantidad averiada no puede ser mayor a la cantidad total'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (precioBase != null &&
        precioMercado != null &&
        precioBase > precioMercado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El precio base no puede ser mayor al precio de mercado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Chequear duplicados
    if (_usarProductoExistente && _selectedProductoId != null) {
      if (_productosAgregados.any((p) => p.productoId == _selectedProductoId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este producto ya fue agregado'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // Crear el producto
    final nuevoProducto = LoteProductoInput(
      productoId: _usarProductoExistente ? _selectedProductoId : null,
      nombre: !_usarProductoExistente ? _nuevoNombreCtrl.text : null,
      unidadMedida: _unidadMedidaSeleccionada,
      conFactura: _conFactura,
      cantidad: _cantidadCtrl.text,
      cantidadAveriada: _cantidadAveriadaCtrl.text.isEmpty ? '0.000' : _cantidadAveriadaCtrl.text,
      costoTotal: _costoTotalCtrl.text,
      precioVentaBase:
          _precioVentaBaseCtrl.text.isNotEmpty
              ? _precioVentaBaseCtrl.text
              : null,
      precioVentaMercado: _precioVentaMercadoCtrl.text,
    );

    setState(() {
      _productosAgregados.add(nuevoProducto);
      // Limpiar campos
      _selectedProductoId = null;
      _nuevoNombreCtrl.clear();
      _cantidadCtrl.clear();
      _cantidadAveriadaCtrl.clear();
      _costoTotalCtrl.clear();
      _precioVentaBaseCtrl.clear();
      _precioVentaMercadoCtrl.clear();
    });
  }

  Widget _buildGuardarButton(
    bool isDueno,
    int? tiendaId,
    bool isSaving,
  ) {
    final enabled = _productosAgregados.isNotEmpty &&
        _fechaCtrl.text.isNotEmpty &&
        !isSaving;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F2A7C),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: enabled
            ? () => _mostrarConfirmacion()
            : null,
        child: isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'GUARDAR LOTE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _mostrarConfirmacion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber[700],
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Confirmar creación'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estás a punto de registrar un lote con ${_productosAgregados.length} producto(s).',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  border: Border.all(color: Colors.amber[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Los lotes no pueden modificarse una vez guardados. Verifica que todos los datos sean correctos antes de continuar.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Productos a registrar:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ..._productosAgregados.take(3).map((p) {
                return Text(
                  '• ${p.nombre ?? 'Producto ${p.productoId}'}',
                  style: const TextStyle(fontSize: 12),
                );
              }),
              if (_productosAgregados.length > 3)
                Text(
                  'y ${_productosAgregados.length - 3} más',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F2A7C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _guardarLote();
            },
            child: const Text('Confirmar y guardar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _guardarLote() {
    final tiendaId = ref.read(authProvider).selectedTiendaId;
    if (tiendaId == null) return;

    final lote = LoteCreateModel(
      tienda: tiendaId,
      fechaLlegada: _fechaCtrl.text,
      costoOperacion: _costoOperacionCtrl.text,
      costoTransporte: _costoTransporteCtrl.text,
      productos: _productosAgregados,
    );

    ref.read(inventarioProvider.notifier).crearLote(lote);
  }
}
