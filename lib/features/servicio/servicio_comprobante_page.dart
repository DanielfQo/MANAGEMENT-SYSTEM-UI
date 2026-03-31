import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/impresora/impresora_provider.dart';
import 'package:management_system_ui/features/impresora/impresora_repository.dart';
import 'package:management_system_ui/features/impresora/ticket_converter.dart';
import 'package:management_system_ui/features/servicio/models/servicio_read_model.dart';
import 'package:management_system_ui/features/servicio/servicio_flow_header.dart';
import 'package:management_system_ui/features/servicio/servicio_provider.dart';
import 'package:management_system_ui/features/servicio/servicio_repository.dart';
import 'package:management_system_ui/features/venta/services/printing_service.dart';
import 'package:path_provider/path_provider.dart';

class ServicioComprobantePage extends ConsumerStatefulWidget {
  const ServicioComprobantePage({super.key});

  @override
  ConsumerState<ServicioComprobantePage> createState() =>
      _ServicioComprobantePageState();
}

class _ServicioComprobantePageState
    extends ConsumerState<ServicioComprobantePage> {
  bool _imprimiendo = false;
  bool _descargando = false;
  String? _mensajeError;

  @override
  Widget build(BuildContext context) {
    final servicioCreado = ref.watch(servicioProvider).servicioCreado;
    final authState = ref.watch(authProvider);
    final esDueno = authState.userMe?.isDueno ?? false;

    if (servicioCreado == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Comprobante')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No hay servicio registrado'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/operaciones'),
                child: const Text('Ir a operaciones'),
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
              title: 'Servicios',
              subtitle: 'Comprobante',
              icon: Icons.build,
              isTiendaTitle: esDueno,
            ),
            const ServicioFlowHeader(currentStep: 2, showTiendaHeader: false),
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
                                    '¡Servicio registrado exitosamente!',
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

                      // Información del servicio
                      _buildServicioInfoCard(servicioCreado),
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
                      _buildAccionesSection(servicioCreado),
                      const SizedBox(height: 24),

                      // Botón Ir a operaciones
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2F3A8F),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => context.go('/operaciones'),
                          child: const Text(
                            'Volver a operaciones',
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

  Widget _buildServicioInfoCard(ServicioReadModel servicio) {
    return Container(
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
              Text(
                servicio.tipoDisplay.isNotEmpty
                    ? servicio.tipoDisplay
                    : servicio.tipo,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (servicio.tipoComprobante.isNotEmpty)
                Chip(
                  label: Text(
                    servicio.tipoComprobanteDisplay.isNotEmpty
                        ? servicio.tipoComprobanteDisplay
                        : servicio.tipoComprobante,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.blue[100],
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (servicio.numeroComprobante.isNotEmpty)
            Text(
              'Comprobante: ${servicio.numeroComprobante}',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),

          // Estado SUNAT
          if (servicio.estadoSunat != 'NO_APLICA' &&
              servicio.estadoSunat.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildEstadoSunatBadge(
              servicio.estadoSunat,
              servicio.estadoSunatDisplay.isNotEmpty
                  ? servicio.estadoSunatDisplay
                  : servicio.estadoSunat,
            ),
            if (servicio.estadoSunat.toUpperCase() == 'RECHAZADO' &&
                servicio.motivoRechazo.isNotEmpty) ...[
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
                        'Motivo: ${servicio.motivoRechazo}',
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
          const SizedBox(height: 16),

          // Descripción
          if (servicio.descripcion.isNotEmpty) ...[
            Text(
              'Descripción:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              servicio.descripcion,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
          ],

          // Fechas
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inicio:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      servicio.fechaInicio,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fin:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      servicio.fechaFin,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cliente
          if (servicio.cliente != null) ...[
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
              servicio.cliente!.nombre,
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
                'S/. ${servicio.total.toStringAsFixed(2)}',
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

  Widget _buildAccionesSection(ServicioReadModel servicio) {
    final esNormalOCredito =
        servicio.tipo == 'NORMAL' || servicio.tipo == 'CREDITO';
    final tieneTicket = esNormalOCredito ||
        (servicio.urlPdfTicket != null && servicio.urlPdfTicket!.isNotEmpty);
    final tieneAlgunPdf = tieneTicket ||
        (servicio.urlPdfA4 != null && servicio.urlPdfA4!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Acciones del comprobante',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),

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

        if (tieneAlgunPdf) ...[
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
                : () => _descargarPdf(servicio),
          ),
          const SizedBox(height: 12),
        ],

        if (tieneAlgunPdf)
          ElevatedButton.icon(
            icon: _imprimiendo
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                : () => _imprimirTicket(servicio),
          ),

        if (tieneTicket) const SizedBox(height: 12),

        if (tieneTicket)
          OutlinedButton.icon(
            icon: const Icon(Icons.preview),
            label: const Text('Ver ticket'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _imprimiendo || _descargando
                ? null
                : () => _verComprobante(servicio),
          ),
      ],
    );
  }

  Future<void> _imprimirTicket(ServicioReadModel servicio) async {
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
      Uint8List bytes;

      if (servicio.urlPdfTicket != null &&
          servicio.urlPdfTicket!.isNotEmpty) {
        // SUNAT: usar URL del JSON response
        final dio = ref.read(dioProvider);
        final printingService = PrintingService(dio);
        bytes = await printingService.descargarPdf(servicio.urlPdfTicket!);
      } else {
        // NORMAL/CREDITO: llamar endpoint /ticket/
        final repository = ref.read(servicioRepositoryProvider);
        bytes = await repository.descargarTicketPdf(servicio.numeroComprobante);
      }

      if (bytes.isEmpty) {
        throw Exception('El PDF no contiene datos');
      }

      String nombreComprobante = 'Comprobante-${servicio.numeroComprobante}';

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

  Future<void> _descargarPdf(ServicioReadModel servicio) async {
    setState(() {
      _descargando = true;
      _mensajeError = null;
    });

    try {
      Uint8List bytes;

      if (servicio.urlPdfTicket != null &&
          servicio.urlPdfTicket!.isNotEmpty) {
        // SUNAT: usar URL del JSON response
        final dio = ref.read(dioProvider);
        final printingService = PrintingService(dio);
        bytes = await printingService.descargarPdf(servicio.urlPdfTicket!);
      } else {
        // NORMAL/CREDITO: llamar endpoint /ticket/
        final repository = ref.read(servicioRepositoryProvider);
        bytes = await repository.descargarTicketPdf(servicio.numeroComprobante);
      }

      if (bytes.isEmpty) {
        throw Exception('El PDF no contiene datos');
      }

      final dio = ref.read(dioProvider);
      final printingService = PrintingService(dio);
      final nombreArchivo = 'Comprobante-${servicio.numeroComprobante}';
      await printingService.guardarPdfEnDescargas(bytes, nombreArchivo);

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

  Future<void> _verComprobante(ServicioReadModel servicio) async {
    try {
      Uint8List bytes;

      if (servicio.urlPdfTicket != null &&
          servicio.urlPdfTicket!.isNotEmpty) {
        // SUNAT: usar URL del JSON response
        final dio = ref.read(dioProvider);
        final printingService = PrintingService(dio);
        bytes = await printingService.descargarPdf(servicio.urlPdfTicket!);
      } else {
        // NORMAL/CREDITO: llamar endpoint /ticket/
        final repository = ref.read(servicioRepositoryProvider);
        bytes = await repository.descargarTicketPdf(servicio.numeroComprobante);
      }

      if (bytes.isEmpty) {
        throw Exception('El PDF no contiene datos');
      }

      if (!mounted) return;

      final nombreArchivo = 'Ticket-${servicio.numeroComprobante}';
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
