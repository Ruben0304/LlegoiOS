# Configuración de Stripe en el Backend

## ⚠️ IMPORTANTE: La Secret Key va en el BACKEND

La Secret Key de Stripe **NUNCA** debe estar en el frontend (iOS). Solo la Publishable Key va en el cliente.

## Configuración en el Backend (Railway)

### 1. Variables de Entorno

Agrega estas variables en Railway:

```bash
STRIPE_SECRET_KEY=sk_test_tu_secret_key_aqui
STRIPE_PUBLISHABLE_KEY=pk_test_tu_publishable_key_aqui
```

**Para obtener tus keys:**
1. Ve a https://dashboard.stripe.com/apikeys
2. Copia la "Publishable key" (pk_test_...)
3. Copia la "Secret key" (sk_test_...)

### 2. Endpoint para crear Payment Intent

Crea este endpoint en tu backend:

```javascript
// POST /api/stripe/create-payment-intent
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

app.post('/api/stripe/create-payment-intent', async (req, res) => {
  try {
    // Verificar autenticación
    const token = req.headers.authorization?.replace('Bearer ', '');
    if (!token) {
      return res.status(401).json({ error: 'No autorizado' });
    }

    // Verificar JWT y obtener userId
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userId = decoded.userId;

    // Obtener datos del request
    const { amount, currency, description } = req.body;

    // Validar
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Monto inválido' });
    }

    // Crear Payment Intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount, // Ya viene en centavos desde el frontend
      currency: currency.toLowerCase(),
      description: description || 'Recarga Wallet',
      metadata: {
        userId: userId,
        type: 'wallet_recharge'
      },
      // Habilitar métodos de pago automáticos (incluye Apple Pay)
      automatic_payment_methods: {
        enabled: true,
      },
    });

    // Devolver el client secret
    res.json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id
    });

  } catch (error) {
    console.error('Error creando Payment Intent:', error);
    res.status(500).json({ error: error.message });
  }
});
```

### 3. Webhook para confirmar pagos (Opcional pero recomendado)

Stripe enviará webhooks cuando el pago se complete:

```javascript
// POST /api/stripe/webhook
const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET;

app.post('/api/stripe/webhook', express.raw({type: 'application/json'}), async (req, res) => {
  const sig = req.headers['stripe-signature'];

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, endpointSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Manejar el evento
  switch (event.type) {
    case 'payment_intent.succeeded':
      const paymentIntent = event.data.object;
      console.log('✅ Payment succeeded:', paymentIntent.id);
      
      // Aquí puedes actualizar el balance del usuario en la BD
      const userId = paymentIntent.metadata.userId;
      const amount = paymentIntent.amount / 100; // Convertir de centavos
      
      // TODO: Actualizar balance en la base de datos
      // await updateUserBalance(userId, amount);
      
      break;
      
    case 'payment_intent.payment_failed':
      const failedPayment = event.data.object;
      console.error('❌ Payment failed:', failedPayment.id);
      break;
      
    default:
      console.log(`Unhandled event type ${event.type}`);
  }

  res.json({received: true});
});
```

### 4. Configurar Webhook en Stripe Dashboard

1. Ve a https://dashboard.stripe.com/webhooks
2. Haz clic en "Add endpoint"
3. URL: `https://llegobackend-production.up.railway.app/api/stripe/webhook`
4. Selecciona estos eventos:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
5. Copia el "Signing secret" (whsec_...)
6. Agrégalo como variable de entorno: `STRIPE_WEBHOOK_SECRET`

## Flujo Completo

1. **Usuario en iOS**: Toca "Pagar con Tarjeta (Stripe)"
2. **iOS → Backend**: POST a `/api/stripe/create-payment-intent`
3. **Backend → Stripe**: Crea Payment Intent con la Secret Key
4. **Backend → iOS**: Devuelve el `clientSecret`
5. **iOS**: Muestra el Payment Sheet de Stripe
6. **Usuario**: Ingresa datos de tarjeta o usa Apple Pay
7. **Stripe**: Procesa el pago
8. **Stripe → Backend**: Envía webhook `payment_intent.succeeded`
9. **Backend**: Actualiza el balance del usuario
10. **iOS**: Muestra mensaje de éxito

## Testing

### Tarjetas de prueba de Stripe:

- **Éxito**: 4242 4242 4242 4242
- **Requiere autenticación**: 4000 0025 0000 3155
- **Declinada**: 4000 0000 0000 9995
- **Fondos insuficientes**: 4000 0000 0000 9995

Cualquier fecha futura y cualquier CVV de 3 dígitos.

## Seguridad

✅ **Correcto**:
- Secret Key en el backend (variables de entorno)
- Publishable Key en el frontend
- Validar JWT en el endpoint
- Verificar firma del webhook

❌ **Incorrecto**:
- Secret Key en el frontend
- Crear Payment Intents desde el cliente
- No validar autenticación
- No verificar webhooks

## Instalación de dependencias

```bash
npm install stripe
# o
yarn add stripe
```

## Variables de entorno completas

```bash
# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# JWT (ya deberías tenerlo)
JWT_SECRET=tu_jwt_secret
```

## Documentación

- [Stripe Payment Intents](https://stripe.com/docs/payments/payment-intents)
- [Stripe iOS SDK](https://stripe.com/docs/payments/accept-a-payment?platform=ios)
- [Stripe Webhooks](https://stripe.com/docs/webhooks)
- [Stripe Testing](https://stripe.com/docs/testing)
