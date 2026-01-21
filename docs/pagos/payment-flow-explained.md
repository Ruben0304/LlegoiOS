# Flujo de Pago - Explicación Visual

## 🎯 Flujo Principal

```
┌─────────────────────────────────────────────────────────────────┐
│                    1. CLIENTE CREA ORDEN                        │
│                                                                 │
│  Cliente selecciona productos y crea orden                      │
│  Estado: PENDING_ACCEPTANCE                                     │
│  Pago: NO requerido aún                                         │
│                                                                 │
│  ❌ NO puede pagar en este punto                                │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│              2. NEGOCIO REVISA Y ACEPTA/MODIFICA                │
│                                                                 │
│  Negocio puede:                                                 │
│  - Aceptar la orden tal cual                                    │
│  - Modificar items/precios                                      │
│  - Rechazar/cancelar                                            │
│                                                                 │
│  Si acepta → Estado: ACCEPTED                                   │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                  3. 🔴 BLOQUEO DE PAGO                          │
│                                                                 │
│  Cliente recibe notificación: "Debes pagar para continuar"     │
│  Estado: ACCEPTED (bloqueado)                                   │
│                                                                 │
│  ✅ AHORA SÍ puede pagar                                        │
│  ❌ Negocio NO puede continuar sin pago                         │
│                                                                 │
│  Excepciones:                                                   │
│  - Efectivo: No requiere pago previo                            │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                    4. CLIENTE PAGA                              │
│                                                                 │
│  Opciones:                                                      │
│  A) Wallet → Instantáneo                                        │
│  B) Stripe → Completa en app                                    │
│  C) Transferencia → Sube comprobante → Espera confirmación     │
│  D) Efectivo → Paga al recibir (no bloquea)                     │
│                                                                 │
│  Cuando pago se completa:                                       │
│  - paymentStatus: COMPLETED                                     │
│  - paidAt: timestamp                                            │
│  - currentPaymentAttemptId: ID del pago                         │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                5. NEGOCIO CONTINÚA FLUJO                        │
│                                                                 │
│  ✅ Ahora SÍ puede marcar como:                                 │
│  PREPARING → READY_FOR_PICKUP → ON_THE_WAY → DELIVERED         │
└─────────────────────────────────────────────────────────────────┘
```

## 📱 Flujos por Método de Pago

### A. Wallet (Instantáneo)

```
Cliente en pantalla de pago
         ↓
Selecciona "Wallet USD"
         ↓
Presiona "Pagar $56.93"
         ↓
Backend verifica saldo
         ↓
    ¿Tiene saldo?
    ├─ SÍ → Debita wallet
    │        Acredita a negocio
    │        Acredita comisión
    │        ✅ COMPLETED
    │        Redirige a confirmación
    │
    └─ NO → ❌ FAILED
             Muestra error
             "Saldo insuficiente"
```

**Tiempo:** < 1 segundo

### B. Stripe (Requiere UI)

```
Cliente en pantalla de pago
         ↓
Selecciona "Tarjeta (Stripe)"
         ↓
Backend crea Payment Intent
         ↓
Retorna clientSecret
         ↓
App muestra Stripe Payment Sheet
         ↓
Cliente ingresa tarjeta
         ↓
Stripe procesa pago
         ↓
    ¿Exitoso?
    ├─ SÍ → Webhook notifica backend
    │        Backend acredita a negocio
    │        ✅ COMPLETED
    │        App redirige a confirmación
    │
    └─ NO → ❌ FAILED
             Muestra error de Stripe
             "Tarjeta rechazada"
```

**Tiempo:** 5-30 segundos

### C. Transferencia Bancaria (Manual)

```
Cliente en pantalla de pago
         ↓
Selecciona "Transfermóvil"
         ↓
Ve instrucciones:
"Transfiere a: 5355-1234-5678"
         ↓
Cliente sale de la app
Hace transferencia en su banco
         ↓
Vuelve a la app
Sube foto del comprobante
         ↓
Estado: AWAITING_BUSINESS
         ↓
Negocio revisa comprobante
Verifica que recibió el dinero
         ↓
    ¿Recibió?
    ├─ SÍ → Confirma en su app
    │        ✅ COMPLETED
    │        Cliente recibe notificación
    │
    └─ NO → Disputa
             "No recibí el pago"
             Estado: DISPUTED
             Requiere intervención
```

**Tiempo:** 10 minutos - 48 horas

### D. Efectivo (En Entrega)

```
Cliente en pantalla de pago
         ↓
Selecciona "Efectivo"
         ↓
Ve mensaje:
"Pagarás $58.00 al recibir"
(incluye recargo del 5%)
         ↓
Estado: AWAITING_DELIVERY
         ↓
Orden continúa flujo normal
(NO se bloquea por pago)
         ↓
Repartidor entrega
Cliente paga en efectivo
         ↓
Repartidor confirma en su app
"Recibí $58.00 en efectivo"
         ↓
✅ COMPLETED
```

