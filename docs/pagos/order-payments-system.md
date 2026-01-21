# Sistema de Pagos para Pedidos - Llego Platform

## Descripción General

Sistema completo de procesamiento de pagos para pedidos que soporta múltiples métodos de pago (wallet, Stripe, transferencias bancarias, efectivo), gestión de comisiones, reembolsos y disputas.

## Arquitectura

### Componentes Principales

```
payments/
├── models.py          # Modelos de datos (PaymentAttempt, RefundRequest)
├── repository.py      # Operaciones de base de datos
├── service.py         # Lógica de negocio
└── __init__.py        # Exports del módulo

llego_platform/
├── models.py          # Platform, PlatformWallet (comisiones)
└── repository.py      # PlatformRepository

schema/payments/
├── types.py           # Tipos GraphQL
├── mutations.py       # Mutaciones GraphQL (7 operaciones)
└── queries.py         # Queries GraphQL (6 operaciones)
```

## Modelos de Datos

### PaymentAttempt

Representa un intento de pago para un pedido. Rastrea el ciclo de vida completo desde la iniciación hasta la finalización, incluyendo reembolsos y disputas.

**Estados del Pago:**

```python
class PaymentAttemptStatus(Enum):
    # Estados iniciales
    PENDING = "pending"                    # Recién creado
    PROCESSING = "processing"              # En proceso (Stripe, wallet)
    
    # Estados de pagos manuales
    AWAITING_PROOF = "awaiting_proof"      # Esperando comprobante del cliente
    AWAITING_BUSINESS = "awaiting_business" # Esperando confirmación del negocio
    
    # Estados de pago en efectivo
    AWAITING_DELIVERY = "awaiting_delivery" # Esperando confirmación de entrega
    
    # Estados finales
    COMPLETED = "completed"                # Pago exitoso
    FAILED = "failed"                      # Pago fallido
    EXPIRED = "expired"                    # Expirado por tiempo
    CANCELLED = "cancelled"                # Cancelado por usuario/sistema
    
    # Estados de disputa
    DISPUTED = "disputed"                  # Negocio reclama no recibido
    
    # Estados de reembolso
    REFUND_REQUESTED = "refund_requested"  # Cliente solicitó reembolso
    REFUND_PROCESSING = "refund_processing" # Reembolso en proceso
    REFUNDED = "refunded"                  # Reembolso completado
```

**Campos Principales:**

```python
{
    "id": str,
    "orderId": str,
    "paymentMethodId": str,
    
    # Montos (calculados al iniciar el pago)
    "subtotal": float,              # Total de items del pedido
    "deliveryFee": float,           # Tarifa de entrega
    "includesDeliveryFee": bool,    # False si entrega se paga aparte en efectivo
    "taxAmount": float,             # Impuestos (futuro)
    "discountAmount": float,        # Descuentos (futuro)
    "commissionAmount": float,      # Comisión cobrada al cliente
    "totalAmount": float,           # Monto final a pagar
    "currency": str,                # "usd" o "local" (CUP)
    
    # Estado
    "status": PaymentAttemptStatus,
    
    # Campos específicos de Stripe
    "stripePaymentIntentId": str,
    "stripeClientSecret": str,
    
    # Campos de pagos manuales
    "proofUrl": str,                # Comprobante subido por cliente
    "customerConfirmedAt": datetime,
    "businessConfirmedAt": datetime,
    "disputeReason": str,
    
    # Campos de pago en efectivo
    "deliveryPersonConfirmedAt": datetime,
    "deliveryPersonId": str,
    
    # Referencias a transacciones de wallet
    "walletTransactionId": str,
    "businessWalletTransactionId": str,
    "commissionTransactionId": str,
    
    # Campos de reembolso
    "refundRequestedAt": datetime,
    "refundReason": str,
    "refundedAt": datetime,
    "refundTransactionId": str,
    "refundAmount": float,
    
    # Ciclo de vida
    "expiresAt": datetime,
    "completedAt": datetime,
    "failedAt": datetime,
    "failedReason": str,
    "createdAt": datetime,
    "updatedAt": datetime
}
```

### PaymentMethod

Define los métodos de pago disponibles con sus tasas de comisión, políticas de reembolso y configuración.

