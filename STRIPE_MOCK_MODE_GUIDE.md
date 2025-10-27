# Guía de Modo Mock - Stripe (Testing sin Backend)

## ¿Qué es el Modo Mock?

El **Modo Mock** te permite probar la integración de Stripe PaymentSheet **sin necesidad de tener un backend configurado**. Este modo llama directamente a la API de Stripe desde el cliente iOS usando tu test key.

⚠️ **IMPORTANTE**: Este modo es **SOLO PARA TESTING/DESARROLLO**. **NUNCA** debe usarse en producción.

## 🚀 Cómo Activar el Modo Mock

El modo mock está **ACTIVADO por defecto** en [StripeConfig.swift](LlegoiOS/network/StripeConfig.swift):

```swift
/// Modo de desarrollo: usa datos mock sin llamar al backend
/// ⚠️ ACTIVAR SOLO PARA TESTING. Desactivar cuando el backend esté listo.
static let useMockData = true
```

## 📱 Cómo Probar

### 1. Ejecutar la App

```bash
# Abrir en Xcode y ejecutar
Cmd + R
```

### 2. Flujo de Testing

1. **Añade productos al carrito**
2. **Ve al tab "Carrito"**
3. **Selecciona "Tarjeta de Crédito"** como método de pago
4. **Toca "Pagar"**
5. **Verás el loading**: "Preparando pago..."
6. **PaymentSheet se abre** 🎉

### 3. Ingresar Tarjeta de Prueba

Usa estas tarjetas de prueba de Stripe:

**Para pago exitoso SIN autenticación:**
```
Número: 4242 4242 4242 4242
Fecha: 12/25
CVC: 123
CP: 12345
```

**Para pago exitoso CON 3D Secure (requiere URL scheme configurado):**
```
Número: 4000 0025 0000 3155
Fecha: 12/25
CVC: 123
CP: 12345
```

**Para probar tarjeta rechazada:**
```
Número: 4000 0000 0000 9995
Fecha: 12/25
CVC: 123
CP: 12345
```

### 4. Completar el Pago

1. Toca "Pay" en el PaymentSheet
2. ¡Listo! Verás la confirmación

## 📊 Logs en Xcode

Cuando uses el modo mock, verás estos logs en la consola:

```
💳 Iniciando pago con Stripe
💰 Monto: 4550 centavos ($45.50)
🧪 Usando MOCK MODE - llamando directamente a Stripe API (solo para testing)
🧪 [MOCK MODE] Creando PaymentIntent directamente con Stripe API
   Amount: 4550 usd
📥 Response: {"id":"pi_xxxxx","object":"payment_intent"...
✅ [MOCK MODE] PaymentIntent creado: pi_xxxxx
🧪 [MOCK MODE] Omitiendo configuración de Customer
✅ PaymentSheet configurado correctamente
   PaymentIntent: pi_xxxxx_secret_yy...
✅ Pago completado exitosamente
```

## 🔄 Cómo Desactivar el Modo Mock (Para Producción)

Cuando tu backend esté listo:

1. **Edita [StripeConfig.swift](LlegoiOS/network/StripeConfig.swift)**:

```swift
/// Modo de desarrollo: usa datos mock sin llamar al backend
/// ⚠️ ACTIVAR SOLO PARA TESTING. Desactivar cuando el backend esté listo.
static let useMockData = false  // ← Cambiar a false
```

2. **Verifica que el endpoint del backend esté funcionando**:

```bash
curl -X POST https://llegobackend-production.up.railway.app/create-payment-intent \
  -H "Content-Type: application/json" \
  -d '{"amount": 4550, "currency": "usd", "customer_email": "test@example.com"}'
```

3. **Listo**: La app ahora usará el backend en lugar del modo mock.

## 🆚 Diferencias: Mock vs Producción

| Característica | Modo Mock | Modo Producción (Backend) |
|----------------|-----------|---------------------------|
| Backend requerido | ❌ No | ✅ Sí |
| Llama a Stripe API | Directamente desde iOS | A través del backend |
| Secret Key expuesta | ⚠️ Sí (solo test key) | ❌ No (segura en backend) |
| Customer guardado | ❌ No | ✅ Sí |
| Tarjetas guardadas | ❌ No | ✅ Sí |
| Pagos recurrentes | ❌ No | ✅ Sí |
| Webhooks | ❌ No | ✅ Sí |
| Seguro para producción | ❌ NUNCA | ✅ Sí |

## ⚠️ Limitaciones del Modo Mock

