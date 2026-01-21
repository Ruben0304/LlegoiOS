# Backend: Stripe Recharge Link - Especificaciones

## Objetivo
Crear un endpoint en FastAPI que genere un **Stripe Payment Link** personalizado para que usuarios externos (familiares, amigos) puedan recargar dinero a la wallet de un usuario de Llego desde el extranjero.

## Flujo Completo

```
1. Usuario de Llego → Presiona "Recarga Internacional" en la app
2. App iOS → POST /stripe/create-recharge-link (con JWT del usuario)
3. Backend → Crea Payment Link de Stripe con metadata del usuario
4. Backend → Retorna el Payment Link URL
5. Usuario comparte el link → Familiar/amigo abre el link
6. Familiar paga → Stripe procesa el pago
7. Stripe Webhook → Notifica al backend del pago exitoso
8. Backend → Acredita el dinero a la wallet del usuario
```

## Endpoint 1: Crear Payment Link

### Request
```http
POST /stripe/create-recharge-link
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "currency": "usd",
  "description": "Recarga internacional para Llego Wallet"
}
```

### Response (Success)
```json
{
  "payment_link": "https://buy.stripe.com/test_xxxxxxxxxxxxx",
  "link_id": "plink_xxxxxxxxxxxxx",
  "user_id": "user_id_from_jwt",
  "expires_at": "2024-12-31T23:59:59Z"
}
```

### Response (Error)
```json
{
  "detail": "Error message"
}
```

## Implementación Backend (FastAPI)

### 1. Crear el Payment Link

```python
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
import stripe
from datetime import datetime, timedelta

router = APIRouter(prefix="/stripe", tags=["stripe"])

class CreateRechargeLinkRequest(BaseModel):
    currency: str = "usd"
    description: str = "Recarga internacional para Llego Wallet"

@router.post("/create-recharge-link")
async def create_recharge_link(
    request: CreateRechargeLinkRequest,
    current_user = Depends(get_current_user)  # Tu función de autenticación JWT
):
    """
    Crea un Stripe Payment Link para que usuarios externos puedan recargar
    dinero a la wallet del usuario autenticado.
    
    El link permite al pagador elegir el monto y pagar con tarjeta internacional.
    """
    try:
        # Configurar Stripe
        stripe.api_key = settings.STRIPE_SECRET_KEY
        
        # Crear un Price dinámico (permite al usuario elegir el monto)
        # Nota: Stripe Payment Links requieren un Price, pero podemos usar
        # "custom_amount" para que el pagador elija el monto
        
        # Opción 1: Crear un producto y price específico para este usuario
        product = stripe.Product.create(
            name=f"Recarga Wallet - {current_user.name}",
            description=f"Recarga internacional para {current_user.email}",
            metadata={
                "user_id": str(current_user.id),
                "user_email": current_user.email,
                "type": "wallet_recharge"
            }
        )
        
        # Crear un price con monto ajustable
        price = stripe.Price.create(
            product=product.id,
            currency=request.currency.lower(),
            unit_amount=1000,  # $10 USD como sugerencia (en centavos)
            custom_unit_amount={
                "enabled": True,
                "minimum": 500,  # Mínimo $5 USD
                "maximum": 100000,  # Máximo $1000 USD
                "preset": 2000  # Sugerencia $20 USD
            }
        )
        
        # Crear el Payment Link
        payment_link = stripe.PaymentLink.create(
            line_items=[{
                "price": price.id,
                "quantity": 1,
                "adjustable_quantity": {
                    "enabled": False  # No permitir cambiar cantidad, solo monto
                }
            }],
            after_completion={
                "type": "hosted_confirmation",
                "hosted_confirmation": {
                    "custom_message": f"¡Gracias! El dinero ha sido enviado a {current_user.name} exitosamente."
                }
            },
            allow_promotion_codes=False,
            billing_address_collection="auto",
            shipping_address_collection=None,
            phone_number_collection={
                "enabled": False
            },
            metadata={
                "user_id": str(current_user.id),
                "user_email": current_user.email,
                "username": current_user.username,
                "type": "wallet_recharge",
                "created_at": datetime.utcnow().isoformat()
            }
        )
        
        # Guardar el link en la base de datos (opcional pero recomendado)
        # para tracking y seguridad
        await save_payment_link_to_db(
            user_id=current_user.id,
            link_id=payment_link.id,
            url=payment_link.url,
            product_id=product.id,
            price_id=price.id
        )
        
        return {
            "payment_link": payment_link.url,
            "link_id": payment_link.id,
            "user_id": str(current_user.id),
            "expires_at": None  # Payment Links no expiran por defecto
        }
        
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=f"Error de Stripe: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")
```

### 2. Webhook para Procesar Pagos

