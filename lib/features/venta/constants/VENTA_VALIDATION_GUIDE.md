# Guía de Validación de Ventas

## Resumen de Campos por Tipo de Venta

### VENTA NORMAL
- **Cliente**: Opcional
- **tipo_comprobante**: No aplica

**Cliente nuevo (si se envía):**
- `nombre`: ✅ Requerido
- `tipo_documento`: ❌ Opcional (default "1" - DNI)
- `numero_documento`: ❌ Opcional
- `telefono`: ❌ Opcional
- `email`: ❌ Opcional
- `direccion`: ❌ Opcional

---

### VENTA CREDITO
- **Cliente**: ✅ Requerido (nuevo o existente)
- **tipo_comprobante**: No aplica

**Cliente nuevo (todos requeridos):**
- `nombre`: ✅ Requerido
- `tipo_documento`: ✅ Requerido
- `numero_documento`: ✅ Requerido
- `telefono`: ✅ Requerido
- `email`: ✅ Requerido
- `direccion`: ✅ Requerido

---

### VENTA SUNAT - BOLETA (tipo_comprobante: "03")
- **Cliente**: ❌ Opcional (usa "CLIENTE VARIOS" si no se envía)
- **tipo_comprobante**: ✅ Requerido = "03"

**Cliente nuevo (si se envía):**
- `nombre`: ✅ Requerido
- `tipo_documento`: ❌ Opcional (default "1" - DNI) **NO puede ser "6" (RUC)**
- `numero_documento`: ✅ Requerido
- `telefono`: ❌ Opcional
- `email`: ❌ Opcional
- `direccion`: ❌ Opcional (usa "-" por defecto)

---

### VENTA SUNAT - FACTURA (tipo_comprobante: "01")
- **Cliente**: ✅ Requerido (nuevo o existente con RUC)
- **tipo_comprobante**: ✅ Requerido = "01"

**Cliente nuevo:**
- `nombre`: ✅ Requerido
- `tipo_documento`: ✅ Requerido = "6" (RUC)
- `numero_documento`: ✅ Requerido (RUC de 11 dígitos)
- `telefono`: ❌ Opcional
- `email`: ❌ Opcional
- `direccion`: ❌ Opcional (usa "-" por defecto)

---

## Cómo usar en las páginas

### 1. Importar el configurador
```dart
import 'package:management_system_ui/features/venta/constants/cliente_form_config.dart';
```

### 2. Obtener configuración según tipo de venta
```dart
final config = ClienteFormConfig.getConfig(tipoVenta);

// O para SUNAT con comprobante específico:
final config = ClienteFormConfig.getConfig('SUNAT_BOLETA');
final config = ClienteFormConfig.getConfig('SUNAT_FACTURA');
```

### 3. Usar en el formulario
```dart
final isClienteOpcional = ClienteFormConfig.esClienteOpcional(tipoVenta);

// Para cada campo de cliente:
TextField(
  label: '${config.esRequerido("nombre") ? "*" : ""} Nombre',
  // ...
)

// O mostrar solo campos requeridos:
for (final campo in config.camposRequeridos) {
  // buildCampoCliente(campo, config)
}
```

### 4. Campos de cliente por tipo
```dart
// NORMAL - mostrar solo nombre como requerido
if (tipoVenta == 'NORMAL') {
  buildClienteNormal(); // nombre requerido
}

// CREDITO - mostrar todos los campos como requeridos
else if (tipoVenta == 'CREDITO') {
  buildClienteCredito(); // todos requeridos
}

// SUNAT BOLETA - nombre y numero_documento requeridos
else if (tipoVenta == 'SUNAT_BOLETA') {
  buildClienteSunatBoleta(); // nombre + numero_documento
}

// SUNAT FACTURA - nombre, RUC (tipo_documento="6"), numero_documento
else if (tipoVenta == 'SUNAT_FACTURA') {
  buildClienteSunatFactura(); // nombre + RUC
}
```

---

## Validación

La validación se ejecuta automáticamente en `VentaRepository.crearVenta()`:

```dart
final validationError = venta.validate();
if (validationError != null) {
  throw Exception(validationError); // Error: "Nombre de cliente es requerido para crédito"
}
```

Los mensajes de error son específicos según el tipo y campo:
- ✅ "Nombre de cliente es requerido"
- ✅ "Tipo de documento DEBE ser RUC (tipo_documento: 6) para factura"
- ✅ "RUC debe ser exactamente 11 dígitos numéricos"
- ✅ etc.

---

## Constantes útiles

```dart
import 'package:management_system_ui/features/venta/constants/venta_constants.dart';

// Tipos de venta
TipoVenta.normal     // "NORMAL"
TipoVenta.credito    // "CREDITO"
TipoVenta.sunat      // "SUNAT"

// Métodos de pago
MetodoPago.efectivo      // "EFECTIVO"
MetodoPago.yape         // "YAPE"
MetodoPago.plin         // "PLIN"
MetodoPago.transferencia // "TRANSFERENCIA"
MetodoPago.tarjeta      // "TARJETA"

// Comprobantes SUNAT
TipoComprobanteSunat.factura // "01"
TipoComprobanteSunat.boleta  // "03"

// Tipos de documento
TipoDocumento.dni // "1"
TipoDocumento.ruc // "6"
```