```python
{
    "id": str,
    "name": str,                    # "Wallet USD", "Transfermóvil", "Stripe"
    "code": str,                    # "wallet_usd", "transfermovil", "stripe"
    "currency": str,                # "CUP", "USD"
    "method": str,                  # "wallet", "transfer", "stripe", "cash"
    
    # Configuración de comisiones
    "commissionPercent": float,     # % cobrado al cliente (ej: 2.5 = 2.5%)
    "deliveryFeePercent": float,    # % extra para efectivo cubriendo entrega
    
    # Configuración de reembolsos y confirmación
    "isRefundable": bool,
    "requiresProof": bool,          # True para transferencias bancarias
    "requiresBusinessConfirmation": bool,  # True para métodos manuales
    "expirationMinutes": int,       # Tiempo límite (null = sin límite)
    
    # Configuración de visualización
    "isActive": bool,
    "displayOrder": int,
    "iconUrl": str,
    "instructions": str,            # "Transferir a cuenta X..."
    
    "createdAt": datetime,
    "updatedAt": datetime
}
```

### Platform

Entidad singleton que almacena la configuración del sistema y el wallet de la plataforma donde se recolectan las comisiones.

```python
{
    "id": "platform",               # Siempre "platform" (singleton)
    "name": "Llego",
    "wallet": {
        "local": float,             # Balance en CUP
        "usd": float                # Balance en USD
    },
    "walletStatus": str,            # "active", "frozen"
    "totalCommissionsCollected": float,
    "totalOrdersProcessed": int,
    "createdAt": datetime,
    "updatedAt": datetime
}
```

## Flujos de Pago

### 1. Pago con Wallet

**Flujo:**
1. Cliente inicia pago → `initiatePayment()`
2. Sistema verifica saldo
3. Si hay saldo suficiente:
   - Debita wallet del cliente
   - Acredita wallet del negocio (subtotal + delivery)
   - Acredita wallet de plataforma (comisión)
   - Crea transacciones de wallet
   - Marca pago como COMPLETED
4. Si no hay saldo: marca como FAILED

**Características:**
- Procesamiento instantáneo
- Sin comisión adicional (0%)
- Reembolsable
- No requiere confirmación manual

### 2. Pago con Stripe

**Flujo:**
1. Cliente inicia pago → `initiatePayment()`
2. Sistema crea Payment Intent en Stripe
3. Retorna `clientSecret` al cliente
4. Cliente completa pago en la app
5. Webhook de Stripe notifica éxito/fallo
6. Sistema procesa webhook:
   - Acredita wallet del negocio
   - Acredita comisión a plataforma
   - Marca pago como COMPLETED

**Características:**
- Comisión: 3.5%
- Expiración: 30 minutos
- Reembolsable (vía Stripe Refund API)
- No requiere confirmación manual

### 3. Pago con Transferencia Bancaria (Transfermóvil)

**Flujo:**
1. Cliente inicia pago → `initiatePayment()`
2. Sistema retorna instrucciones de transferencia
3. Estado: AWAITING_PROOF
4. Cliente realiza transferencia y sube comprobante → `confirmPaymentSent()`
5. Estado: AWAITING_BUSINESS
6. Negocio confirma recepción → `confirmPaymentReceived()`
7. Estado: COMPLETED

**Características:**
- Comisión: 2%
- Expiración: 48 horas
- No reembolsable automáticamente
- Requiere comprobante y confirmación del negocio
- Puede ser disputado por el negocio

### 4. Pago en Efectivo

**Flujo:**
1. Cliente inicia pago → `initiatePayment()`
2. Estado: AWAITING_DELIVERY
3. Repartidor entrega pedido y recibe efectivo
4. Repartidor confirma → `confirmCashReceived()`
5. Sistema registra transacciones
6. Estado: COMPLETED

**Características:**
- Sin comisión base
- Recargo del 5% sobre tarifa de entrega
- Sin expiración (espera entrega)
- No reembolsable
- Confirmado por repartidor

## API GraphQL

### Mutations

#### 1. initiatePayment

Inicia un pago para un pedido.

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

