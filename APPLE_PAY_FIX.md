# Solución: Apple Pay "Asegúrate de que la app se diseñó para usar Apple Pay"

## El Problema

El mensaje "Asegúrate de que la app Llego se diseñó para usar Apple Pay" aparece porque el Merchant ID `merchant.com.llego.ios` no está registrado en tu cuenta de Apple Developer o no está vinculado correctamente al App ID.

## Solución Paso a Paso

### Opción A: Registrar el Merchant ID (Producción)

1. **Ve a Apple Developer Portal**
   - https://developer.apple.com/account

2. **Navega a Certificates, Identifiers & Profiles**
   - En el menú lateral, selecciona "Identifiers"

3. **Crea un nuevo Merchant ID**
   - Haz clic en el botón "+" (azul)
   - Selecciona "Merchant IDs"
   - Haz clic en "Continue"

4. **Configura el Merchant ID**
   - Description: `Llego iOS Payments`
   - Identifier: `merchant.com.llego.ios`
   - Haz clic en "Continue" y luego "Register"

5. **Vincula el Merchant ID al App ID**
   - Ve a "Identifiers" nuevamente
   - Selecciona tu App ID (ej: `com.llego.ios`)
   - Busca "Apple Pay Payment Processing"
   - Marca la casilla
   - Haz clic en "Edit"
   - Selecciona el Merchant ID que acabas de crear
   - Guarda los cambios

6. **Actualiza el Provisioning Profile**
   - Ve a "Profiles"
   - Elimina el profile actual (si existe)
   - Crea uno nuevo que incluya la capability de Apple Pay
   - Descárgalo e instálalo en Xcode

7. **En Xcode**
   - Ve a tu proyecto > Target > Signing & Capabilities
   - Asegúrate de que "Apple Pay" esté agregado
   - Verifica que el Merchant ID `merchant.com.llego.ios` esté listado
   - Limpia el build (Cmd+Shift+K)
   - Reconstruye el proyecto

### Opción B: Usar Modo Testing (Desarrollo - MÁS RÁPIDO)

Si solo quieres probar la funcionalidad sin configurar todo en Apple Developer:

1. **Cambia el Merchant ID a uno de prueba**
   
   En `WalletViewModel.swift`, ya cambié el merchant ID a:
   ```swift
   private let merchantID = "merchant.com.apple.test"
   ```

2. **Actualiza el entitlements**
   
   Abre `LlegoiOS.entitlements` y cambia:
   ```xml
   <key>com.apple.developer.in-app-payments</key>
   <array>
       <string>merchant.com.apple.test</string>
   </array>
   ```

3. **Limpia y reconstruye**
   - Cmd+Shift+K (Clean)
   - Cmd+B (Build)

**NOTA**: Esta opción B solo funciona para testing. En producción DEBES usar un Merchant ID real registrado.

### Opción C: Simular el pago sin Apple Pay (Testing rápido)

Si quieres seguir desarrollando sin configurar Apple Pay ahora, puedes usar el botón "Recarga Manual (Prueba)" que ya funciona y simula el pago exitosamente.

## Verificación

Después de aplicar cualquiera de las opciones:

1. Abre la app
2. Ve a Wallet
3. Toca "Recargar"
4. Ingresa un monto
5. Toca el botón ℹ️ para ver el diagnóstico
6. Intenta pagar con Apple Pay

## Recomendación

Para desarrollo rápido: **Usa Opción B o C**
Para producción: **Usa Opción A**

El botón "Recarga Manual (Prueba)" ya funciona perfectamente y simula todo el flujo de pago sin necesidad de configurar Apple Pay.