1. **No guarda customers**: Cada pago crea un nuevo PaymentIntent sin customer asociado
2. **No soporta tarjetas guardadas**: No puedes guardar tarjetas para uso futuro
3. **Secret key expuesta**: La test key está en el código (no es seguro para producción)
4. **No hay webhooks**: No recibirás eventos en el backend
5. **Solo para testing**: No cumple con las mejores prácticas de seguridad de Stripe

## 🎯 ¿Qué Funciona en Modo Mock?

✅ **Lo que SÍ funciona:**
- Mostrar PaymentSheet
- Ingresar datos de tarjeta
- Validación de tarjeta por Stripe
- Proceso de pago completo
- Manejo de errores (tarjeta rechazada, etc.)
- Mostrar confirmación de pago
- Limpiar carrito después del pago

❌ **Lo que NO funciona:**
- Guardar tarjetas para uso futuro
- Crear customers persistentes
- Recibir webhooks en el backend
- Pagos recurrentes/suscripciones
- Vincular pagos con tu base de datos

## 🧪 Escenarios de Testing

### Escenario 1: Pago Exitoso Simple
```
1. Selecciona productos → Carrito
2. Método de pago: Tarjeta de Crédito
3. Pagar → Ingresa 4242 4242 4242 4242
4. ✅ Pago exitoso
```

### Escenario 2: Tarjeta Rechazada
```
1. Selecciona productos → Carrito
2. Método de pago: Tarjeta de Crédito
3. Pagar → Ingresa 4000 0000 0000 9995
4. ❌ Error: "Your card has insufficient funds"
```

### Escenario 3: Usuario Cancela
```
1. Selecciona productos → Carrito
2. Método de pago: Tarjeta de Crédito
3. Pagar → PaymentSheet abre
4. Toca "X" para cerrar
5. ⚠️ "Pago cancelado"
```

## 🔍 Debugging

### Si PaymentSheet no se abre:

1. **Verifica los logs** en Xcode (busca `💳`, `🧪`, `✅`, `❌`)
2. **Verifica que `useMockData = true`** en StripeConfig.swift
3. **Limpia el build**: `Cmd + Shift + K`
4. **Reinstala la app**

### Si el pago falla:

1. **Verifica la conexión a internet**
2. **Usa tarjetas de prueba válidas** (ver arriba)
3. **Revisa los logs de Stripe**: https://dashboard.stripe.com/test/logs

### Si ves error "Invalid API Key":

1. Verifica que la publishable key sea correcta en [StripeConfig.swift](LlegoiOS/network/StripeConfig.swift)
2. Debe empezar con `pk_test_`

## 📈 Monitoreo en Stripe Dashboard

Puedes ver todos los pagos de prueba en:

1. Ve a https://dashboard.stripe.com/test/payments
2. Verás todos los PaymentIntents creados desde el modo mock
3. Cada pago tendrá:
   - Estado: `succeeded`, `requires_action`, `canceled`
   - Monto
   - Tarjeta (últimos 4 dígitos)
   - Timestamp

## 🚀 Siguiente Paso: Backend

Cuando estés listo, sigue la guía para crear el endpoint del backend:

📖 **[STRIPE_BACKEND_SETUP.md](STRIPE_BACKEND_SETUP.md)**

## 💡 Tips

1. **Usa siempre tarjetas de prueba**: Las tarjetas reales no funcionarán con test keys
2. **Revisa Stripe Dashboard**: Puedes ver todos los pagos de prueba ahí
3. **Experimenta**: Prueba diferentes tarjetas para ver los errores
4. **Logs son tus amigos**: Los logs te dirán exactamente qué está pasando

## ❓ FAQ

**P: ¿Puedo usar este modo en producción?**
R: ❌ NO. NUNCA. Es inseguro porque expone la secret key.

**P: ¿Los pagos son reales?**
R: No, estás usando test keys. No se cobra dinero real.

**P: ¿Necesito configurar el URL Scheme?**
R: Solo si quieres probar 3D Secure. Para tarjetas básicas (4242...) no es necesario.

**P: ¿Cómo cambio de modo mock a producción?**
R: Cambia `useMockData = false` en [StripeConfig.swift](LlegoiOS/network/StripeConfig.swift)

**P: ¿Por qué necesito un backend?**
R: Por seguridad. La secret key NUNCA debe estar en el código del cliente.

---

**Última actualización**: Octubre 2024

**Nota**: Este modo está diseñado específicamente para que puedas probar la interfaz de PaymentSheet sin configurar el backend primero. Es perfecto para desarrollo rápido y prototipos.