**Respuestas según método:**
- **Wallet**: `status: COMPLETED` o `FAILED` (inmediato)
- **Stripe**: `status: PROCESSING`, incluye `stripeClientSecret`
- **Transfer**: `status: AWAITING_PROOF`, incluye `instructions`
- **Cash**: `status: AWAITING_DELIVERY`

#### 2. confirmPaymentSent

Cliente confirma que envió el pago (transferencias).

```graphql
mutation ConfirmPaymentSent(
  $paymentAttemptId: String!
  $proofUrl: String!
  $jwt: String!
) {
  confirmPaymentSent(
    paymentAttemptId: $paymentAttemptId
    proofUrl: $proofUrl
    jwt: $jwt
  ) {
    id
    status
    proofUrl
    customerConfirmedAt
  }
}
```

#### 3. confirmPaymentReceived

Negocio confirma que recibió el pago.

```graphql
mutation ConfirmPaymentReceived(
  $paymentAttemptId: String!
  $jwt: String!
) {
  confirmPaymentReceived(
    paymentAttemptId: $paymentAttemptId
    jwt: $jwt
  ) {
    id
    status
    businessConfirmedAt
    completedAt
  }
}
```

#### 4. confirmCashReceived

Repartidor confirma que recibió el efectivo.

```graphql
mutation ConfirmCashReceived(
  $paymentAttemptId: String!
  $jwt: String!
) {
  confirmCashReceived(
    paymentAttemptId: $paymentAttemptId
    jwt: $jwt
  ) {
    id
    status
    deliveryPersonConfirmedAt
    completedAt
  }
}
```

#### 5. disputePayment

Negocio disputa que no recibió el pago.

```graphql
mutation DisputePayment(
  $paymentAttemptId: String!
  $reason: String!
  $jwt: String!
) {
  disputePayment(
    paymentAttemptId: $paymentAttemptId
    reason: $reason
    jwt: $jwt
  ) {
    id
    status
    disputeReason
  }
}
```

#### 6. requestRefund

Cliente solicita reembolso.

```graphql
mutation RequestRefund(
  $paymentAttemptId: String!
  $reason: String!
  $jwt: String!
) {
  requestRefund(
    paymentAttemptId: $paymentAttemptId
    reason: $reason
    jwt: $jwt
  ) {
    id
    status
    refundRequestedAt
    refundReason
  }
}
```

**Restricciones:**
- Solo pagos completados
- Método debe ser reembolsable
- Pedido no debe estar entregado o en camino

#### 7. cancelPayment

Cancela un intento de pago pendiente.

```graphql
mutation CancelPayment(
  $paymentAttemptId: String!
  $jwt: String!
) {
  cancelPayment(
    paymentAttemptId: $paymentAttemptId
    jwt: $jwt
  ) {
    id
    status
  }
}
```

**Estados cancelables:**
- PENDING
- AWAITING_PROOF
- PROCESSING

### Queries

#### 1. paymentMethods

Obtiene todos los métodos de pago disponibles.

```graphql
query GetPaymentMethods($jwt: String) {
  paymentMethods(jwt: $jwt) {
    id
    name
    code
    currency
    method
    commissionPercent
    isActive
    instructions
  }
}
```

#### 2. paymentMethod

Obtiene un método de pago por ID.

```graphql
query GetPaymentMethod($id: String!, $jwt: String) {
  paymentMethod(id: $id, jwt: $jwt) {
    id
    name
    commissionPercent
    deliveryFeePercent
    isRefundable
    requiresProof
    expirationMinutes
  }
}
```

#### 3. paymentMethodsByCurrency

Filtra métodos de pago por moneda.

```graphql
query GetPaymentMethodsByCurrency($currency: String!, $jwt: String) {
  paymentMethodsByCurrency(currency: $currency, jwt: $jwt) {
    id
    name
    code
  }
}
```

#### 4. paymentAttempt

Obtiene un intento de pago por ID.

```graphql
query GetPaymentAttempt($id: String!, $jwt: String!) {
  paymentAttempt(id: $id, jwt: $jwt) {
    id
    orderId
    status
    totalAmount
    currency
    createdAt
    completedAt
  }
}
```

#### 5. paymentAttemptsByOrder

Obtiene todos los intentos de pago de un pedido.

