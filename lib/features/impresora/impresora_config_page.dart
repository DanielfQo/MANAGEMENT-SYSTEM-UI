import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/impresora/impresora_provider.dart';
import 'package:management_system_ui/features/impresora/impresora_repository.dart';
import 'package:printing/printing.dart';

class ImpresoraConfigPage extends ConsumerStatefulWidget {
  const ImpresoraConfigPage({super.key});

  @override
  ConsumerState<ImpresoraConfigPage> createState() => _ImpresoraConfigPageState();
}

class _ImpresoraConfigPageState extends ConsumerState<ImpresoraConfigPage> {
  late TextEditingController _ipController;
  late TextEditingController _puertoController;
  bool _probando = false;
  TipoConexionImpresora _tipoConexion = TipoConexionImpresora.wifi;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: '10.10.100.254');
    _puertoController = TextEditingController(text: '9100');

    final config = ref.read(impresoraConfigProvider);
    _tipoConexion = config.tipoConexion;
    if (config.ip.isNotEmpty) {
      _ipController.text = config.ip;
      _puertoController.text = config.puerto.toString();
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _puertoController.dispose();
    super.dispose();
  }

  Future<void> _probarConexionWifi() async {
    setState(() => _probando = true);

    try {
      final ip = _ipController.text.trim();
      final puerto = int.tryParse(_puertoController.text.trim()) ?? 9100;

      if (ip.isEmpty) {
        _mostrarMensaje('Ingresa la IP de la impresora', esError: true);
        return;
      }

      final repository = ref.read(impresoraRepositoryProvider);
      final conectada = await repository.probarConexion(ip, puerto);

      if (conectada) {
        await ref.read(impresoraConfigProvider.notifier).guardarConfiguracion(
          ip, puerto,
          tipoConexion: TipoConexionImpresora.wifi,
        );
        if (mounted) {
          _mostrarMensaje('Impresora conectada', esError: false);
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) context.pop();
          });
        }
      } else {
        _mostrarMensaje('No se puede conectar a la impresora', esError: true);
      }
    } catch (e) {
      _mostrarMensaje('Error: $e', esError: true);
    } finally {
      if (mounted) setState(() => _probando = false);
    }
  }

  Future<void> _guardarUsbCups() async {
    setState(() => _probando = true);

    try {
      final printers = await Printing.listPrinters();

      if (printers.isEmpty) {
        _mostrarMensaje(
          'No se encontraron impresoras del sistema. '
          'Verifica que CUPS esté configurado.',
          esError: true,
        );
        return;
      }

      await ref.read(impresoraConfigProvider.notifier).guardarConfiguracion(
        '', 0,
        tipoConexion: TipoConexionImpresora.usbCups,
      );

      if (mounted) {
        _mostrarMensaje(
          '${printers.length} impresora(s) disponible(s). Configuración guardada.',
          esError: false,
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) context.pop();
        });
      }
    } catch (e) {
      _mostrarMensaje('Error al verificar impresoras: $e', esError: true);
    } finally {
      if (mounted) setState(() => _probando = false);
    }
  }

  void _mostrarMensaje(String mensaje, {required bool esError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Configurar Impresora'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de tipo de conexión
            const Text('Tipo de conexión',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SegmentedButton<TipoConexionImpresora>(
              segments: const [
                ButtonSegment(
                  value: TipoConexionImpresora.wifi,
                  label: Text('WiFi'),
                  icon: Icon(Icons.wifi),
                ),
                ButtonSegment(
                  value: TipoConexionImpresora.usbCups,
                  label: Text('USB / Sistema'),
                  icon: Icon(Icons.usb),
                ),
              ],
              selected: {_tipoConexion},
              onSelectionChanged: (selection) {
                setState(() => _tipoConexion = selection.first);
              },
            ),
            const SizedBox(height: 24),

            // Campos según tipo de conexión
            if (_tipoConexion == TipoConexionImpresora.wifi) ...[
              const Text('Dirección IP',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _ipController,
                decoration: InputDecoration(
                  hintText: '192.168.1.100',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text('Puerto',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _puertoController,
                decoration: InputDecoration(
                  hintText: '9100',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _probando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label:
                      Text(_probando ? 'Probando...' : 'Probar Conexión'),
                  onPressed: _probando ? null : _probarConexionWifi,
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Impresión por sistema (CUPS)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Se usará el diálogo de impresión del sistema operativo. '
                      'La impresora debe estar configurada en CUPS.',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _probando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.print),
                  label: Text(_probando
                      ? 'Verificando...'
                      : 'Verificar y Guardar'),
                  onPressed: _probando ? null : _guardarUsbCups,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
