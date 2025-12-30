# Configuración del Backend para Stripe

Este documento explica cómo configurar el endpoint necesario en el backend de Railway para que la integración de Stripe funcione correctamente.

## Requisitos

1. **API Keys de Stripe**: Ya tienes las keys de test
   - Publishable Key: `pk_test_51SMry82V350jFWI4oFI9WqATNGUFm9HtLhO76ZCye3KNZPZ54CjFoM1qJeOVAi02CF2xdEJuvhDC9lMuGyn4NNUz00ilGKdmzP`
   - Secret Key: `sk_test_51SMry82V350jFWI4tw7N8hCDElVwHyZWJL2XQjj7Z14kyMCQxQyu3M8a8GdDKLbYXX3TPWO3o0j5sOjGnClhugba00opIlTxPk`

2. **SDK de Stripe para el backend**: Instalar según el lenguaje que uses
   - Node.js: `npm install stripe`
   - Python: `pip install stripe`
   - Ruby: `gem install stripe`

## Endpoint Requerido

### URL
```
POST https://llegobackend-production.up.railway.app/create-payment-intent
```

### Request Body (JSON)
```json
{
  "amount": 4550,           // Monto en centavos (ej: 4550 = $45.50)
  "currency": "usd",        // Código de divisa en minúsculas
  "customer_id": "cus_xxx", // (Opcional) ID de customer existente
  "customer_email": "user@example.com", // (Opcional) Email para crear customer
  "metadata": {             // (Opcional) Metadatos personalizados
    "cart_items": "3",
    "subtotal": "43.00",
    "delivery_fee": "2.50"
  }
}
```

### Response (JSON)
```json
{
  "paymentIntent": "pi_xxxxx_secret_yyyyy", // Client secret del PaymentIntent
  "ephemeralKey": "ek_test_xxxxx",          // Secret de la Ephemeral Key
  "customer": "cus_xxxxx",                  // ID del Customer
  "publishableKey": "pk_test_xxxxx"         // Publishable key de Stripe
}
```

## Implementación del Endpoint

### Ejemplo en Node.js (Express)

```javascript
const express = require('express');
const stripe = require('stripe')('sk_test_51SMry82V350jFWI4tw7N8hCDElVwHyZWJL2XQjj7Z14kyMCQxQyu3M8a8GdDKLbYXX3TPWO3o0j5sOjGnClhugba00opIlTxPk');

const app = express();
app.use(express.json());

app.post('/create-payment-intent', async (req, res) => {
  try {
    const { amount, currency, customer_id, customer_email, metadata } = req.body;

    // 1. Crear o recuperar Customer
    let customerId = customer_id;
    if (!customerId && customer_email) {
      const customer = await stripe.customers.create({
        email: customer_email,
      });
      customerId = customer.id;
    }

    // 2. Crear Ephemeral Key para el Customer
    const ephemeralKey = await stripe.ephemeralKeys.create(
      { customer: customerId },
      { apiVersion: '2025-09-30.clover' }
    );

    // 3. Crear PaymentIntent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: currency,
      customer: customerId,
      automatic_payment_methods: {
        enabled: true,
      },
      metadata: metadata || {},
    });

    // 4. Devolver respuesta
    res.json({
      paymentIntent: paymentIntent.client_secret,
      ephemeralKey: ephemeralKey.secret,
      customer: customerId,
      publishableKey: 'pk_test_51SMry82V350jFWI4oFI9WqATNGUFm9HtLhO76ZCye3KNZPZ54CjFoM1qJeOVAi02CF2xdEJuvhDC9lMuGyn4NNUz00ilGKdmzP',
    });
  } catch (error) {
    console.error('Error creating payment intent:', error);
    res.status(500).json({ error: error.message });
  }
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

### Ejemplo en Python (Flask)

```python
from flask import Flask, request, jsonify
import stripe