```graphql
query GetPaymentAttemptsByOrder($orderId: String!, $jwt: String!) {
  paymentAttemptsByOrder(orderId: $orderId, jwt: $jwt) {
    id
    status
    totalAmount
    createdAt
  }
}
```

#### 6. activePaymentAttempt

Obtiene el intento de pago activo de un pedido.

```graphql
query GetActivePaymentAttempt($orderId: String!, $jwt: String!) {
  activePaymentAttempt(orderId: $orderId, jwt: $jwt) {
    id
    status
    totalAmount
    expiresAt
  }
}
```

## Cálculo de Montos

### Fórmula General

```python
subtotal = sum(item.price * item.quantity for item in order.items)
delivery_fee = order.deliveryFee  # Si includeDeliveryFee = True

# Para efectivo, aplicar recargo a delivery
if method == "cash" and includeDeliveryFee:
    delivery_fee = delivery_fee * (1 + deliveryFeePercent / 100)

base_amount = subtotal + delivery_fee
commission = base_amount * (commissionPercent / 100)
total = subtotal + delivery_fee + commission
```

### Ejemplo: Pedido de $50 con entrega de $5

**Wallet USD (0% comisión):**
```
Subtotal: $50.00
Delivery: $5.00
Comisión: $0.00
Total: $55.00
```

**Stripe (3.5% comisión):**
```
Subtotal: $50.00
Delivery: $5.00
Base: $55.00
Comisión: $1.93 (3.5% de $55)
Total: $56.93
```

**Efectivo CUP (0% comisión, 5% recargo en delivery):**
```
Subtotal: 1250 CUP
Delivery base: 125 CUP
Delivery con recargo: 131.25 CUP (125 * 1.05)
Comisión: 0 CUP
Total: 1381.25 CUP
```

## Gestión de Comisiones

### Flujo de Comisiones

1. **Pago Wallet/Stripe**: Comisión se acredita inmediatamente al wallet de plataforma
2. **Pago Efectivo**: Comisión queda pendiente (owed) hasta que negocio liquide con plataforma

### Transacciones de Wallet

Cada pago genera hasta 3 transacciones:

```python
# 1. Débito del cliente (wallet/stripe)
{
    "fromOwnerId": user_id,
    "fromOwnerType": "user",
    "toOwnerId": branch_id,
    "toOwnerType": "branch",
    "amount": subtotal + delivery_fee,
    "type": "order_payment"
}

# 2. Crédito al negocio
{
    "fromOwnerId": user_id,
    "fromOwnerType": "user",
    "toOwnerId": branch_id,
    "toOwnerType": "branch",
    "amount": subtotal + delivery_fee,
    "type": "order_received"
}

# 3. Comisión a plataforma
{
    "fromOwnerId": user_id,
    "fromOwnerType": "user",
    "toOwnerId": "platform",
    "toOwnerType": "platform",
    "amount": commission,
    "type": "commission"
}
```

## Reembolsos

### Proceso de Reembolso

1. Cliente solicita reembolso → `requestRefund()`
2. Estado: REFUND_REQUESTED
3. Admin/sistema aprueba → `process_refund()` (interno)
4. Estado: REFUND_PROCESSING
5. Según método:
   - **Wallet**: Reversa transacciones automáticamente
   - **Stripe**: Crea Stripe Refund
   - **Manual**: Requiere proceso manual
6. Estado: REFUNDED

### Monto de Reembolso

```python
refund_amount = subtotal + delivery_fee  # Sin incluir comisión
```

La comisión NO se reembolsa al cliente (costo del servicio).

## Webhooks de Stripe

### Endpoint

```
POST /api/stripe/webhook
```

### Eventos Manejados

#### payment_intent.succeeded

```python
# 1. Buscar PaymentAttempt por stripePaymentIntentId
# 2. Acreditar wallet del negocio
# 3. Acreditar comisión a plataforma
# 4. Crear transacciones de wallet
# 5. Actualizar estado a COMPLETED
# 6. Actualizar pedido: paymentStatus = "completed"
```

#### payment_intent.payment_failed

```python
# 1. Buscar PaymentAttempt
# 2. Actualizar estado a FAILED
# 3. Registrar razón del fallo
```

