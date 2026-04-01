import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/core/router.dart';
import 'package:management_system_ui/features/impresora/impresora_provider.dart';
import 'package:management_system_ui/features/impresora/impresora_repository.dart';
import 'package:management_system_ui/features/impresora/ticket_converter.dart';
import 'package:management_system_ui/features/venta/services/printing_service.dart';
import 'package:path_provider/path_provider.dart';
import 'finanzas_provider.dart';
import 'models/deuda_model.dart';

class PagoResumenPage extends ConsumerStatefulWidget {
  final DeudaModel deuda;
  final String montoRegistrado;

  const PagoResumenPage({
    super.key,
    required this.deuda,
    required this.montoRegistrado,
  });

  @override
  ConsumerState<PagoResumenPage> createState() => _PagoResumenPageState();
}

class _PagoResumenPageState extends ConsumerState<PagoResumenPage> {
  bool _imprimiendo = false;
  bool _descargando = false;
  String? _mensajeError;

  @override
  Widget build(BuildContext context) {
    final pdfBytes = ref.watch(pagoPdfProvider);

    if (pdfBytes == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Comprobante de Pago')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No hay comprobante disponible'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.finanzas),
                child: const Text('Volver a finanzas'),
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
              title: 'Comprobante de Pago',
              subtitle: 'Pago registrado exitosamente',
              icon: Icons.receipt_outlined,
              onBack: () => context.go(AppRoutes.finanzasDeudas),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjeta de confirmación
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
                                    '¡Pago registrado correctamente!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Monto pagado: S/ ${widget.montoRegistrado}',
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

                      // Información de la deuda
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'ID Deuda',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${widget.deuda.id}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Monto Total',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'S/ ${widget.deuda.montoTotal}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Saldo Anterior',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'S/ ${widget.deuda.saldo}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Nuevo Saldo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'S/ ${(double.parse(widget.deuda.saldo) - double.parse(widget.montoRegistrado)).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Mensaje de error
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

                      // Botones de acción
                      OutlinedButton.icon(
                        icon: _descargando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download),
                        label: Text(
                          _descargando ? 'Descargando...' : 'Descargar PDF',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _descargando || _imprimiendo
                            ? null
                            : () => _descargarPdf(pdfBytes),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: _imprimiendo
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.print),
                        label: Text(
                          _imprimiendo ? 'Imprimiendo...' : 'Imprimir',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          disabledBackgroundColor: Colors.grey[400],
                        ),
                        onPressed: _imprimiendo || _descargando
                            ? null
                            : () => _imprimirTicket(pdfBytes),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.preview),
                        label: const Text('Ver comprobante'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _imprimiendo || _descargando
                            ? null
                            : () => _verComprobante(pdfBytes),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2F3A8F),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => context.go(AppRoutes.finanzasDeudas),
                          child: const Text(
                            'Volver a deudas',
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

  Future<void> _imprimirTicket(Uint8List pdfBytes) async {
    final config = ref.read(impresoraConfigProvider);

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
      if (pdfBytes.isEmpty) {
        throw Exception('El PDF no contiene datos');
      }

      String nombreComprobante = 'Pago-${widget.deuda.id}';

      if (mounted) {
        setState(() => _imprimiendo = false);
        await _mostrarPreviewPdf(pdfBytes, nombreComprobante, config);
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

  Future<void> _mostrarPreviewPdf(
      Uint8List bytes, String nombreComprobante, dynamic config) async {
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

  Future<void> _enviarAImpresora(Uint8List pdfBytes, dynamic config) async {
    try {
      setState(() => _imprimiendo = true);

      final comandos = await TicketConverter.pdfAEscPos(pdfBytes);
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

  Future<void> _descargarPdf(Uint8List pdfBytes) async {
    setState(() {
      _descargando = true;
      _mensajeError = null;
    });

    try {
      if (pdfBytes.isEmpty) {
        throw Exception('El PDF no contiene datos');
      }

      final dio = ref.read(dioProvider);
      final printingService = PrintingService(dio);
      final nombreArchivo = 'Pago-${widget.deuda.id}';
      await printingService.guardarPdfEnDescargas(pdfBytes, nombreArchivo);

      if (mounted) {
        setState(() => _descargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF guardado en Downloads'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
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

  Future<void> _verComprobante(Uint8List pdfBytes) async {
    try {
      if (pdfBytes.isEmpty) {
        throw Exception('El PDF no contiene datos');
      }

      if (!mounted) return;

      final nombreArchivo = 'Pago-${widget.deuda.id}';
      await _mostrarPreviewPdf(pdfBytes, nombreArchivo, null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comprobante abierto correctamente'),
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
