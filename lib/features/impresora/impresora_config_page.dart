import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/impresora/impresora_provider.dart';
import 'package:management_system_ui/features/impresora/impresora_repository.dart';

class ImpresoraConfigPage extends ConsumerStatefulWidget {
  const ImpresoraConfigPage({super.key});

  @override
  ConsumerState<ImpresoraConfigPage> createState() => _ImpresoraConfigPageState();
}

class _ImpresoraConfigPageState extends ConsumerState<ImpresoraConfigPage> {
  late TextEditingController _ipController;
  late TextEditingController _puertoController;
  bool _probando = false;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController();
    _puertoController = TextEditingController(text: '9100');

    // Cargar configuración guardada
    final config = ref.read(impresoraConfigProvider);
    if (config.estaConfigura) {
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

  Future<void> _probarConexion() async {
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
        await ref.read(impresoraConfigProvider.notifier).guardarConfiguracion(ip, puerto);
        if (mounted) {
          _mostrarMensaje('Impresora conectada', esError: false);
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.pop(context);
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
      appBar: AppBar(title: const Text('Configurar Impresora')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dirección IP', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                hintText: '192.168.1.100',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text('Puerto', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _puertoController,
              decoration: InputDecoration(
                hintText: '9100',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_probando ? 'Probando...' : 'Probar Conexión'),
                onPressed: _probando ? null : _probarConexion,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