```python
@router.post("/webhook")
async def stripe_webhook(request: Request):
    """
    Webhook de Stripe para procesar eventos de pago.
    
    Eventos importantes:
    - checkout.session.completed: Pago completado
    - payment_intent.succeeded: Pago exitoso
    """
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature")
    
    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, settings.STRIPE_WEBHOOK_SECRET
        )
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid payload")
    except stripe.error.SignatureVerificationError:
        raise HTTPException(status_code=400, detail="Invalid signature")
    
    # Manejar el evento
    if event["type"] == "checkout.session.completed":
        session = event["data"]["object"]
        await handle_successful_payment(session)
    
    elif event["type"] == "payment_intent.succeeded":
        payment_intent = event["data"]["object"]
        # Procesar pago exitoso si es necesario
        pass
    
    return {"status": "success"}

async def handle_successful_payment(session):
    """
    Procesa un pago exitoso y acredita el dinero a la wallet del usuario.
    """
    try:
        # Obtener metadata del payment link
        metadata = session.get("metadata", {})
        user_id = metadata.get("user_id")
        
        if not user_id:
            print("⚠️ No user_id en metadata del pago")
            return
        
        # Obtener el monto pagado (en centavos)
        amount_total = session.get("amount_total", 0)
        currency = session.get("currency", "usd")
        
        # Convertir de centavos a dólares
        amount = amount_total / 100
        
        # Acreditar a la wallet del usuario
        await deposit_to_wallet(
            user_id=user_id,
            amount=amount,
            currency=currency,
            source="stripe_payment_link",
            description=f"Recarga internacional via Stripe",
            transaction_id=session.get("payment_intent")
        )
        
        print(f"✅ Recarga exitosa: ${amount} {currency.upper()} para user {user_id}")
        
        # Opcional: Enviar notificación push al usuario
        await send_push_notification(
            user_id=user_id,
            title="¡Recarga recibida!",
            body=f"Has recibido ${amount:.2f} {currency.upper()} en tu Wallet"
        )
        
    except Exception as e:
        print(f"❌ Error procesando pago: {str(e)}")
        # Aquí podrías guardar en una tabla de errores para retry manual
```

### 3. Función Helper para Depositar en Wallet

```python
async def deposit_to_wallet(
    user_id: str,
    amount: float,
    currency: str,
    source: str,
    description: str,
    transaction_id: str = None
):
    """
    Acredita dinero a la wallet del usuario.
    Usa tu lógica existente de wallet/transactions.
    """
    # Obtener el usuario
    user = await get_user_by_id(user_id)
    if not user:
        raise Exception(f"Usuario {user_id} no encontrado")
    
    # Crear transacción
    transaction = await create_wallet_transaction(
        to_owner_id=user_id,
        to_owner_type="user",
        amount=amount,
        currency=currency,
        type="deposit",
        status="completed",
        description=description,
        metadata={
            "source": source,
            "stripe_transaction_id": transaction_id
        }
    )
    
    # Actualizar balance de la wallet
    if currency == "usd":
        user.wallet_usd += amount
    else:
        user.wallet_local += amount
    
    await user.save()
    
    return transaction
```

## Configuración Necesaria

### 1. Variables de Entorno
```env
STRIPE_SECRET_KEY=sk_test_xxxxxxxxxxxxx
STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxx
```

### 2. Configurar Webhook en Stripe Dashboard

1. Ir a: https://dashboard.stripe.com/webhooks
2. Crear nuevo endpoint: `https://tu-backend.com/stripe/webhook`
3. Seleccionar eventos:
   - `checkout.session.completed`
   - `payment_intent.succeeded`
4. Copiar el "Signing secret" y agregarlo a `.env`

### 3. Tabla de Base de Datos (Opcional)

```python
class StripePaymentLink(Base):
    __tablename__ = "stripe_payment_links"
    
    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    link_id = Column(String, unique=True, nullable=False)  # Stripe link ID
    url = Column(String, nullable=False)
    product_id = Column(String)
    price_id = Column(String)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    last_used_at = Column(DateTime, nullable=True)
    total_received = Column(Float, default=0.0)
    usage_count = Column(Integer, default=0)
```

## Testing

### 1. Crear Link (desde la app)
```bash
curl -X POST https://tu-backend.com/stripe/create-recharge-link \
  -H "Authorization: Bearer {jwt_token}" \
  -H "Content-Type: application/json" \
  -d '{"currency": "usd"}'
```

### 2. Probar Pago
1. Abrir el link generado en un navegador
2. Usar tarjeta de prueba de Stripe: `4242 4242 4242 4242`
3. Fecha: Cualquier fecha futura
4. CVC: Cualquier 3 dígitos
5. Completar el pago

### 3. Verificar Webhook
```bash
stripe listen --forward-to localhost:8000/stripe/webhook
```

## Notas Importantes

1. **Seguridad**: El link es público pero solo el usuario autenticado puede generarlo
2. **Montos**: Configurar mínimos y máximos según tus necesidades
3. **Comisiones**: Stripe cobra ~2.9% + $0.30 por transacción internacional
4. **Monedas**: Soporta USD, EUR, y otras monedas de Stripe
5. **Expiración**: Los Payment Links no expiran por defecto, pero puedes desactivarlos
6. **Tracking**: Guarda los links en BD para analytics y seguridad

## Ventajas de Payment Links vs Payment Intents

- ✅ No requiere frontend personalizado
- ✅ Stripe maneja toda la UI de pago
- ✅ Soporta múltiples métodos de pago
- ✅ El pagador elige el monto
- ✅ Funciona en cualquier dispositivo/navegador
- ✅ Stripe maneja 3D Secure automáticamente
- ✅ Página de confirmación personalizable

## Próximos Pasos

1. Implementar el endpoint `/stripe/create-recharge-link`
2. Configurar el webhook `/stripe/webhook`
3. Probar con tarjetas de prueba de Stripe
4. Configurar el webhook en producción
5. Opcional: Agregar analytics de uso de links
