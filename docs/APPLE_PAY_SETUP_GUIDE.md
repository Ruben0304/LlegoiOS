# Guía de Configuración de Apple Pay

Esta guía te ayudará a configurar Apple Pay en tu aplicación LlegoiOS para que puedas aceptar pagos usando Apple Pay a través de Stripe.

## 📋 Requisitos Previos

1. **Apple Developer Account**: Necesitas una cuenta de desarrollador de Apple (99 USD/año)
2. **Stripe Account**: Ya tienes esto configurado
3. **Dispositivo Real o Simulador iOS 12+**: Apple Pay funciona en simuladores desde iOS 12
4. **Xcode 14+**: Asegúrate de tener la última versión

## 🎯 Paso 1: Registrar Merchant ID en Apple Developer

### 1.1. Crear Merchant ID

1. **Ve a Apple Developer Console**:
   - https://developer.apple.com/account/resources/identifiers/list

2. **Crea un nuevo Merchant ID**:
   - Click en el botón "+" (Añadir)
   - Selecciona "Merchant IDs"
   - Click "Continue"

3. **Configura el Merchant ID**:
   - **Description**: `Llego iOS App` (solo para ti)
   - **Identifier**: `merchant.com.llego.ios` (debe coincidir con [StripeConfig.swift](LlegoiOS/network/StripeConfig.swift))
   - Click "Register"

4. **Confirma**:
   - Click "Done"

### 1.2. Verificar el Merchant ID

Asegúrate de que el Merchant ID en [StripeConfig.swift](LlegoiOS/network/StripeConfig.swift) coincida exactamente:

```swift
static let applePayMerchantId = "merchant.com.llego.ios"
```

Si usaste un ID diferente, actualiza el código.

## 🎯 Paso 2: Crear Certificado para Apple Pay

### 2.1. Obtener CSR de Stripe

1. **Ve a Stripe Dashboard**:
   - https://dashboard.stripe.com/test/settings/payments/apple_pay

2. **Añade un nuevo dominio o app**:
   - Click en "Add new application"
   - Selecciona tu país
   - Click "Add application"

3. **Descarga el CSR (Certificate Signing Request)**:
   - Stripe te mostrará un archivo `.certSigningRequest`
   - Descarga este archivo

### 2.2. Crear Certificado en Apple Developer

1. **Ve a tu Merchant ID en Apple Developer**:
   - https://developer.apple.com/account/resources/identifiers/list
   - Selecciona tu Merchant ID (`merchant.com.llego.ios`)

2. **Crea un Certificado de Procesamiento de Pagos**:
   - Scroll hasta "Apple Pay Payment Processing Certificate"
   - Click "Create Certificate"

3. **Sube el CSR de Stripe**:
   - Click "Choose File"
   - Selecciona el archivo `.certSigningRequest` que descargaste de Stripe
   - Click "Continue"

4. **Descarga el Certificado**:
   - Click "Download"
   - Guarda el archivo `.cer`

### 2.3. Subir Certificado a Stripe

1. **Vuelve a Stripe Dashboard**:
   - https://dashboard.stripe.com/test/settings/payments/apple_pay

2. **Sube el certificado**:
   - Click "Upload Certificate"
   - Selecciona el archivo `.cer` que descargaste de Apple
   - Click "Upload"

3. **Confirma**:
   - Deberías ver tu certificado listado
   - Status: "Active"

## 🎯 Paso 3: Configurar Apple Pay en Xcode

### 3.1. Añadir Capability de Apple Pay

1. **Abrir Xcode**:
   - Abre tu proyecto `LlegoiOS.xcodeproj`

2. **Seleccionar el Target**:
   - En el navegador de proyectos (izquierda), selecciona `LlegoiOS`
   - En la sección TARGETS, selecciona `LlegoiOS`

3. **Añadir Capability**:
   - Click en la pestaña "Signing & Capabilities"
   - Click en el botón "+ Capability"
   - Busca "Apple Pay"
   - Double-click en "Apple Pay" para añadirla

4. **Configurar Merchant IDs**:
   - En la sección "Apple Pay" que aparece
   - Verás una lista de Merchant IDs
   - Click en el botón "+"
   - Selecciona `merchant.com.llego.ios` de la lista
   - Si no aparece, asegúrate de que:
     - Estás logueado con la cuenta correcta en Xcode
     - El Merchant ID está registrado en Apple Developer
     - Refresh: Xcode → Preferences → Accounts → Download Manual Profiles

### 3.2. Verificar Configuración

En la pestaña "Signing & Capabilities", deberías ver:

```
✅ Apple Pay
   Merchant IDs:
   ✓ merchant.com.llego.ios
```

## 🎯 Paso 4: Testing Apple Pay

### 4.1. Configurar Tarjeta de Prueba en Simulador

**En el Simulador iOS**:

1. **Abrir Wallet**:
   - Simulador → Features → Wallet
   - O abre la app Wallet directamente