**Tiempo:** Al momento de entrega

## 🔒 Validaciones Críticas

### 1. ¿Cuándo puede pagar el cliente?

```python
# En payments/service.py

payable_statuses = ["accepted", "modified_by_store"]

# ✅ Puede pagar:
- Orden en estado ACCEPTED
- Orden en estado MODIFIED_BY_STORE

# ❌ NO puede pagar:
- Orden en PENDING_ACCEPTANCE (negocio no ha aceptado)
- Orden en PREPARING (ya está pagada)
- Orden en DELIVERED (ya completada)
- Orden en CANCELLED (cancelada)
```

### 2. ¿Cuándo puede continuar el negocio?

```python
# En orders/service.py

# Para marcar como PREPARING:
if new_status == "preparing":
    payment_method = order.paymentMethod
    
    # ✅ Puede continuar:
    if payment_method in ["cash", "efectivo"]:
        # Efectivo no requiere pago previo
        return True
    
    if order.paymentStatus == "completed":
        # Ya está pagado
        return True
    
    # ❌ NO puede continuar:
    raise ValueError("Debe estar pagado primero")
```

### 3. ¿Qué pasa si no paga?

```python
# Background job cada 10 minutos

# Si orden está en ACCEPTED por más de 30 min sin pago:
if order.status == "accepted" and \
   order.paymentStatus != "completed" and \
   order.paymentMethod not in ["cash", "efectivo"] and \
   (now - order.lastStatusAt) > 30_minutes:
    
    # Cancelar automáticamente
    order.status = "cancelled"
    order.cancellationReason = "Pago no completado"
    
    # Notificar cliente
    send_notification("Tu orden fue cancelada por falta de pago")
```

## 📊 Estados de Pago

### PaymentStatus (en Order)

```python
PENDING = "pending"      # Aún no pagado
VALIDATED = "validated"  # (Obsoleto, no usar)
COMPLETED = "completed"  # ✅ Pagado exitosamente
FAILED = "failed"        # ❌ Pago falló
```

### PaymentAttemptStatus (en PaymentAttempt)

```python
# Iniciales
PENDING = "pending"                # Recién creado
PROCESSING = "processing"          # Procesando (Stripe)

# Manuales
AWAITING_PROOF = "awaiting_proof"  # Esperando comprobante
AWAITING_BUSINESS = "awaiting_business"  # Esperando confirmación negocio

# Efectivo
AWAITING_DELIVERY = "awaiting_delivery"  # Esperando entrega

# Finales
COMPLETED = "completed"    # ✅ Exitoso
FAILED = "failed"          # ❌ Fallido
EXPIRED = "expired"        # ⏰ Expiró
CANCELLED = "cancelled"    # 🚫 Cancelado

# Especiales
DISPUTED = "disputed"              # ⚠️ Disputado
REFUND_REQUESTED = "refund_requested"  # 💰 Reembolso solicitado
REFUNDED = "refunded"              # 💰 Reembolsado
```

## 🎨 Pantallas del Frontend

### Pantalla 1: Orden Aceptada (Cliente)

```
┌─────────────────────────────────┐
│ ✅ ¡Orden Aceptada!             │
├─────────────────────────────────┤
│                                 │
│ Pedido #12345                   │
│ La Bodeguita del Medio          │
│                                 │
│ 🔴 Debes completar el pago      │
│    para que preparen tu pedido  │
│                                 │
│ Total a pagar: $56.93           │
│                                 │
│ [Pagar Ahora]                   │
│                                 │
│ Expira en: 29:45                │
└─────────────────────────────────┘
```

### Pantalla 2: Selección de Método

```
┌─────────────────────────────────┐
│ Selecciona método de pago       │
├─────────────────────────────────┤
│                                 │
│ 💰 Wallet USD                   │
│    Balance: $120.00             │
│    Total: $56.93                │
│    ✅ Instantáneo               │
│                                 │
├─────────────────────────────────┤
│                                 │
│ 💳 Tarjeta (Stripe)             │
│    Comisión: 3.5%               │
│    Total: $58.92                │
│    ⚡ 30 segundos               │
│                                 │
├─────────────────────────────────┤
│                                 │
│ 🏦 Transfermóvil                │
│    Comisión: 2%                 │
│    Total: $58.08                │
│    ⏰ Requiere confirmación     │
│                                 │
├─────────────────────────────────┤
│                                 │
│ 💵 Efectivo                     │
│    Recargo: 5% en delivery      │
│    Total: $58.75                │
│    📦 Paga al recibir           │
│                                 │
└─────────────────────────────────┘
```

### Pantalla 3: Pago Completado

