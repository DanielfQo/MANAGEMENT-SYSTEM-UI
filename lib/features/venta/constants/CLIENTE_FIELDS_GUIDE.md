# Guía de Campos de Cliente por Tipo de Venta

## Estructura de ClienteNuevoInput

Todos los campos en `ClienteNuevoInput` son **requeridos en el constructor** para que se vean como campos obligatorios en la UI. Sin embargo, en la validación, solo se exigen los campos necesarios según el tipo de venta.

```dart
ClienteNuevoInput(
  nombre: 'Juan Pérez',              // ✅ Siempre requerido
  tipoDocumento: '1',                // Requerido para: CREDITO, SUNAT Factura
  numeroDocumento: '12345678',       // Requerido para: CREDITO, SUNAT Boleta, SUNAT Factura
  telefono: '987654321',             // Requerido para: CREDITO
  email: 'juan@gmail.com',           // Requerido para: CREDITO
  direccion: 'Av. Principal 123',    // Requerido para: CREDITO
)
```

---

## Valores Vacíos por Tipo de Venta

Para tipos de venta donde algunos campos son opcionales, pasa strings vacíos:

### NORMAL
```dart
final cliente = ClienteNuevoInput(
  nombre: nombreInput,
  tipoDocumento: '',              // ← Opcional: pasar vacío
  numeroDocumento: '',            // ← Opcional: pasar vacío
  telefono: '',                   // ← Opcional: pasar vacío
  email: '',                      // ← Opcional: pasar vacío
  direccion: '',                  // ← Opcional: pasar vacío
);
```

### CREDITO
```dart
final cliente = ClienteNuevoInput(
  nombre: nombreInput,
  tipoDocumento: tipoDocumentoInput,  // ✅ Requerido
  numeroDocumento: numeroDocumentoInput, // ✅ Requerido
  telefono: telefonoInput,            // ✅ Requerido
  email: emailInput,                  // ✅ Requerido
  direccion: direccionInput,          // ✅ Requerido
);
```

### SUNAT BOLETA
```dart
final cliente = ClienteNuevoInput(
  nombre: nombreInput,
  tipoDocumento: tipoDocumentoInput,  // ← Opcional (default "1", no puede ser "6")
  numeroDocumento: numeroDocumentoInput, // ✅ Requerido
  telefono: '',                       // ← Opcional: pasar vacío
  email: '',                          // ← Opcional: pasar vacío
  direccion: '',                      // ← Opcional: pasar vacío
);
```

### SUNAT FACTURA
```dart
final cliente = ClienteNuevoInput(
  nombre: nombreInput,
  tipoDocumento: '6',                 // ✅ Requerido = RUC
  numeroDocumento: rucInput,          // ✅ Requerido (11 dígitos)
  telefono: telefonoInput ?? '',      // ← Opcional
  email: emailInput ?? '',            // ← Opcional
  direccion: direccionInput ?? '',    // ← Opcional
);
```

---

## Usar ClienteFormConfig para Mostrar/Ocultar Campos

```dart
import 'package:management_system_ui/features/venta/constants/cliente_form_config.dart';

final config = ClienteFormConfig.getConfig(tipoVenta);

// Mostrar o no el campo según si es requerido
Visibility(
  visible: config.esRequerido('tipoDocumento'),
  child: TextField(
    label: 'Tipo de Documento',
    // ...
  ),
);
```

---

## Filtrar Clientes con RUC para SUNAT Factura

Para permitir al usuario seleccionar un cliente existente en SUNAT Factura, filtra solo clientes con RUC:

### Usando el FutureProvider
```dart
import 'package:management_system_ui/features/venta/venta_provider.dart';

// En el widget:
final clientesAsync = ref.watch(clientesConRucProvider);

clientesAsync.when(
  data: (clientes) => DropdownButton(
    items: clientes.map((cliente) {
      return DropdownMenuItem(
        value: cliente.id,
        child: Text(cliente.nombre),
      );
    }).toList(),
    onChanged: (clienteId) {
      // ...
    },
  ),
  loading: () => CircularProgressIndicator(),
  error: (error, _) => Text('Error: $error'),
);
```

### Usando el método del repositorio directamente
```dart
final repository = ref.watch(ventaRepositoryProvider);
final tiendaId = ref.read(authProvider).selectedTiendaId!;
final clientesConRuc = await repository.getClientesConRuc(tiendaId);
```

---

## Validación Automática

Cuando se llama a `VentaRepository.crearVenta(venta)`, automáticamente se valida:

```dart
try {
  await repository.crearVenta(ventaModel);
} catch (e) {
  // Error: "Nombre de cliente es requerido para crédito"
  // Error: "Tipo de documento DEBE ser RUC (tipo_documento: 6) para factura"
  // etc.
}
```

Los mensajes de error son específicos según el tipo de venta y campo que falta.

---

## Resumen de Campos Requeridos en UI

| Campo | NORMAL | CREDITO | BOLETA | FACTURA |
|-------|--------|---------|--------|---------|
| `nombre` | ✅ | ✅ | ✅ | ✅ |
| `tipoDocumento` | ❌ | ✅ | ❌* | ✅ (="6") |
| `numeroDocumento` | ❌ | ✅ | ✅ | ✅ (11 dígitos) |
| `telefono` | ❌ | ✅ | ❌ | ❌ |
| `email` | ❌ | ✅ | ❌ | ❌ |
| `direccion` | ❌ | ✅ | ❌ | ❌ |

*BOLETA: tipoDocumento es opcional pero NO puede ser "6" (RUC)