2. **Añadir Tarjeta de Prueba**:
   - Click en "Add Card"
   - Click "Continue"
   - Usa estos datos de tarjeta de prueba de Stripe:
     ```
     Número: 4242 4242 4242 4242
     Fecha: Cualquier fecha futura
     CVV: Cualquier 3 dígitos
     CP: Cualquier código postal
     ```

3. **Confirmar**:
   - Stripe automáticamente verificará la tarjeta de prueba

**En Dispositivo Real**:

Apple Pay en dispositivos reales requiere tarjetas reales. Para testing:

1. **Modo Sandbox de Apple Pay**:
   - Ve a Settings → Wallet & Apple Pay
   - Scroll hasta el final
   - Busca "Sandbox Tester"
   - Inicia sesión con tu Apple ID de prueba

2. **Añadir Tarjeta de Prueba**:
   - Similar al simulador
   - Usa las tarjetas de prueba de Stripe

### 4.2. Probar Apple Pay en la App

1. **Ejecutar la app** (Cmd + R)

2. **Añadir productos al carrito**

3. **Ir al Carrito**

4. **Seleccionar "Tarjeta de Crédito"**

5. **Tocar "Pagar"**

6. **En PaymentSheet deberías ver**:
   - 🍎 **Apple Pay** (botón grande en la parte superior)
   - Tarjetas guardadas (si hay customer)
   - Formulario para nueva tarjeta

7. **Tocar el botón de Apple Pay**

8. **Confirmar con Face ID/Touch ID/Passcode**

9. **¡Pago completado!** ✅

### 4.3. Logs Esperados

```
💳 Iniciando pago con Stripe
🧪 [MOCK MODE] Creando PaymentIntent directamente con Stripe API
✅ [MOCK MODE] PaymentIntent creado: pi_xxxxx
🍎 Apple Pay habilitado
   Merchant ID: merchant.com.llego.ios
   Country: US
✅ PaymentSheet configurado correctamente
💳 Pagos a plazos habilitados (se mostrarán si son elegibles)
✅ Pago completado exitosamente
```

## 🎯 Paso 5: Verificar Apple Pay en Stripe Dashboard

1. **Ve a Stripe Dashboard**:
   - https://dashboard.stripe.com/test/payments

2. **Busca tu pago**:
   - Deberías ver el pago listado
   - **Payment method**: "Apple Pay"
   - **Last 4**: Últimos 4 dígitos de la tarjeta
   - **Status**: "Succeeded"

3. **Ver detalles**:
   - Click en el pago
   - Verás información sobre la tarjeta tokenizada
   - Apple Pay Device Account Number (no es el número real de la tarjeta)

## 🛠️ Troubleshooting

### Apple Pay no aparece en PaymentSheet

**Posibles causas**:

1. **Merchant ID no configurado en Xcode**:
   - Verifica Signing & Capabilities → Apple Pay
   - Asegúrate de que `merchant.com.llego.ios` esté seleccionado

2. **Certificado no subido a Stripe**:
   - Ve a https://dashboard.stripe.com/test/settings/payments/apple_pay
   - Verifica que haya un certificado activo

3. **No hay tarjetas en Wallet**:
   - Abre Wallet en el simulador/dispositivo
   - Añade una tarjeta de prueba

4. **Código de país incorrecto**:
   - Verifica en [StripeConfig.swift](LlegoiOS/network/StripeConfig.swift)
   - `merchantCountryCode` debe coincidir con tu cuenta de Stripe

### Error: "Invalid Merchant ID"

**Solución**:

1. Verifica que el Merchant ID en [StripeConfig.swift](LlegoiOS/network/StripeConfig.swift) sea exactamente el mismo que creaste en Apple Developer

2. Verifica que el Merchant ID esté seleccionado en Xcode (Signing & Capabilities)

3. Clean build: `Cmd + Shift + K`

4. Reinstala la app

### Apple Pay funciona en simulador pero no en dispositivo

**Solución**:

1. **Verifica provisioning profile**:
   - El profile debe incluir la capability de Apple Pay

2. **Regenera provisioning profile**:
   - Ve a Apple Developer → Certificates, Identifiers & Profiles
   - Profiles → Regenera tu profile

3. **En Xcode**:
   - Signing & Capabilities → Download Manual Profiles

### Error: "This payment method requires authentication"

**Solución**:

1. Asegúrate de que el URL Scheme esté configurado (`llegoi-os`)
   - Ver [STRIPE_URL_SCHEME_SETUP.md](STRIPE_URL_SCHEME_SETUP.md)

2. Verifica que `configuration.returnURL` esté configurado en el código

## 🌍 Países Soportados

Apple Pay está disponible en estos países (parcial):

- 🇺🇸 Estados Unidos
- 🇨🇦 Canadá
- 🇬🇧 Reino Unido
- 🇦🇺 Australia
- 🇪🇸 España
- 🇫🇷 Francia
- 🇩🇪 Alemania
- 🇮🇹 Italia
- 🇲🇽 México
- Y muchos más...

Si tu `merchantCountryCode` es "US" pero tu Stripe account es de otro país, considera cambiarlo en [StripeConfig.swift](LlegoiOS/network/StripeConfig.swift).

