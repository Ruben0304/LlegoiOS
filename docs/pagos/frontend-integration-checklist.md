# Checklist de Integración Frontend - Sistema de Pagos

## ✅ Estado del Backend

### Completado
- ✅ Modelos de datos (PaymentAttempt, PaymentMethod, Platform)
- ✅ Repositorio de base de datos con todas las operaciones
- ✅ Servicio de pagos con lógica completa
- ✅ 7 mutations GraphQL implementadas
- ✅ 6 queries GraphQL implementadas
- ✅ Webhook de Stripe configurado
- ✅ Integración con wallet existente
- ✅ Sistema de comisiones
- ✅ Manejo de reembolsos
- ✅ Script de migración



## 📱 Integración Frontend

### 1. Flujo de Creación de Pedido

#### Paso 1: Crear Pedido
```graphql
mutation CreateOrder($input: CreateOrderInput!) {
  createOrder(input: $input) {
    id
    orderNumber
    status  # Debe ser "pending_payment"
    total
    currency
    currentPaymentAttemptId
  }
}
```

**Cambio necesario:** El backend debe retornar el pedido con estado `pending_payment` en lugar de `pending_acceptance`.

#### Paso 2: Obtener Métodos de Pago
```graphql
query GetPaymentMethods($currency: String!, $jwt: String) {
  paymentMethodsByCurrency(currency: $currency, jwt: $jwt) {
    id
    name
    code
    method
    commissionPercent
    deliveryFeePercent
    instructions
    iconUrl
    isActive
  }
}
```

**UI Sugerida:**
- Lista de métodos de pago con iconos
- Mostrar comisión si > 0%
- Mostrar recargo en delivery si aplica
- Deshabilitar métodos inactivos

#### Paso 3: Iniciar Pago
```graphql
mutation InitiatePayment(
  $orderId: String!
  $paymentMethodId: String!
  $jwt: String!
  $includeDeliveryFee: Boolean = true
) {
  initiatePayment(
    orderId: $orderId
    paymentMethodId: $paymentMethodId
    jwt: $jwt
    includeDeliveryFee: $includeDeliveryFee
  ) {
    paymentAttempt {
      id
      status
      totalAmount
      currency
      stripeClientSecret
      expiresAt
    }
    instructions
  }
}
```

### 2. Flujos por Método de Pago

#### A. Wallet (Instantáneo)

```typescript
// 1. Iniciar pago
const result = await initiatePayment({
  orderId,
  paymentMethodId: "wallet_usd_id",
  jwt
});

// 2. Verificar resultado
if (result.paymentAttempt.status === "completed") {
  // ✅ Pago exitoso - redirigir a confirmación
  navigation.navigate("OrderConfirmation", { orderId });
} else if (result.paymentAttempt.status === "failed") {
  // ❌ Pago fallido - mostrar error
  showError(result.paymentAttempt.failedReason);
}
```

**UI:**
- Mostrar loader mientras procesa
- Mensaje de éxito/error inmediato
- No requiere pasos adicionales

#### B. Stripe (Requiere UI de Stripe)

```typescript
import { useStripe } from '@stripe/stripe-react-native';

// 1. Iniciar pago
const result = await initiatePayment({
  orderId,
  paymentMethodId: "stripe_id",
  jwt
});

// 2. Obtener client secret
const { stripeClientSecret } = result.paymentAttempt;

// 3. Presentar Payment Sheet de Stripe
const stripe = useStripe();
const { error } = await stripe.presentPaymentSheet({
  clientSecret: stripeClientSecret,
  merchantDisplayName: "Llego"
});

if (error) {
  // ❌ Usuario canceló o error
  showError(error.message);
} else {
  // ✅ Pago exitoso
  // El webhook actualizará el estado automáticamente
  navigation.navigate("OrderConfirmation", { orderId });
}
```

**Dependencias:**
```bash
npm install @stripe/stripe-react-native
```

