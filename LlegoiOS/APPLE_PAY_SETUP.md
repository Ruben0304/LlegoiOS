# Configuración de Apple Pay en Sandbox (Testing)

Este documento explica cómo configurar Apple Pay para testing en modo sandbox sin realizar cobros reales.

## 🎯 Resumen

La implementación actual usa Apple Pay en modo **sandbox/testing**, lo que significa:
- ✅ Se muestra la interfaz real de Apple Pay
- ✅ Puedes probar el flujo completo de pago
- ✅ **NO se realizan cobros reales**
- ✅ Puedes usar tarjetas de prueba de Apple

## 📋 Pasos de Configuración

### 1. Configurar Capacidades en Xcode

1. Abre el proyecto `iosApp.xcodeproj` en Xcode
2. Selecciona el target `iosApp`
3. Ve a la pestaña **Signing & Capabilities**
4. Haz clic en **+ Capability**
5. Busca y agrega **"Apple Pay"**

### 2. Configurar Merchant ID

#### Opción A: Para Testing Local (Recomendado para desarrollo)

1. En la sección de Apple Pay que acabas de agregar
2. Haz clic en el botón **"+"** bajo "Merchant IDs"
3. Crea un nuevo Merchant ID:
   - Identifier: `merchant.com.llego.multiplatform.sandbox`
   - Description: `Llego Sandbox Testing`

#### Opción B: Para Testing con Merchant ID Real