app = Flask(__name__)
stripe.api_key = 'sk_test_51SMry82V350jFWI4tw7N8hCDElVwHyZWJL2XQjj7Z14kyMCQxQyu3M8a8GdDKLbYXX3TPWO3o0j5sOjGnClhugba00opIlTxPk'

@app.route('/create-payment-intent', methods=['POST'])
def create_payment_intent():
    try:
        data = request.json
        amount = data['amount']
        currency = data['currency']
        customer_id = data.get('customer_id')
        customer_email = data.get('customer_email')
        metadata = data.get('metadata', {})

        # 1. Crear o recuperar Customer
        if not customer_id and customer_email:
            customer = stripe.Customer.create(email=customer_email)
            customer_id = customer.id

        # 2. Crear Ephemeral Key
        ephemeral_key = stripe.EphemeralKey.create(
            customer=customer_id,
            stripe_version='2025-09-30.clover',
        )

        # 3. Crear PaymentIntent
        payment_intent = stripe.PaymentIntent.create(
            amount=amount,
            currency=currency,
            customer=customer_id,
            automatic_payment_methods={'enabled': True},
            metadata=metadata,
        )

        # 4. Devolver respuesta
        return jsonify({
            'paymentIntent': payment_intent.client_secret,
            'ephemeralKey': ephemeral_key.secret,
            'customer': customer_id,
            'publishableKey': 'pk_test_51SMry82V350jFWI4oFI9WqATNGUFm9HtLhO76ZCye3KNZPZ54CjFoM1qJeOVAi02CF2xdEJuvhDC9lMuGyn4NNUz00ilGKdmzP'
        })

    except Exception as e:
        return jsonify(error=str(e)), 500

if __name__ == '__main__':
    app.run(port=3000)
```

### Ejemplo en Ruby (Sinatra)

```ruby
require 'sinatra'
require 'stripe'
require 'json'

Stripe.api_key = 'sk_test_51SMry82V350jFWI4tw7N8hCDElVwHyZWJL2XQjj7Z14kyMCQxQyu3M8a8GdDKLbYXX3TPWO3o0j5sOjGnClhugba00opIlTxPk'

post '/create-payment-intent' do
  content_type :json

  begin
    data = JSON.parse(request.body.read)
    amount = data['amount']
    currency = data['currency']
    customer_id = data['customer_id']
    customer_email = data['customer_email']
    metadata = data['metadata'] || {}

    # 1. Crear o recuperar Customer
    unless customer_id
      customer = Stripe::Customer.create(email: customer_email)
      customer_id = customer.id
    end

    # 2. Crear Ephemeral Key
    ephemeral_key = Stripe::EphemeralKey.create(
      { customer: customer_id },
      { stripe_version: '2025-09-30.clover' }
    )

    # 3. Crear PaymentIntent
    payment_intent = Stripe::PaymentIntent.create(
      amount: amount,
      currency: currency,
      customer: customer_id,
      automatic_payment_methods: { enabled: true },
      metadata: metadata
    )

    # 4. Devolver respuesta
    {
      paymentIntent: payment_intent.client_secret,
      ephemeralKey: ephemeral_key.secret,
      customer: customer_id,
      publishableKey: 'pk_test_51SMry82V350jFWI4oFI9WqATNGUFm9HtLhO76ZCye3KNZPZ54CjFoM1qJeOVAi02CF2xdEJuvhDC9lMuGyn4NNUz00ilGKdmzP'
    }.to_json

  rescue => e
    status 500
    { error: e.message }.to_json
  end
