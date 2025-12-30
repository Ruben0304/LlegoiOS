# Guía de Testing - Integración Stripe

Esta guía te ayudará a probar la integración de Stripe en LlegoiOS usando tarjetas de prueba.

## Tarjetas de Prueba

### Tarjetas Básicas

| Número de Tarjeta | Descripción | Resultado |
|-------------------|-------------|-----------|
| `4242424242424242` | Visa - Pago exitoso sin autenticación | ✅ Success |
| `4000002500003155` | Visa - Requiere autenticación 3D Secure | ✅ Success (después de autenticación) |
| `4000000000009995` | Visa - Tarjeta rechazada | ❌ Declined (fondos insuficientes) |
| `4000000000000002` | Visa - Tarjeta rechazada | ❌ Declined (generic decline) |
| `4000008400001629` | Visa - Pago exitoso (Emiratos Árabes Unidos) | ✅ Success |

### Tarjetas con 3D Secure (Autenticación Requerida)

| Número de Tarjeta | Descripción |
|-------------------|-------------|
| `4000002760003184` | Autenticación requerida - Success |
| `4000008260003178` | Autenticación requerida - Success |
| `4000002500003155` | Autenticación requerida - Success |

### Tarjetas Rechazadas (Para Probar Errores)

| Número de Tarjeta | Código de Error | Descripción |
|-------------------|-----------------|-------------|
| `4000000000000002` | `generic_decline` | Rechazada por razones genéricas |
| `4000000000009995` | `insufficient_funds` | Fondos insuficientes |
| `4000000000009987` | `lost_card` | Tarjeta reportada como perdida |
| `4000000000009979` | `stolen_card` | Tarjeta reportada como robada |
| `4000000000000069` | `expired_card` | Tarjeta expirada |
| `4000000000000127` | `incorrect_cvc` | CVC incorrecto |
| `4000000000000119` | `processing_error` | Error de procesamiento |

### Tarjetas Internacionales

| Número de Tarjeta | País |
|-------------------|------|
| `4000056655665556` | Brasil |
| `4000004840008001` | México |
| `4000058260000005` | España |
| `4000007560000009` | Francia |

## Datos de Prueba para Formulario

Puedes usar cualquier valor válido para estos campos cuando uses tarjetas de prueba:

- **CVC**: Cualquier 3 dígitos (ej: `123`)
- **Fecha de expiración**: Cualquier fecha futura (ej: `12/25`)
- **Código postal**: Cualquier 5 dígitos (ej: `12345`)
- **Nombre en la tarjeta**: Cualquier nombre (ej: `Test User`)

## Flujo de Testing Completo

### 1. Preparación

1. **Verificar que el backend esté corriendo**:
   ```bash
   curl https://llegobackend-production.up.railway.app/create-payment-intent
   ```

2. **Verificar URL Scheme** (en Xcode):
   - Target → Info → URL Types
   - Debe existir `llegoi-os`

3. **Verificar configuración de Stripe** ([StripeConfig.swift](LlegoiOS/network/StripeConfig.swift)):
   ```swift
   static let publishableKey = "pk_test_51SMry82..."
   static let paymentIntentURL = "https://llegobackend-production.up.railway.app/create-payment-intent"
   ```

### 2. Testing de Pago Exitoso

1. **Ejecutar la app** en simulador o dispositivo
2. **Añadir productos al carrito**
3. **Ir al carrito** (Tab "Carrito")
4. **Seleccionar método de pago**: "Tarjeta de Crédito"
5. **Tocar "Pagar"**
6. **Ver indicador de carga**: "Preparando pago..."
7. **PaymentSheet se abre**
8. **Ingresar tarjeta de prueba**:
   ```
   Número: 4242 4242 4242 4242
   Fecha: 12/25
   CVC: 123
   CP: 12345
   ```
9. **Tocar "Pagar"**
10. **Ver confirmación**: "¡Pago completado exitosamente!"

**Logs esperados en Xcode**:
```
💳 Iniciando pago con Stripe
💰 Monto: 4550 centavos ($45.50)
✅ PaymentIntent creado exitosamente
   Customer: cus_xxxxx
   PaymentIntent: pi_xxxxx_secret_yyyyy...
✅ PaymentSheet configurado correctamente
✅ Pago completado exitosamente
```

### 3. Testing de Autenticación 3D Secure

1. Repetir pasos 1-7 de arriba
2. **Ingresar tarjeta con 3D Secure**:
   ```
   Número: 4000 0025 0000 3155
   Fecha: 12/25
   CVC: 123
   CP: 12345
   ```
3. **Tocar "Pagar"**
4. **Safari/WebView se abre** para autenticación
5. **Completar autenticación**: Tocar "Complete" o "Success"
6. **App vuelve automáticamente** (gracias al URL scheme)
7. **Ver confirmación**: "¡Pago completado exitosamente!"

**Logs esperados**:
```
💳 Iniciando pago con Stripe
✅ PaymentIntent creado exitosamente
✅ PaymentSheet configurado correctamente
[Safari abre]
✅ Stripe manejó la URL: llegoi-os://stripe-redirect
✅ Pago completado exitosamente
```