## 💳 Pagos a Plazos (Installments)

Los pagos a plazos (Affirm, Afterpay, Klarna) se habilitan automáticamente si:

1. **Están habilitados en Stripe Dashboard**:
   - https://dashboard.stripe.com/test/settings/payment_methods
   - Busca "Buy now, pay later"
   - Activa Affirm, Afterpay, Klarna, etc.

2. **El monto es elegible**:
   - Affirm: $50 - $30,000 USD
   - Afterpay: $1 - $2,000 USD
   - Klarna: €1 - €10,000 EUR

3. **El país es soportado**:
   - Affirm: US, CA
   - Afterpay: US, CA, AU, NZ, UK
   - Klarna: US, UK, EU

4. **`automatic_payment_methods` está habilitado**:
   - Ya está configurado en el código ✅

**IMPORTANTE**: En PaymentSheet, estos métodos aparecerán automáticamente si cumplen los requisitos. No necesitas configurarlos manualmente.

## 🎨 Personalización de Apple Pay

### Cambiar el nombre que aparece en Apple Pay

Edita [StripeConfig.swift](LlegoiOS/network/StripeConfig.swift):

```swift
static let merchantDisplayName = "Tu Nombre de Empresa"
```

### Cambiar el país del comerciante

```swift
static let merchantCountryCode = "MX"  // México
static let merchantCountryCode = "ES"  // España
static let merchantCountryCode = "CA"  // Canadá
```

### Personalizar colores de PaymentSheet

Ya está configurado en `CartView.swift`:

```swift
var appearance = PaymentSheet.Appearance()
appearance.colors.primary = UIColor(Color.llegoPrimary)
appearance.colors.background = UIColor(Color.white)
appearance.cornerRadius = 16.0
```

Puedes personalizar más:

```swift
appearance.colors.text = UIColor.black
appearance.colors.componentBackground = UIColor.lightGray
appearance.font.base = UIFont.systemFont(ofSize: 16)
```

## 📱 Testing en Producción

Cuando estés listo para producción:

1. **Actualiza las keys en [StripeConfig.swift](LlegoiOS/network/StripeConfig.swift)**:
   ```swift
   static let publishableKey = "pk_live_xxxxx"  // Live key
   static let useMockData = false               // Desactivar mock
   ```

2. **Crea certificado de producción**:
   - Repite los pasos 2.2 y 2.3 pero en modo LIVE de Stripe
   - https://dashboard.stripe.com/settings/payments/apple_pay

3. **Usa Merchant ID de producción** (si creaste uno diferente)

4. **Testing con tarjetas reales**:
   - Usa montos pequeños al principio
   - Apple Pay usa Device Account Numbers, más seguros que números de tarjeta

## 📊 Monitoreo y Analytics

### Ver estadísticas de Apple Pay

1. **Stripe Dashboard → Payments**:
   - Filtra por "Payment method: Apple Pay"
   - Verás cuántos pagos vienen de Apple Pay

2. **Stripe Dashboard → Analytics**:
   - Ve las tasas de conversión
   - Compara Apple Pay vs otros métodos

### Mejores Prácticas

1. **Botón de Apple Pay prominente**: Ya está configurado ✅
2. **Fast checkout**: Apple Pay es más rápido que ingresar tarjeta manualmente
3. **Conversión más alta**: Los usuarios prefieren Apple Pay
4. **Más seguro**: Usa tokenización, el comerciante nunca ve el número de tarjeta

## 🔒 Seguridad

Apple Pay es extremadamente seguro:

1. **Tokenización**: No se comparte el número real de la tarjeta
2. **Device Account Number**: Cada dispositivo tiene un número único
3. **Biométricos**: Requiere Face ID/Touch ID
4. **No hay CVV**: No se necesita ingresar CVV

## 📚 Recursos

- [Stripe Apple Pay Docs](https://stripe.com/docs/apple-pay)
- [Apple Pay Developer Guide](https://developer.apple.com/apple-pay/)
- [Stripe Dashboard - Apple Pay](https://dashboard.stripe.com/test/settings/payments/apple_pay)
- [Apple Developer - Merchant IDs](https://developer.apple.com/account/resources/identifiers/list/merchant)

## ✅ Checklist Final

Antes de considerar Apple Pay completamente configurado:

- [ ] Merchant ID creado en Apple Developer
- [ ] Certificado creado y subido a Stripe
- [ ] Capability de Apple Pay añadida en Xcode
- [ ] Merchant ID seleccionado en Xcode
- [ ] Tarjeta de prueba añadida en Wallet
- [ ] Apple Pay aparece en PaymentSheet
- [ ] Pago de prueba completado exitosamente
- [ ] Pago visible en Stripe Dashboard como "Apple Pay"

---

**Última actualización**: Octubre 2024

**Nota**: Esta guía asume que ya tienes la integración básica de Stripe funcionando. Si no, revisa primero [STRIPE_INTEGRATION_SUMMARY.md](STRIPE_INTEGRATION_SUMMARY.md).