end
```

## Webhooks (Opcional pero Recomendado)

Para manejar eventos posteriores al pago (confirmaciones, fallos, etc.), debes configurar webhooks:

### URL del Webhook
```
POST https://llegobackend-production.up.railway.app/stripe-webhook
```

### Eventos Importantes
- `payment_intent.succeeded` - Pago completado exitosamente
- `payment_intent.processing` - Pago en proceso
- `payment_intent.payment_failed` - Pago fallido

### Implementación del Webhook (Node.js)

```javascript
app.post('/stripe-webhook', express.raw({ type: 'application/json' }), (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = 'whsec_xxxxx'; // Tu webhook secret de Stripe

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
  } catch (err) {
    console.log(`Webhook signature verification failed: ${err.message}`);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Manejar el evento
  switch (event.type) {
    case 'payment_intent.succeeded':
      const paymentIntent = event.data.object;
      console.log(`PaymentIntent ${paymentIntent.id} succeeded!`);
      // TODO: Confirmar pedido en la base de datos
      break;

    case 'payment_intent.processing':
      console.log('Payment processing...');
      break;

    case 'payment_intent.payment_failed':
      console.log('Payment failed!');
      // TODO: Notificar al usuario del fallo
      break;

    default:
      console.log(`Unhandled event type ${event.type}`);
  }

  res.json({ received: true });
});
```

## Configurar Webhooks en Stripe Dashboard

1. Ve a https://dashboard.stripe.com/test/webhooks
2. Click en "Add endpoint"
3. URL: `https://llegobackend-production.up.railway.app/stripe-webhook`
4. Selecciona eventos: `payment_intent.succeeded`, `payment_intent.processing`, `payment_intent.payment_failed`
5. Copia el "Signing secret" (comienza con `whsec_`)

## Variables de Entorno Recomendadas

```bash
STRIPE_SECRET_KEY=sk_test_51SMry82V350jFWI4tw7N8hCDElVwHyZWJL2XQjj7Z14kyMCQxQyu3M8a8GdDKLbYXX3TPWO3o0j5sOjGnClhugba00opIlTxPk
STRIPE_PUBLISHABLE_KEY=pk_test_51SMry82V350jFWI4oFI9WqATNGUFm9HtLhO76ZCye3KNZPZ54CjFoM1qJeOVAi02CF2xdEJuvhDC9lMuGyn4NNUz00ilGKdmzP
STRIPE_WEBHOOK_SECRET=whsec_xxxxx
```

## Testing del Endpoint

### Usando curl

```bash
curl -X POST https://llegobackend-production.up.railway.app/create-payment-intent \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 4550,
    "currency": "usd",
    "customer_email": "test@example.com",
    "metadata": {
      "cart_items": "3",
      "subtotal": "43.00",
      "delivery_fee": "2.50"
    }
  }'
```

### Respuesta Esperada

```json
{
  "paymentIntent": "pi_3Xxxxx_secret_Yyyyyy",
  "ephemeralKey": "ek_test_Zzzzzz",
  "customer": "cus_Aaaaaa",
  "publishableKey": "pk_test_51SMry82V350jFWI4oFI9WqATNGUFm9HtLhO76ZCye3KNZPZ54CjFoM1qJeOVAi02CF2xdEJuvhDC9lMuGyn4NNUz00ilGKdmzP"
}
```

## Seguridad

1. **NUNCA** expongas la Secret Key en el cliente iOS
2. **SIEMPRE** valida los parámetros del request en el backend
3. **SIEMPRE** verifica la firma de los webhooks con `stripe.webhooks.constructEvent()`
4. Usa HTTPS para todas las comunicaciones
5. Implementa rate limiting en el endpoint
6. Valida que los montos sean razonables (ej: máximo $10,000)

## Para Producción

Cuando estés listo para producción:

1. Reemplaza las test keys con las live keys:
   - Live Secret Key: `sk_live_xxxxx`
   - Live Publishable Key: `pk_live_xxxxx`

2. Actualiza `StripeConfig.swift` en iOS:
   ```swift
   static let publishableKey = "pk_live_xxxxx"
   ```

3. Actualiza las variables de entorno en Railway

4. Configura webhooks de producción en Stripe Dashboard

## Recursos

- [Stripe API Reference](https://stripe.com/docs/api)
- [Stripe iOS SDK](https://stripe.com/docs/mobile/ios)
- [Stripe Testing](https://stripe.com/docs/testing)
- [Stripe Webhooks](https://stripe.com/docs/webhooks)

---

**Última actualización**: Octubre 2024
