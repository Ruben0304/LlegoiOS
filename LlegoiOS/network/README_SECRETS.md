# Configuración de Claves Secretas de Stripe

## 📁 Archivos en esta carpeta

- **`Secrets.swift`** - Archivo con tus claves de Stripe (NO se sube a GitHub)
- **`StripeConfig.swift`** - Configuración general de Stripe que usa las claves de Secrets.swift

## 🔐 Configuración de tus claves

### 1. Editar tu archivo Secrets.swift

El archivo `Secrets.swift` ya existe. Para actualizar tus claves:

1. Abre `Secrets.swift` en Xcode
2. Reemplaza las claves con tus claves reales de Stripe:
   - Obtén tus claves en: https://dashboard.stripe.com/apikeys
   - **Publishable Key** (pk_test_... o pk_live_...)
   - **Secret Key** (sk_test_... o sk_live_...)

```swift
struct StripeSecrets {
    static let secretKey = "sk_test_TU_KEY_AQUI"
    static let publishableKey = "pk_test_TU_KEY_AQUI"
}
```

### 2. Verificar que está en .gitignore

El archivo `Secrets.swift` está configurado en `.gitignore` para que NO se suba a GitHub:

```
# SENSITIVE DATA - DO NOT COMMIT
# API Keys and Secrets
LlegoiOS/network/Secrets.swift
```

## ⚠️ Importante

### Secret Key
- **NUNCA** debe exponerse en código del cliente en producción
- Solo se usa aquí para propósitos de testing/desarrollo
- En producción, la Secret Key debe estar SOLO en el backend
- El backend debe crear los Payment Intents y devolver el client_secret

### Publishable Key
- Es segura para usar en el cliente
- Se puede exponer públicamente sin problemas

## 🔄 Si trabajas en equipo

Cada desarrollador debe:
1. Crear su propio archivo `Secrets.swift` en esta carpeta
2. Copiar la estructura del archivo existente
3. Agregar sus propias claves de Stripe (test keys)
4. El archivo `Secrets.swift` NO se compartirá en Git

**Estructura del archivo:**
```swift
import Foundation

struct StripeSecrets {
    static let secretKey = "sk_test_TU_KEY_AQUI"
    static let publishableKey = "pk_test_TU_KEY_AQUI"
}
```

## 🚀 Uso en el código

Las claves se usan automáticamente desde `StripeConfig`:

```swift
// Inicializar Stripe (en AppDelegate)
StripeAPI.defaultPublishableKey = StripeConfig.publishableKey

// Usar en código
let paymentIntent = // ... crear con backend usando StripeConfig.secretKey (solo testing)
```

## 📝 Checklist

- [ ] Archivo `Secrets.swift` creado con tus claves
- [ ] Archivo está en `.gitignore`
- [ ] Secret key SOLO para testing/desarrollo
- [ ] En producción, usar backend para Payment Intents