```
┌─────────────────────────────────┐
│        ✅ ¡Pago Exitoso!        │
├─────────────────────────────────┤
│                                 │
│ Pedido #12345                   │
│ Pagado: $56.93                  │
│                                 │
│ El negocio está preparando      │
│ tu pedido                       │
│                                 │
│ Tiempo estimado: 30 min         │
│                                 │
│ [Rastrear Pedido]               │
│ [Volver al Inicio]              │
│                                 │
└─────────────────────────────────┘
```

### Pantalla 4: Esperando Pago (Negocio)

```
┌─────────────────────────────────┐
│ Pedido #12345                   │
├─────────────────────────────────┤
│                                 │
│ Estado: Aceptado                │
│ 🔴 Esperando pago del cliente   │
│                                 │
│ Cliente: Juan Pérez             │
│ Total: $56.93                   │
│ Método: Wallet USD              │
│                                 │
│ ⏰ Hace 5 minutos               │
│                                 │
│ [Cancelar Orden]                │
│                                 │
└─────────────────────────────────┘
```

### Pantalla 5: Listo para Preparar (Negocio)

```
┌─────────────────────────────────┐
│ Pedido #12345                   │
├─────────────────────────────────┤
│                                 │
│ Estado: Aceptado                │
│ ✅ Pagado: $56.93               │
│                                 │
│ Cliente: Juan Pérez             │
│ Método: Wallet USD              │
│                                 │
│ Items:                          │
│ - 2x Hamburguesa                │
│ - 1x Papas Fritas               │
│                                 │
│ [Comenzar a Preparar]           │
│                                 │
└─────────────────────────────────┘
```

## 🔧 Código de Ejemplo

### Frontend: Verificar si puede pagar

```typescript
const canPayOrder = (order: Order): boolean => {
  // Solo puede pagar si está aceptado y no pagado
  return (
    (order.status === "accepted" || order.status === "modified_by_store") &&
    order.paymentStatus !== "completed" &&
    order.paymentMethod !== "cash"
  );
};

// Uso:
if (canPayOrder(order)) {
  showPaymentButton();
} else if (order.status === "pending_acceptance") {
  showMessage("Esperando que el negocio acepte");
} else if (order.paymentStatus === "completed") {
  showMessage("Ya está pagado");
}
```

### Frontend: Verificar si negocio puede continuar

```typescript
const canPrepareOrder = (order: Order): boolean => {
  // Solo puede preparar si está pagado (o es efectivo)
  return (
    order.status === "accepted" &&
    (order.paymentStatus === "completed" || 
     order.paymentMethod === "cash")
  );
};

// Uso:
if (canPrepareOrder(order)) {
  showPrepareButton();
} else {
  showMessage("Esperando pago del cliente");
}
```

### Backend: Validar pago antes de preparar

```python
# En orders/service.py

async def update_order_status(
    self,
    order_id: str,
    new_status: str,
    user_id: str
) -> Order:
    """Update order status with validations."""
    
    order = await self.orders_repo.get_by_id(order_id)
    
    # Validar transición
    if new_status not in ALLOWED_TRANSITIONS.get(order.status, []):
        raise ValueError(f"No se puede cambiar de {order.status} a {new_status}")
    
    # VALIDACIÓN CRÍTICA: Pago antes de preparar
    if new_status == OrderStatus.PREPARING.value:
        payment_method = order.paymentMethod.lower()
        
        # Efectivo no requiere pago previo
        if payment_method not in ["cash", "efectivo"]:
            if order.paymentStatus != PaymentStatus.COMPLETED.value:
                raise ValueError(
                    "El pedido debe estar pagado antes de prepararse. "
                    "El cliente debe completar el pago primero."
                )
    
    # Actualizar estado
    updated_order = await self.orders_repo.update_status(
        order_id,
        new_status,
        user_id
    )
    
    return updated_order
```

## ✅ Checklist Final

### Backend
- [ ] Ejecutar migración
- [ ] Cambiar `payable_statuses` a `["accepted", "modified_by_store"]`
- [ ] Agregar validación de pago antes de PREPARING
- [ ] Configurar Stripe keys
- [ ] Implementar background job de expiración

### Frontend Cliente
- [ ] Pantalla: Orden aceptada → "Debes pagar"
- [ ] Pantalla: Selección de método de pago
- [ ] Flujo: Pago con Wallet
- [ ] Flujo: Pago con Stripe
- [ ] Flujo: Pago con Transferencia
- [ ] Flujo: Selección de Efectivo
- [ ] Pantalla: Pago completado
- [ ] Notificación: "Orden aceptada, paga ahora"
- [ ] Notificación: "Pago completado"

### Frontend Negocio
- [ ] Indicador: "Esperando pago" en orden aceptada
- [ ] Bloqueo: No puede preparar sin pago
- [ ] Notificación: "Cliente pagó, puedes preparar"
- [ ] Dashboard: Órdenes pendientes de pago

---

**¿Dudas?** Este documento explica TODO el flujo. Si algo no está claro, pregunta específicamente qué parte.