**Setup:**
```typescript
import { StripeProvider } from '@stripe/stripe-react-native';

<StripeProvider publishableKey="pk_test_...">
  <App />
</StripeProvider>
```

**UI:**
- Mostrar monto total con comisión
- Stripe maneja la UI de pago
- Mostrar timer de expiración (30 min)

#### C. Transferencia Bancaria (Manual)

```typescript
// 1. Iniciar pago
const result = await initiatePayment({
  orderId,
  paymentMethodId: "transfermovil_id",
  jwt
});

// 2. Mostrar instrucciones
const { instructions } = result;
// "Realiza la transferencia al número de la tienda y sube el comprobante."

// 3. Usuario realiza transferencia externamente

// 4. Usuario sube comprobante
const proofUrl = await uploadProofImage(imageFile);

// 5. Confirmar envío
await confirmPaymentSent({
  paymentAttemptId: result.paymentAttempt.id,
  proofUrl,
  jwt
});

// 6. Esperar confirmación del negocio
// Estado: "awaiting_business"
```

**UI:**
1. **Pantalla de Instrucciones:**
   - Mostrar instrucciones del método
   - Datos de la cuenta/número del negocio
   - Botón "Ya realicé la transferencia"
   - Timer de expiración (48h)

2. **Pantalla de Subir Comprobante:**
   - Cámara o galería
   - Preview de imagen
   - Botón "Enviar comprobante"

3. **Pantalla de Espera:**
   - "Esperando confirmación del negocio"
   - Mostrar comprobante subido
   - Opción de cancelar
   - Notificación push cuando se confirme

#### D. Efectivo (En Entrega)

```typescript
// 1. Iniciar pago
const result = await initiatePayment({
  orderId,
  paymentMethodId: "cash_id",
  jwt
});

// 2. Estado: "awaiting_delivery"
// No requiere acción del cliente hasta la entrega

// 3. Repartidor confirma al entregar (desde su app)
// await confirmCashReceived({
//   paymentAttemptId,
//   jwt: deliveryPersonJwt
// });
```

**UI Cliente:**
- Mensaje: "Pagarás en efectivo al recibir"
- Mostrar monto total con recargo
- Recordatorio al rastrear pedido

**UI Repartidor:**
- Botón "Confirmar pago recibido" al entregar
- Mostrar monto a cobrar
- Validación antes de marcar como entregado

### 3. Monitoreo de Estado de Pago

#### Polling (Opción Simple)
```typescript
const pollPaymentStatus = async (paymentAttemptId: string) => {
  const interval = setInterval(async () => {
    const attempt = await getPaymentAttempt(paymentAttemptId, jwt);
    
    if (attempt.status === "completed") {
      clearInterval(interval);
      navigation.navigate("OrderConfirmation");
    } else if (["failed", "expired", "cancelled"].includes(attempt.status)) {
      clearInterval(interval);
      showError("Pago no completado");
    }
  }, 3000); // Cada 3 segundos
};
```

#### Subscriptions (Opción Avanzada)
```graphql
subscription OnPaymentStatusChange($paymentAttemptId: String!) {
  paymentStatusChanged(paymentAttemptId: $paymentAttemptId) {
    id
    status
    completedAt
    failedReason
  }
}
```

**Nota:** Requiere implementar subscription en backend.

### 4. Pantallas Necesarias

#### 4.1 Selección de Método de Pago
```
┌─────────────────────────────┐
│ Selecciona método de pago   │
├─────────────────────────────┤
│ 💰 Wallet USD               │
│    Balance: $50.00          │
│    Sin comisión             │
├─────────────────────────────┤
│ 💳 Tarjeta (Stripe)         │
│    Comisión: 3.5%           │
│    Total: $56.93            │
├─────────────────────────────┤
│ 🏦 Transfermóvil            │
│    Comisión: 2%             │
│    Requiere confirmación    │
├─────────────────────────────┤
│ 💵 Efectivo                 │
│    Recargo delivery: 5%     │
│    Paga al recibir          │
└─────────────────────────────┘
```

