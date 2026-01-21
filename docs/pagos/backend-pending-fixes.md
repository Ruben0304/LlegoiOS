# Ajustes Pendientes en Backend - Sistema de Pagos

## ✅ Flujo de Pago Confirmado

**TU FLUJO (Correcto):**
```
1. Cliente crea orden → PENDING_ACCEPTANCE
2. Negocio acepta/modifica → ACCEPTED
3. 🔵 BLOQUEO: Cliente DEBE pagar antes de continuar
4. Cliente paga exitosamente → Orden continúa a PREPARING
5. Si no paga → Orden se queda bloqueada en ACCEPTED
```

**Excepciones:**
- **Efectivo:** No requiere pago previo, se paga al entregar
- **Transferencias:** Cliente sube comprobante, negocio confirma, luego continúa

## 🔴 Ajustes Críticos (30 minutos)

### 1. Actualizar Estados Pagables

**Archivo:** `payments/service.py` (línea ~149)

**Cambiar de:**
```python
payable_statuses = ["pending_payment", "pending_acceptance", "modified_by_store"]
```

**A:**
```python
# Solo permitir pago después de que negocio acepte
payable_statuses = ["accepted", "modified_by_store"]
```

**¿Por qué?** Para que el cliente solo pueda pagar DESPUÉS de que el negocio acepte la orden.

### 2. Verificar Campos en Order

**Archivo:** `orders/models.py`

**Verificar que la clase Order tenga estos campos:**

```python
class Order(BaseModel):
    # ... campos existentes ...
    
    # VERIFICAR QUE EXISTAN:
    currentPaymentAttemptId: Optional[str] = None  # ID del pago activo
    paidAt: Optional[datetime] = None  # Cuándo se completó el pago
```

Si no existen, agregarlos.

### 3. Actualizar OrderType en GraphQL

**Archivo:** `schema/orders/types.py`

**Verificar que OrderType incluya:**

```python
@strawberry.type
class OrderType:
    # ... campos existentes ...
    
    # VERIFICAR QUE EXISTAN:
    currentPaymentAttemptId: Optional[str] = strawberry.field(
        description="ID del intento de pago activo"
    )
    paidAt: Optional[datetime] = strawberry.field(
        description="Cuándo se completó el pago"
    )
```

### 4. Agregar Validación de Pago Antes de PREPARING

**Archivo:** `orders/service.py` o donde manejes cambios de estado

**Agregar validación:**

```python
async def update_order_status(self, order_id: str, new_status: str, user_id: str):
    """Update order status with validations."""
    
    order = await self.orders_repo.get_by_id(order_id)
    
    # ... validaciones existentes ...
    
    # AGREGAR ESTA VALIDACIÓN:
    # Si intenta pasar a PREPARING, verificar que esté pagado
    if new_status == OrderStatus.PREPARING.value:
        # Excepto efectivo, que se paga al entregar
        payment_method = order.get("paymentMethod", "").lower()
        
        if payment_method not in ["cash", "efectivo"]:
            # Verificar que haya un pago completado
            if order.get("paymentStatus") != PaymentStatus.COMPLETED.value:
                raise ValueError(
                    "El pedido debe estar pagado antes de prepararse. "
                    "El cliente debe completar el pago primero."
                )
    
    # ... resto del código ...
```

**¿Por qué?** Para evitar que el negocio marque como "preparando" si el cliente no ha pagado.

## 🟡 Ajustes Importantes (1-2 horas)

### 5. Actualizar Transiciones de Estado

**Archivo:** `orders/models.py` (al final)

**Agregar validación de que desde ACCEPTED solo puede ir a PREPARING si está pagado:**

```python
# Al final del archivo

ALLOWED_TRANSITIONS: Dict[str, List[str]] = {
    OrderStatus.PENDING_ACCEPTANCE.value: [
        OrderStatus.ACCEPTED.value,
        OrderStatus.MODIFIED_BY_STORE.value,
        OrderStatus.CANCELLED.value,
    ],
    OrderStatus.MODIFIED_BY_STORE.value: [
        OrderStatus.ACCEPTED.value,
        OrderStatus.CANCELLED.value,
    ],
    OrderStatus.ACCEPTED.value: [
        OrderStatus.PREPARING.value,  # Solo si está pagado (validar en service)
        OrderStatus.CANCELLED.value,
    ],
    # ... resto igual ...
}
```

**Nota:** La validación real de pago se hace en el service (punto 4), esto solo define las rutas posibles.

### 6. Notificación al Cliente para Pagar

**Archivo:** `orders/service.py`

**Cuando el negocio acepta, notificar al cliente:**

