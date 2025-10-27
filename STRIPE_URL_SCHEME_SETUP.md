# Configuración del URL Scheme para Stripe

Para que Stripe pueda redirigir de vuelta a tu aplicación después de la autenticación (como 3D Secure), necesitas configurar un URL Scheme personalizado.

## URL Scheme Configurado

```
llegoi-os://stripe-redirect
```

## Pasos para Configurar en Xcode

### Opción 1: Usando el Target Settings (Recomendado)

1. **Abrir Xcode**
   - Abre el proyecto `LlegoiOS.xcodeproj` en Xcode

2. **Seleccionar el Target**
   - En el navegador de proyectos (izquierda), selecciona el proyecto `LlegoiOS`
   - En la sección TARGETS, selecciona `LlegoiOS`

3. **Ir a la pestaña Info**
   - Click en la pestaña "Info" en la parte superior

4. **Añadir URL Type**
   - Scroll hasta encontrar "URL Types"
   - Click en el botón "+" para añadir un nuevo URL Type
   - Configura los campos:
     - **Identifier**: `com.llego.ios.stripe` (o tu bundle identifier + `.stripe`)
     - **URL Schemes**: `llegoi-os` (SIN el `://`)
     - **Role**: `Editor`

5. **Guardar**
   - Xcode guardará automáticamente

### Opción 2: Editando Info.plist (Si existe)

Si tu proyecto tiene un archivo `Info.plist` separado, añade:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.llego.ios.stripe</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>llegoi-os</string>
        </array>
    </dict>
</array>
```

## Verificar la Configuración

### En Xcode

1. Ve a `iOSApp.swift` y verifica que el handler esté configurado:

```swift
import SwiftUI
import StripePaymentSheet

@main
struct iOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    let stripeHandled = StripeAPI.handleURLCallback(with: url)
                    if stripeHandled {
                        print("✅ Stripe manejó la URL: \(url)")
                    }
                }
        }
    }
}
```

### Testing del URL Scheme

Puedes probar que el URL scheme funciona ejecutando esto en Terminal mientras la app está corriendo en el simulador:

```bash
xcrun simctl openurl booted "llegoi-os://stripe-redirect"
```

Si todo está configurado correctamente, deberías ver en la consola de Xcode:
```
✅ Stripe manejó la URL: llegoi-os://stripe-redirect
```

## URL Scheme en Producción

Para producción, considera usar un URL scheme más específico:

```swift
// En StripeConfig.swift
static let returnURL = "llego-app://payment-return"
```

Y actualiza el URL Scheme en Xcode a `llego-app` en lugar de `llegoi-os`.

## Troubleshooting

### El URL scheme no funciona

1. **Limpia el build**:
   ```
   Product → Clean Build Folder (Cmd + Shift + K)
   ```

2. **Reinstala la app**:
   - Elimina la app del simulador/dispositivo
   - Vuelve a ejecutar desde Xcode

3. **Verifica el URL Scheme en Xcode**:
   - Target → Info → URL Types
   - Asegúrate de que el scheme sea exactamente `llegoi-os` (sin `://`)

4. **Verifica la consola**:
   - Cuando Stripe intente redirigir, verás un log en Xcode
   - Si no ves nada, el URL scheme no está configurado correctamente

### iOS 14+ Privacy

En iOS 14+, necesitas declarar los URL schemes que tu app puede abrir. Añade esto a tu `Info.plist` si planeas abrir otras apps:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>stripe</string>
</array>
```

## Flujo Completo de Autenticación

```
1. Usuario toca "Pagar" en CartView
2. App llama a PaymentRepository.createPaymentIntent()
3. Backend devuelve el PaymentIntent
4. App muestra PaymentSheet de Stripe
5. Usuario ingresa datos de tarjeta
6. Si requiere 3D Secure:
   a. Safari/WebView se abre para autenticación
   b. Usuario completa autenticación
   c. Safari redirige a: llegoi-os://stripe-redirect
   d. iOS abre la app con esa URL
   e. StripeAPI.handleURLCallback() procesa el resultado
   f. PaymentSheet muestra resultado final
7. App muestra confirmación de pago
```

## Recursos

- [Apple URL Scheme Documentation](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)
- [Stripe iOS Return URL](https://stripe.com/docs/mobile/ios/basic-payment-intents#return-url)

---

**Última actualización**: Octubre 2024