#### 4.2 Resumen de Pago
```
┌─────────────────────────────┐
│ Resumen del pago            │
├─────────────────────────────┤
│ Subtotal:        $50.00     │
│ Delivery:         $5.00     │
│ Comisión (3.5%):  $1.93     │
├─────────────────────────────┤
│ Total:           $56.93     │
│                             │
│ [Confirmar Pago]            │
└─────────────────────────────┘
```

#### 4.3 Estado de Pago (Transferencias)
```
┌─────────────────────────────┐
│ ⏳ Esperando confirmación   │
├─────────────────────────────┤
│ Tu comprobante:             │
│ [Imagen del comprobante]    │
│                             │
│ El negocio confirmará       │
│ cuando reciba el pago       │
│                             │
│ Expira en: 47h 23m          │
│                             │
│ [Cancelar pago]             │
└─────────────────────────────┘
```

#### 4.4 Pago Completado
```
┌─────────────────────────────┐
│        ✅ ¡Pago exitoso!    │
├─────────────────────────────┤
│ Pedido #12345               │
│ Total pagado: $56.93        │
│                             │
│ El negocio está preparando  │
│ tu pedido                   │
│                             │
│ [Ver mi pedido]             │
│ [Volver al inicio]          │
└─────────────────────────────┘
```

### 5. Manejo de Errores

```typescript
const handlePaymentError = (error: any) => {
  const errorMessages = {
    "Saldo insuficiente": "No tienes suficiente saldo en tu wallet",
    "Método de pago no disponible": "Este método de pago no está disponible",
    "Ya existe un intento de pago activo": "Ya hay un pago en proceso para este pedido",
    "El pedido no está en un estado que permita pago": "Este pedido no puede ser pagado",
  };
  
  const message = errorMessages[error.message] || "Error al procesar el pago";
  
  Alert.alert("Error", message, [
    { text: "Reintentar", onPress: () => retryPayment() },
    { text: "Cancelar", style: "cancel" }
  ]);
};
```

### 6. Notificaciones Push

Implementar notificaciones para:

1. **Pago completado** (wallet/stripe)
   - "✅ Pago confirmado - Pedido #12345"

2. **Pago fallido**
   - "❌ Pago rechazado - Intenta otro método"

3. **Negocio confirmó transferencia**
   - "✅ El negocio confirmó tu pago"

4. **Pago disputado**
   - "⚠️ El negocio reportó no haber recibido el pago"

5. **Pago expirado**
   - "⏰ Tu pago expiró - Intenta nuevamente"

6. **Reembolso procesado**
   - "💰 Reembolso de $50.00 procesado"

### 7. Queries Útiles

#### Verificar Balance de Wallet
```graphql
query GetWalletBalance($jwt: String!) {
  walletBalance(jwt: $jwt) {
    local
    usd
  }
}
```

#### Obtener Historial de Pagos
```graphql
query GetOrderPayments($orderId: String!, $jwt: String!) {
  paymentAttemptsByOrder(orderId: $orderId, jwt: $jwt) {
    id
    status
    totalAmount
    currency
    createdAt
    completedAt
    failedReason
  }
}
```

#### Verificar Pago Activo
```graphql
query GetActivePayment($orderId: String!, $jwt: String!) {
  activePaymentAttempt(orderId: $orderId, jwt: $jwt) {
    id
    status
    totalAmount
    expiresAt
  }
}
```

## 🔧 Configuración Necesaria

### 1. Stripe SDK

**iOS:**
```bash
cd ios && pod install
```

**Android:**
```gradle
// android/app/build.gradle
dependencies {
    implementation 'com.stripe:stripe-android:20.x.x'
}
```

### 2. Permisos de Cámara (para comprobantes)