### 4. Testing de Tarjeta Rechazada

1. Repetir pasos 1-7
2. **Ingresar tarjeta rechazada**:
   ```
   Número: 4000 0000 0000 9995
   Fecha: 12/25
   CVC: 123
   CP: 12345
   ```
3. **Tocar "Pagar"**
4. **Ver error**: "Your card has insufficient funds."
5. **Ver alert**: "Error al procesar el pago: Your card has insufficient funds."

**Logs esperados**:
```
💳 Iniciando pago con Stripe
✅ PaymentIntent creado exitosamente
❌ Pago fallido: Your card has insufficient funds.
```

### 5. Testing de Error de Backend

Para probar errores de backend, puedes:

1. **Apagar el servidor temporalmente**
2. **Seguir flujo normal**
3. **Ver error**: "Error al iniciar el pago: The Internet connection appears to be offline."

**Logs esperados**:
```
💳 Iniciando pago con Stripe
❌ Network error: The Internet connection appears to be offline.
```

## Checklist de Testing

- [ ] Pago exitoso sin autenticación (`4242 4242 4242 4242`)
- [ ] Pago exitoso con 3D Secure (`4000 0025 0000 3155`)
- [ ] Tarjeta rechazada por fondos insuficientes (`4000 0000 0000 9995`)
- [ ] Tarjeta rechazada genérica (`4000 0000 0000 0002`)
- [ ] Pago cancelado por usuario (cerrar PaymentSheet)
- [ ] Error de red (backend apagado)
- [ ] Carrito se limpia después de pago exitoso
- [ ] Alert de confirmación se muestra correctamente
- [ ] Loading indicator funciona durante preparación
- [ ] URL Scheme redirige correctamente después de 3D Secure

## Monitoreo en Stripe Dashboard

Puedes ver todos los pagos de prueba en:

1. Ve a https://dashboard.stripe.com/test/payments
2. Verás todos los PaymentIntents creados
3. Filtra por estado: `succeeded`, `requires_action`, `canceled`, etc.

### Ver detalles de un pago:

1. Click en un pago de la lista
2. Verás:
   - Monto y divisa
   - Estado actual
   - Tarjeta usada (últimos 4 dígitos)
   - Metadata (cart_items, subtotal, delivery_fee)
   - Timeline de eventos
   - Logs

## Simulación de Webhooks

Para probar webhooks sin esperar a pagos reales:

1. Ve a https://dashboard.stripe.com/test/webhooks
2. Selecciona tu webhook
3. Click en "Send test webhook"
4. Elige el evento: `payment_intent.succeeded`
5. Ve los logs en tu backend

## Testing en Dispositivo Real vs Simulador

### Simulador

- **Ventajas**:
  - Más rápido para iterar
  - Fácil de debuggear
  - No necesita provisioning profiles

- **Limitaciones**:
  - No puede probar Apple Pay
  - URL scheme puede comportarse diferente

### Dispositivo Real

- **Ventajas**:
  - Testing más realista
  - Puede probar Apple Pay
  - URL scheme funciona igual que en producción

- **Limitaciones**:
  - Requiere provisioning profile
  - Más lento para iterar

## Errores Comunes y Soluciones

### "Failed to load PaymentSheet"

**Causa**: Backend no devolvió respuesta correcta

**Solución**:
1. Verificar logs del backend
2. Verificar que el endpoint devuelva JSON correcto
3. Usar curl para probar el endpoint directamente

### "URL Scheme not working"

**Causa**: URL Scheme no configurado en Xcode

**Solución**:
1. Target → Info → URL Types
2. Añadir `llegoi-os`
3. Clean build folder
4. Reinstalar app

### "Invalid API Key"

**Causa**: Publishable key incorrecta o expirada

**Solución**:
1. Verificar [StripeConfig.swift](LlegoiOS/network/StripeConfig.swift)
2. Verificar en https://dashboard.stripe.com/test/apikeys
3. Copiar key correcta

### "Customer not found"

**Causa**: Backend no creó el customer correctamente

**Solución**:
1. Verificar logs del backend
2. Verificar que `stripe.customers.create()` se ejecute
3. Verificar response del endpoint

## Recursos de Testing

- [Stripe Testing Cards](https://stripe.com/docs/testing)
- [Stripe Dashboard (Test Mode)](https://dashboard.stripe.com/test/payments)
- [Stripe API Logs](https://dashboard.stripe.com/test/logs)
- [Stripe Webhook Testing](https://stripe.com/docs/webhooks/test)

## Para Producción

Antes de ir a producción:

1. **Reemplazar test keys con live keys**
2. **Testing exhaustivo con tarjetas reales** (pequeños montos)
3. **Configurar webhooks de producción**
4. **Implementar logging robusto**
5. **Añadir analytics** (ej: mixpanel, amplitude)
6. **Testing de carga** (múltiples pagos simultáneos)
7. **Probar en diferentes dispositivos y versiones de iOS**

---

**Última actualización**: Octubre 2024