```python
async def accept_order(self, order_id: str, business_user_id: str):
    """Business accepts an order."""
    
    # ... código existente de aceptación ...
    
    # Después de aceptar:
    order = await self.orders_repo.update_status(
        order_id,
        OrderStatus.ACCEPTED,
        business_user_id
    )
    
    # AGREGAR: Notificar al cliente que debe pagar
    payment_method = order.get("paymentMethod", "").lower()
    
    if payment_method not in ["cash", "efectivo"]:
        # Enviar notificación push
        from services.push_notification_service import send_push_notification
        
        await send_push_notification(
            user_id=order.get("customerId"),
            title="¡Pedido aceptado!",
            body=f"Tu pedido #{order.get('orderNumber')} fue aceptado. Por favor completa el pago.",
            data={
                "type": "order_accepted_payment_required",
                "order_id": order_id,
                "order_number": order.get("orderNumber")
            }
        )
    
    return order
```

### 7. Background Job para Expiración de Pagos

**Crear archivo:** `scripts/expire_payments_job.py`

```python
"""
Background job to expire old payment attempts.
Run this with a cron job every 5-10 minutes.
"""
import asyncio
import logging
from datetime import datetime

from payments import payment_service

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def expire_payments():
    """Expire old payment attempts."""
    try:
        logger.info(f"Starting payment expiration job at {datetime.utcnow()}")
        
        count = await payment_service.expire_payments()
        
        logger.info(f"Expired {count} payment attempts")
        
    except Exception as e:
        logger.error(f"Error in expiration job: {e}")


if __name__ == "__main__":
    asyncio.run(expire_payments())
```

**Configurar en main.py con APScheduler:**

```python
# En main.py

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from payments import payment_service

scheduler = AsyncIOScheduler()

@app.on_event("startup")
async def startup_event():
    # ... código existente ...
    
    # Agregar job de expiración cada 10 minutos
    scheduler.add_job(
        payment_service.expire_payments,
        'interval',
        minutes=10,
        id='expire_payments',
        replace_existing=True
    )
    scheduler.start()
    logger.info("Payment expiration job scheduled")

@app.on_event("shutdown")
async def shutdown_event():
    scheduler.shutdown()
```

**Instalar dependencia:**
```bash
pip install apscheduler
```

### 8. Timeout para Órdenes sin Pagar

**Opcional pero recomendado:**

Si el cliente no paga después de X tiempo de que el negocio acepte, cancelar automáticamente.

```python
# En scripts/expire_payments_job.py, agregar:

async def cancel_unpaid_orders():
    """Cancel orders that are accepted but not paid after 30 minutes."""
    from datetime import timedelta
    from clients.mongodb_client import get_database
    
    db = get_database()
    cutoff_time = datetime.utcnow() - timedelta(minutes=30)
    
    # Buscar órdenes aceptadas hace más de 30 min sin pago
    unpaid_orders = await db.orders.find({
        "status": "accepted",
        "paymentStatus": {"$ne": "completed"},
        "paymentMethod": {"$nin": ["cash", "efectivo"]},
        "lastStatusAt": {"$lte": cutoff_time}
    }).to_list(None)
    
    for order in unpaid_orders:
        # Cancelar orden
        await db.orders.update_one(
            {"_id": order["_id"]},
            {
                "$set": {
                    "status": "cancelled",
                    "updatedAt": datetime.utcnow(),
                    "cancellationReason": "Pago no completado en 30 minutos"
                }
            }
        )
        
        # Notificar cliente
        logger.info(f"Cancelled unpaid order: {order['orderNumber']}")
    
    return len(unpaid_orders)


# En main.py, agregar otro job:
scheduler.add_job(
    cancel_unpaid_orders,
    'interval',
    minutes=5,
    id='cancel_unpaid_orders',
    replace_existing=True
)
```

## 🟢 Mejoras Opcionales

### 9. Dashboard para Negocio

Mostrar órdenes pendientes de pago:

```graphql
query GetOrdersPendingPayment($branchId: String!, $jwt: String!) {
  ordersByBranch(branchId: $branchId, jwt: $jwt) {
    id
    orderNumber
    status
    paymentStatus
    currentPaymentAttemptId
    total
    createdAt
    lastStatusAt
  }
}
```

Filtrar en frontend las que están en `ACCEPTED` pero sin `paymentStatus: completed`.

### 10. Recordatorios Automáticos

Enviar recordatorio al cliente si no paga en 10 minutos:

```python
# En el job de expiración, agregar:

async def send_payment_reminders():
    """Send reminders for unpaid orders."""
    from datetime import timedelta
    from clients.mongodb_client import get_database
    
    db = get_database()
    reminder_time = datetime.utcnow() - timedelta(minutes=10)
    
    orders_to_remind = await db.orders.find({
        "status": "accepted",
        "paymentStatus": {"$ne": "completed"},
        "paymentMethod": {"$nin": ["cash", "efectivo"]},
        "lastStatusAt": {"$lte": reminder_time},
        "paymentReminderSent": {"$ne": True}  # No enviar duplicados
    }).to_list(None)
    
    for order in orders_to_remind:
        # Enviar notificación
        await send_push_notification(
            user_id=order["customerId"],
            title="⏰ Recordatorio de pago",
            body=f"Tu pedido #{order['orderNumber']} está esperando el pago",
            data={"type": "payment_reminder", "order_id": str(order["_id"])}
        )
        
        # Marcar como enviado
        await db.orders.update_one(
            {"_id": order["_id"]},
            {"$set": {"paymentReminderSent": True}}
        )
```

## 📋 Checklist de Implementación

### Críticos (Hacer HOY)
- [ ] ✅ Ejecutar migración: `python scripts/migrate_payment_methods.py`
- [ ] 🔴 Cambiar `payable_statuses` a `["accepted", "modified_by_store"]`
- [ ] 🔴 Verificar campos `currentPaymentAttemptId` y `paidAt` en Order
- [ ] 🔴 Verificar OrderType incluye esos campos en GraphQL
- [ ] 🔴 Agregar validación de pago antes de PREPARING

### Importantes (Esta semana)
- [ ] 🟡 Agregar notificación cuando negocio acepta
- [ ] 🟡 Implementar background job de expiración
- [ ] 🟡 Implementar timeout de órdenes sin pagar (30 min)
- [ ] 🟡 Configurar variables de entorno de Stripe

### Opcionales (Después)
- [ ] 🟢 Recordatorios automáticos (10 min)
- [ ] 🟢 Dashboard de órdenes pendientes de pago
- [ ] 🟢 Analytics de conversión de pago

## 🧪 Testing

### Flujo Completo a Probar

1. **Crear orden:**
   ```graphql
   mutation {
     createOrder(input: {...}) {
       id
       orderNumber
       status  # Debe ser "pending_acceptance"
       paymentStatus  # Debe ser "pending"
     }
   }
   ```

2. **Negocio acepta:**
   ```graphql
   mutation {
     acceptOrder(orderId: "...", jwt: "...") {
       id
       status  # Debe ser "accepted"
       # Cliente recibe notificación para pagar
     }
   }
   ```

3. **Cliente intenta pagar antes de aceptación (debe fallar):**
   ```graphql
   mutation {
     initiatePayment(orderId: "...", paymentMethodId: "...", jwt: "...") {
       # Error: "El pedido no está en un estado que permita pago"
     }
   }
   ```

4. **Cliente paga después de aceptación (debe funcionar):**
   ```graphql
   mutation {
     initiatePayment(orderId: "...", paymentMethodId: "wallet_usd", jwt: "...") {
       paymentAttempt {
         id
         status  # "completed" si wallet tiene saldo
       }
     }
   }
   ```

5. **Verificar orden actualizada:**
   ```graphql
   query {
     order(id: "...", jwt: "...") {
       paymentStatus  # Debe ser "completed"
       currentPaymentAttemptId  # Debe tener ID
       paidAt  # Debe tener timestamp
     }
   }
   ```

6. **Negocio intenta marcar como preparando sin pago (debe fallar):**
   ```graphql
   mutation {
     updateOrderStatus(orderId: "...", status: "preparing", jwt: "...") {
       # Error: "El pedido debe estar pagado antes de prepararse"
     }
   }
   ```

7. **Negocio marca como preparando con pago (debe funcionar):**
   ```graphql
   mutation {
     updateOrderStatus(orderId: "...", status: "preparing", jwt: "...") {
       status  # "preparing"
     }
   }
   ```

## 🎯 Resumen Ejecutivo

### Lo que tienes que hacer AHORA (30 min):

1. Ejecutar: `python scripts/migrate_payment_methods.py`
2. Cambiar línea 149 en `payments/service.py`:
   ```python
   payable_statuses = ["accepted", "modified_by_store"]
   ```
3. Verificar que Order tenga `currentPaymentAttemptId` y `paidAt`
4. Agregar validación en cambio de estado a PREPARING

### Después de eso:

✅ **El sistema está listo para el frontend**

El flujo será:
1. Cliente crea orden
2. Negocio acepta
3. Cliente recibe notificación "Debes pagar"
4. Cliente paga (Wallet/Stripe/Transferencia/Efectivo)
5. Negocio puede continuar preparando

---

**Última actualización:** Enero 2026  
**Versión:** 2.0 (Ajustado al flujo correcto)