**iOS (Info.plist):**
```xml
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceso a tu cámara para subir comprobantes de pago</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Necesitamos acceso a tus fotos para subir comprobantes de pago</string>
```

**Android (AndroidManifest.xml):**
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### 3. Upload de Imágenes

Usar el endpoint existente:
```typescript
const uploadProofImage = async (imageFile: File) => {
  const formData = new FormData();
  formData.append('file', imageFile);
  
  const response = await fetch('/api/uploads', {
    method: 'POST',
    headers: { Authorization: `Bearer ${jwt}` },
    body: formData
  });
  
  const { url } = await response.json();
  return url;
};
```

## ⚠️ Consideraciones Importantes

### 1. Seguridad
- ✅ Todas las mutations requieren JWT
- ✅ Verificación de ownership en cada operación
- ✅ Webhook de Stripe con verificación de firma
- ⚠️ Implementar rate limiting en endpoints críticos

### 2. UX
- Mostrar loaders durante procesamiento
- Feedback inmediato en cada acción
- Mensajes de error claros y accionables
- Timer visible para pagos con expiración
- Confirmación antes de cancelar pagos

### 3. Testing
- Probar cada flujo de pago end-to-end
- Usar tarjetas de prueba de Stripe
- Simular fallos de red
- Probar expiración de pagos
- Verificar notificaciones push

### 4. Monitoreo
- Log de todos los intentos de pago
- Alertas para pagos fallidos frecuentes
- Dashboard de conversión por método
- Tracking de comisiones recolectadas

## 📋 Checklist de Implementación

### Backend (Antes de Frontend)
- [ ] Ejecutar `python scripts/migrate_payment_methods.py`
- [ ] Verificar que se crearon los 6 métodos de pago
- [ ] Verificar documento de plataforma creado
- [ ] Configurar variables de entorno de Stripe
- [ ] Probar webhook de Stripe con Stripe CLI
- [ ] Implementar background job para expiración
- [ ] Actualizar `OrderService.create_order()` para usar `PENDING_PAYMENT`

### Frontend - Fase 1 (MVP)
- [ ] Instalar Stripe SDK
- [ ] Implementar pantalla de selección de método
- [ ] Implementar flujo de Wallet
- [ ] Implementar flujo de Stripe
- [ ] Implementar pantalla de confirmación
- [ ] Manejo básico de errores

### Frontend - Fase 2 (Completo)
- [ ] Implementar flujo de transferencias
- [ ] Implementar upload de comprobantes
- [ ] Implementar flujo de efectivo
- [ ] Implementar polling/subscriptions de estado
- [ ] Implementar notificaciones push
- [ ] Implementar pantallas de error/retry
- [ ] Testing end-to-end

### Frontend - Fase 3 (Avanzado)
- [ ] Implementar solicitud de reembolsos
- [ ] Implementar historial de pagos
- [ ] Implementar analytics de conversión
- [ ] Optimizar UX basado en métricas
- [ ] A/B testing de flujos

## 🚀 Orden de Implementación Recomendado

1. **Semana 1: Backend + Wallet**
   - Ejecutar migración
   - Configurar Stripe
   - Implementar flujo de Wallet en frontend
   - Testing básico

2. **Semana 2: Stripe**
   - Integrar Stripe SDK
   - Implementar flujo completo
   - Testing con tarjetas de prueba

3. **Semana 3: Transferencias**
   - Implementar upload de comprobantes
   - Flujo de confirmación
   - Notificaciones

4. **Semana 4: Efectivo + Polish**
   - Implementar flujo de efectivo
   - Pulir UX
   - Testing completo
   - Deploy a producción

## 📞 Soporte

Si encuentras problemas durante la integración:
1. Revisar logs del backend
2. Verificar que la migración se ejecutó correctamente
3. Probar queries/mutations en GraphQL Playground
4. Revisar documentación de Stripe

---

**Última actualización:** Enero 2026  
**Versión:** 1.0