## Expiración de Pagos

### Background Job

Ejecutar periódicamente (cada 5-10 minutos):

```python
expired_count = await payment_service.expire_payments()
```

Marca como EXPIRED todos los pagos que:
- Estado: PENDING, AWAITING_PROOF, AWAITING_BUSINESS
- `expiresAt` < now

## Índices de MongoDB

```python
# payment_attempts
db.payment_attempts.createIndex({"orderId": 1})
db.payment_attempts.createIndex({"stripePaymentIntentId": 1}, {sparse: true})
db.payment_attempts.createIndex({"status": 1, "expiresAt": 1})
db.payment_attempts.createIndex({"createdAt": 1})

# orders
db.orders.createIndex({"currentPaymentAttemptId": 1}, {sparse: true})
```

## Migración

### Ejecutar Script

```bash
python scripts/migrate_payment_methods.py
```

### Acciones del Script

1. **Crea 6 métodos de pago iniciales:**
   - Wallet USD (0% comisión)
   - Wallet CUP (0% comisión)
   - Stripe (3.5% comisión, 30 min expiración)
   - Transfermóvil (2% comisión, 48h expiración)
   - Efectivo CUP (5% recargo en delivery)
   - Efectivo USD (5% recargo en delivery)

2. **Crea documento de plataforma:**
   - ID: "platform"
   - Wallet inicial: {local: 0, usd: 0}

3. **Crea índices necesarios:**
   - payment_attempts
   - orders (currentPaymentAttemptId)

## Seguridad y Autorización

### Verificaciones por Operación

**initiatePayment:**
- Usuario debe ser dueño del pedido
- Pedido debe estar en estado pagable
- No debe haber pago activo

**confirmPaymentSent:**
- Usuario debe ser dueño del pedido

**confirmPaymentReceived:**
- Usuario debe ser manager o dueño del negocio

**confirmCashReceived:**
- Usuario debe ser el repartidor asignado

**disputePayment:**
- Usuario debe ser manager o dueño del negocio

**requestRefund:**
- Usuario debe ser dueño del pedido
- Método debe ser reembolsable
- Pedido no debe estar entregado

## Manejo de Errores

### Errores Comunes

```python
# Saldo insuficiente
"Saldo insuficiente en wallet"

# Pedido no pagable
"El pedido no está en un estado que permita pago: delivered"

# Pago activo existente
"Ya existe un intento de pago activo para este pedido"

# Método no disponible
"Método de pago no disponible"

# No autorizado
"No autorizado para confirmar este pago"

# Estado inválido
"Estado no válido para confirmar: completed"

# No reembolsable
"Este método de pago no permite reembolsos"
```

## Mejoras Futuras

1. **Impuestos**: Agregar cálculo de `taxAmount`
2. **Descuentos**: Implementar `discountAmount` con cupones
3. **Pagos parciales**: Permitir pagar delivery por separado
4. **Notificaciones**: Push notifications en cada cambio de estado
5. **Dashboard de comisiones**: Panel para ver comisiones recolectadas
6. **Liquidación automática**: Transferir fondos de plataforma a cuenta bancaria
7. **Reportes**: Generar reportes de pagos por período
8. **Webhooks salientes**: Notificar a sistemas externos de cambios de estado

## Testing

### Casos de Prueba Recomendados

1. **Wallet con saldo suficiente** → COMPLETED inmediato
2. **Wallet sin saldo** → FAILED inmediato
3. **Stripe exitoso** → Webhook → COMPLETED
4. **Stripe fallido** → Webhook → FAILED
5. **Transferencia completa** → AWAITING_PROOF → AWAITING_BUSINESS → COMPLETED
6. **Transferencia disputada** → DISPUTED
7. **Efectivo** → AWAITING_DELIVERY → COMPLETED
8. **Reembolso wallet** → Reversa transacciones
9. **Reembolso Stripe** → Stripe Refund API
10. **Cancelación** → CANCELLED
11. **Expiración** → EXPIRED

## Soporte

Para preguntas o problemas con el sistema de pagos, contactar al equipo de desarrollo.

---

**Versión:** 1.0  
**Última actualización:** Enero 2026  
**Autor:** Llego Platform Team