1. Ve a [Apple Developer Portal](https://developer.apple.com/account)
2. Navega a **Certificates, Identifiers & Profiles**
3. Selecciona **Identifiers** > **Merchant IDs**
4. Crea un nuevo Merchant ID:
   - Identifier: `merchant.com.llego.multiplatform`
   - Description: `Llego Multiplatform`
5. Actualiza el `merchantID` en [PaymentManager.swift](helpers/PaymentManager.swift:26):
   ```swift
   private let merchantID = "merchant.com.llego.multiplatform"
   ```

### 3. Configurar Tarjetas de Prueba en el Simulador/Dispositivo

#### En el Simulador iOS:

1. Abre la app **Wallet** en el simulador
2. Agrega una tarjeta de prueba:
   - Número: `4111 1111 1111 1111` (Visa test)
   - Cualquier fecha de expiración futura
   - Cualquier CVV de 3 dígitos
   - Cualquier código postal

#### Tarjetas de Prueba Adicionales:

- **Visa**: 4111 1111 1111 1111
- **Mastercard**: 5555 5555 5555 4444
- **Amex**: 3782 822463 10005
- **Discover**: 6011 1111 1111 1117

#### En un Dispositivo Real:

1. Ve a **Settings** > **Wallet & Apple Pay**
2. Agrega una tarjeta de prueba usando los números anteriores
3. Apple detectará que es un entorno sandbox y no solicitará verificación real

### 4. Configurar StoreKit Testing (Opcional pero recomendado)

Para un entorno de testing más robusto:

1. En Xcode, ve a **Product** > **Scheme** > **Edit Scheme**
2. Selecciona **Run** en el panel izquierdo
3. Ve a la pestaña **Options**
4. En **StoreKit Configuration**, selecciona o crea un archivo de configuración
5. Esto te permitirá simular diferentes escenarios de pago

### 5. Info.plist - Verificar Configuración

Asegúrate de que tu `Info.plist` tenga la siguiente entrada (ya debería estar incluida):

```xml
<key>NSAppleMusicUsageDescription</key>
<string>Para procesar pagos seguros con Apple Pay</string>
```

## 🧪 Testing en Sandbox

### Comportamiento Actual

El código en [PaymentManager.swift](helpers/PaymentManager.swift) está configurado para:

1. **Verificar disponibilidad de Apple Pay**:
   ```swift
   paymentManager.canMakePayments() // true si Apple Pay está disponible
   ```

2. **Mostrar interfaz real de Apple Pay**:
   - Sheet nativo de iOS con tus tarjetas
   - Touch ID / Face ID para autorizar
   - Resumen del pago

3. **Procesar en modo sandbox**:
   - El pago es autorizado pero **NO se cobra**
   - Recibes un payment token válido (para enviar a tu backend)
   - Estado cambia a `.success` automáticamente

### Banner de Debug

En modo DEBUG, verás un banner en la parte superior de [PlansAndPricingView](ui/screens/PlansAndPricingView.swift:104-119) que muestra:

```
✅ Apple Pay disponible con tarjetas configuradas
⚠️ Apple Pay disponible pero sin tarjetas
❌ Apple Pay no disponible en este dispositivo
```

Este banner **solo aparece en builds de DEBUG** y no se verá en producción.

### Logs de Consola

Al procesar un pago, verás en la consola de Xcode:

```
🍎 Apple Pay Status: ✅ Apple Pay disponible con tarjetas configuradas
✅ Payment authorized in sandbox mode
Payment token: <PKPaymentToken: 0x...>
Billing contact: user@example.com
```

## 🎬 Flujo de Usuario

1. Usuario abre PlansAndPricingView
2. Selecciona el **Plan Premium**
3. Toca el botón **"Pagar con Apple Pay"**
4. Se muestra el sheet nativo de Apple Pay con:
   - Resumen: "Plan Premium - Mensual: $9.99"
   - Impuestos: $1.00
   - Total: $10.99
5. Usuario autoriza con Face ID/Touch ID
6. PaymentManager simula procesamiento (1.5 segundos)
7. Muestra alert de éxito: "¡Suscripción Exitosa! 🎉"

## 🔍 Verificación

Para verificar que todo funciona:

```swift
// En PlansAndPricingView.onAppear se ejecuta automáticamente:
print("🍎 Apple Pay Status: \(paymentManager.getApplePayStatus())")
```

## ⚠️ Notas Importantes

### Testing vs Producción

- **Sandbox**: Merchant ID puede ser cualquiera, no se valida con servidor
- **Producción**: Necesitas un Merchant ID real verificado por Apple
- **Backend**: En producción, deberás enviar el `payment.token` a tu servidor para procesarlo con tu proveedor de pagos (Stripe, etc.)

### Limitaciones del Simulador

- El simulador puede mostrar "Apple Pay no disponible" en algunos casos
- Solución: Usa un dispositivo real o configura tarjetas en el simulador
- Algunos simuladores antiguos no soportan Apple Pay

### Países Soportados

Actualmente configurado para:
- **País**: US (`countryCode = "US"`)
- **Moneda**: USD (`currencyCode = "USD"`)

Para cambiar (ejemplo a Cuba/EUR):
```swift
request.countryCode = "CU"
request.currencyCode = "CUP" // o "EUR"
```

## 🚀 Próximos Pasos (Producción)

Cuando estés listo para producción:

1. **Obtener Merchant ID real** en Apple Developer Portal
2. **Configurar Payment Service Provider** (Stripe, Braintree, etc.)
3. **Implementar backend** para procesar payment tokens:
   ```swift
   // En PaymentManager.paymentAuthorizationController
   // Enviar payment.token a tu servidor
   let tokenData = payment.token.paymentData
   // POST a https://tu-backend.com/api/process-payment
   ```
4. **Actualizar countryCode y currencyCode** según tu mercado
5. **Remover código de simulación** en PaymentManager
6. **Testing con tarjetas reales** en Sandbox de Stripe/etc.

## 📚 Referencias

- [Apple Pay Developer Guide](https://developer.apple.com/apple-pay/)
- [PassKit Framework](https://developer.apple.com/documentation/passkit)
- [Apple Pay Sandbox Testing](https://developer.apple.com/apple-pay/sandbox-testing/)
- [StoreKit Testing](https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode)

## 🐛 Troubleshooting

### "Apple Pay no disponible"
- Verifica que agregaste la capability en Xcode
- Asegúrate de tener al menos una tarjeta en Wallet
- Reinicia el simulador

### "No se pudo presentar Apple Pay"
- Verifica el Merchant ID en PaymentManager
- Asegúrate de que el Merchant ID existe en Capabilities

### "Payment token null"
- Normal en sandbox, el token se genera pero no se procesa
- En producción necesitarás un backend para validarlo

### Banner de debug no aparece
- Solo visible en builds DEBUG
- Verifica que estás corriendo en modo Debug, no Release
