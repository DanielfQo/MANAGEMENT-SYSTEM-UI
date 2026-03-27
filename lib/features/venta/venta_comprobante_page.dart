import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/impresora/impresora_provider.dart';
import 'package:management_system_ui/features/impresora/impresora_repository.dart';
import 'package:management_system_ui/features/impresora/ticket_converter.dart';
import 'package:management_system_ui/features/venta/models/venta_read_model.dart';
import 'package:management_system_ui/features/venta/services/printing_service.dart';
import 'package:management_system_ui/features/venta/venta_flow_header.dart';
import 'package:management_system_ui/features/venta/venta_provider.dart';
import 'package:management_system_ui/features/venta/venta_repository.dart';
import 'package:path_provider/path_provider.dart';

/// Página de confirmación de venta con opciones de impresión
/// Se muestra después de crear una venta exitosamente
class VentaComprobantePage extends ConsumerStatefulWidget {
  const VentaComprobantePage({super.key});

  @override
  ConsumerState<VentaComprobantePage> createState() =>
      _VentaComprobantePageState();
}

class _VentaComprobantePageState extends ConsumerState<VentaComprobantePage> {
  bool _imprimiendo = false;
  bool _descargando = false;
  String? _mensajeError;

  @override
  Widget build(BuildContext context) {
    final ventaCreada = ref.watch(ventaProvider).ventaCreada;
    final authState = ref.watch(authProvider);
    final userMe = authState.userMe;
    final esDueno = userMe?.isDueno ?? false;

    if (ventaCreada == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Comprobante')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No hay venta registrada'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/caja/historial'),
                child: const Text('Ir al historial'),
              ),
            ],
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
              title: 'Ventas',
              subtitle: 'Comprobante',
              icon: Icons.point_of_sale,
              isTiendaTitle: esDueno,
            ),
            VentaFlowHeader(currentStep: 3, showTiendaHeader: false),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Tarjeta de confirmación ──────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green[700], size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¡Venta registrada exitosamente!',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Elige una acción para continuar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Información de la venta ──────────────────────
              _buildVentaInfoCard(ventaCreada),
              const SizedBox(height: 24),

              // ── Mensaje de error (si existe) ──────────────────
              if (_mensajeError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _mensajeError!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Botones de acción ────────────────────────────
              _buildAccionesSection(ventaCreada),
              const SizedBox(height: 24),

              // ── Botón Ir al historial ────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F3A8F),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => context.go('/caja/historial'),
                  child: const Text(
                    'Ir al historial de cajas',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
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

  /// Widget con información de la venta
  Widget _buildVentaInfoCard(VentaReadModel venta) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tipo de venta + Número comprobante + Estado SUNAT
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    venta.tipoDisplay,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (venta.tipoComprobante.isNotEmpty)
                    Chip(
                      label: Text(
                        venta.tipoComprobanteDisplay,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.blue[100],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (venta.numeroComprobante.isNotEmpty)
                Text(
                  'Comprobante: ${venta.numeroComprobante}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              // Estado SUNAT (si aplica)
              if (venta.estadoSunat != 'NO_APLICA' && venta.estadoSunat.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildEstadoSunatBadge(venta.estadoSunat, venta.estadoSunatDisplay),
                // Motivo de rechazo (si aplica)
                if (venta.estadoSunat.toUpperCase() == 'RECHAZADO' && venta.motivoRechazo.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.block, size: 16, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Motivo: ${venta.motivoRechazo}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Cliente (si existe)
          if (venta.cliente != null) ...[
            Text(
              'Cliente:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              venta.cliente!.nombre,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
          ],

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                'S/. ${venta.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F3A8F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget que muestra el estado SUNAT con color apropiado
  Widget _buildEstadoSunatBadge(String estado, String estadoDisplay) {
    Color backgroundColor;
    Color textColor;

    switch (estado.toUpperCase()) {
      case 'ENVIADO':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[900]!;
        break;
      case 'ACEPTADO':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[900]!;
        break;
      case 'RECHAZADO':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[900]!;
        break;
      case 'PENDIENTE':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[900]!;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[900]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Estado SUNAT: $estadoDisplay',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  /// Widget con botones de acciones (imprimir, descargar, ver, etc.)
  Widget _buildAccionesSection(VentaReadModel venta) {
    final tieneTicket = venta.urlPdfTicket != null && venta.urlPdfTicket!.isNotEmpty;
    final tieneAlgunPdf = tieneTicket || (venta.urlPdfA4 != null && venta.urlPdfA4!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sección de acciones principales
        Text(
          'Acciones del comprobante',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),

        // Si no hay documento disponible, mostrar mensaje
        if (!tieneAlgunPdf)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No hay documento disponible para visualizar o descargar.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),

        // ✅ Botón: Descargar PDF (solo si hay documento)
        if (tieneAlgunPdf) ...[
          OutlinedButton.icon(
            icon: _descargando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download),
            label: Text(
              _descargando ? 'Descargando...' : 'Descargar PDF',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _descargando || _imprimiendo ? null : () => _descargarPdf(venta),
          ),
          const SizedBox(height: 12),
        ],

        // ✅ Botón: Imprimir
        if (tieneAlgunPdf)
          ElevatedButton.icon(
            icon: _imprimiendo
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : const Icon(Icons.print),
            label: Text(
              _imprimiendo
                  ? 'Imprimiendo...'
                  : 'Imprimir',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 12),
              disabledBackgroundColor: Colors.grey[400],
            ),
            onPressed: _imprimiendo || _descargando ? null : () => _imprimirTicket(venta),
          ),

        if (tieneTicket) const SizedBox(height: 12),

        // Botón: Ver ticket
        if (tieneTicket)
          OutlinedButton.icon(
            icon: const Icon(Icons.preview),
            label: const Text('Ver ticket'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _imprimiendo || _descargando ? null : () => _verComprobante(venta),
          ),
      ],
    );
  }

  /// Imprime el ticket en la impresora WiFi
  /// Para SUNAT: intenta usar urlPdfTicket, si no hay usa el endpoint
  /// Para NORMAL/CREDITO: usa el endpoint /sales/ventas/{id}/ticket/
  Future<void> _imprimirTicket(VentaReadModel venta) async {
    final config = ref.read(impresoraConfigProvider);

    // Verificar que la impresora esté configurada
    if (!config.estaConfigura) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Configura la impresora primero'),
            action: SnackBarAction(
              label: 'Configurar',
              onPressed: () => context.go('/config/impresora'),
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _imprimiendo = true;
      _mensajeError = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final repository = ref.read(ventaRepositoryProvider);
      final printingService = PrintingService(dio);

      Uint8List? bytes;
      String nombreComprobante = 'Comprobante-${venta.numeroComprobante}';

      // Obtener el PDF del ticket
      if (venta.urlPdfTicket != null && venta.urlPdfTicket!.isNotEmpty) {
        bytes = await printingService.descargarPdf(venta.urlPdfTicket!);
      } else {
        bytes = await repository.descargarTicketPdf(venta.id);
      }

      if (bytes.isEmpty) {
        throw Exception('El PDF no contiene datos');
      }

      if (mounted) {
        setState(() => _imprimiendo = false);
        await _mostrarPreviewPdf(bytes, nombreComprobante, config);
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _imprimiendo = false;
          _mensajeError = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  /// Muestra un dialog con preview del PDF usando flutter_pdfview
  /// Permite al usuario ver el PDF correctamente centrado antes de imprimir
  /// Si config es null, solo muestra el PDF sin opción de imprimir
  Future<void> _mostrarPreviewPdf(Uint8List bytes, String nombreComprobante, dynamic config) async {
    // Guardar temporalmente el PDF para que flutter_pdfview pueda leerlo
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$nombreComprobante.pdf');
    await tempFile.writeAsBytes(bytes);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Scaffold(
          appBar: AppBar(
            title: Text('Vista previa de $nombreComprobante'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: PDFView(
            filePath: tempFile.path,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: false,
            pageSnap: false,
            fitPolicy: FitPolicy.WIDTH,
            preventLinkNavigation: false,
            onError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al cargar PDF: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
          bottomNavigationBar: config != null
              ? Container(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('Imprimir ahora'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        await tempFile.delete();
                      } catch (_) {}
                      await _enviarAImpresora(bytes, config);
                    },
                  ),
                )
              : null,
        ),
      ),
    );
  }

  /// Envía el PDF a la impresora WiFi
  Future<void> _enviarAImpresora(Uint8List pdfBytes, dynamic config) async {
    try {
      setState(() => _imprimiendo = true);

      // Convertir PDF a comandos ESC/POS
      final comandos = await TicketConverter.pdfAEscPos(pdfBytes);

      // Enviar a la impresora
      final repository = ref.read(impresoraRepositoryProvider);
      await repository.enviarAImpresora(config.ip, config.puerto, comandos);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enviado a imprimir'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _mensajeError = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _imprimiendo = false);
      }
    }
  }

  /// Descarga el PDF y lo guarda en la carpeta Downloads
  Future<void> _descargarPdf(VentaReadModel venta) async {
    setState(() {
      _descargando = true;
      _mensajeError = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final repository = ref.read(ventaRepositoryProvider);
      final printingService = PrintingService(dio);

      Uint8List? bytes;

      // Obtener el PDF
      if (venta.urlPdfTicket != null && venta.urlPdfTicket!.isNotEmpty) {
        // SUNAT con URL disponible: descargar desde la URL
        bytes = await printingService.descargarPdf(venta.urlPdfTicket!);
      } else {
        // NORMAL/CREDITO o SUNAT sin URL: usar endpoint
        bytes = await repository.descargarTicketPdf(venta.id);
      }

      if (bytes.isEmpty) {
        throw Exception('El PDF no contiene datos');
      }

      // Guardar en Downloads
      final nombreArchivo = 'Comprobante-${venta.numeroComprobante}';
      await printingService.guardarPdfEnDescargas(
        bytes,
        nombreArchivo,
      );

      if (mounted) {
        setState(() => _descargando = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF guardado en Downloads'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _descargando = false;
          _mensajeError = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  /// Descarga y muestra el ticket en un dialog con previsualizador
  Future<void> _verComprobante(VentaReadModel venta) async {
    if (venta.urlPdfTicket == null || venta.urlPdfTicket!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay ticket disponible'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final dio = ref.read(dioProvider);
      final printingService = PrintingService(dio);

      // Mostrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Descargando ticket...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Descargar el PDF
      Uint8List bytes;
      if (venta.urlPdfTicket!.isNotEmpty) {
        bytes = await printingService.descargarPdf(venta.urlPdfTicket!);
      } else {
        throw Exception('No hay URL disponible para el ticket');
      }

      if (bytes.isEmpty) {
        throw Exception('El PDF no contiene datos');
      }

      if (!mounted) return;

      // Mostrar el PDF en un dialog con previsualizador
      final nombreArchivo = 'Ticket-${venta.numeroComprobante}';
      await _mostrarPreviewPdf(bytes, nombreArchivo, null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket abierto correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _mensajeError = e.toString().replaceAll('Exception: ', '');
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_mensajeError!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
