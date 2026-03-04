# Cambios en AI Chat para Frontend - Guía de Migración

## 📝 Resumen Ejecutivo

Se agregaron **dos mejoras** a la API de AI Chat:

1. **Manejo de errores robusto**: Ahora todos los errores vienen en un formato estructurado con códigos específicos
2. **Modo streaming (opcional)**: Nueva GraphQL subscription para respuestas en tiempo real

**⚠️ IMPORTANTE**: El modo legacy (sin streaming) sigue funcionando igual. Los cambios son **opt-in**.

---

## 🔄 Cambio en la Query Existente (aiChat)

### Antes (ya no funciona así)

```graphql
query {
  aiChat(input: { message: "pizza", deviceId: "abc" }, jwt: "...") {
    responseType
    aiText
    suggestedProducts {
      product { id name price }
      reason
    }
  }
}
```

**Problema**: Si había un error, retornaba `null` sin información.

### Ahora (nuevo formato)

```graphql
query {
  aiChat(input: { message: "pizza", deviceId: "abc" }, jwt: "...") {
    success {
      responseType
      aiText
      suggestedProducts {
        product { id name price }
        reason
      }
    }
    error {
      code
      message
      quota {
        limit
        used
        remaining
      }
      retryAfter
    }
  }
}
```

**Mejora**: Siempre recibes un resultado. Si hay error, viene en `error`. Si es exitoso, viene en `success`.

---

## ⚡ Nueva Subscription para Streaming

### ¿Qué es?

Una nueva forma de recibir la respuesta del AI **palabra por palabra** en tiempo real, como ChatGPT.

### ¿Cuándo usarla?

- ✅ Apps móviles (mejor UX)
- ✅ Interfaces web interactivas
- ❌ Integraciones simples (usar query normal)

### GraphQL Subscription

```graphql
subscription {
  aiChatStream(input: { message: "pizza", deviceId: "abc" }, jwt: "...") {
    delta              # Texto nuevo en este chunk
    accumulatedText    # Texto completo hasta ahora
    isFinal            # true si es el último chunk

    # Solo vienen en el chunk final:
    suggestedProducts {
      product { id name price image }
      reason
      branchName
      branchAvatarUrl
    }
    confidence

    # Si hay error:
    error {
      code
      message
    }
  }
}
```

---

## 💻 Implementación en Frontend

### Opción 1: Modo Query (Sin cambios, solo actualizar parsing)

**Apollo Client - React**

```typescript
import { gql, useQuery } from '@apollo/client';

const AI_CHAT = gql`
  query AiChat($input: AiAssistantChatInput!, $jwt: String!) {
    aiChat(input: $input, jwt: $jwt) {
      success {
        aiText
        suggestedProducts {
          product { id name price }
          reason
        }
      }
      error {
        code
        message
        quota { limit used remaining }
      }
    }
  }
`;

function ChatComponent() {
  const [message, setMessage] = useState('');
  const { data, loading, error } = useQuery(AI_CHAT, {
    variables: {
      input: { message, deviceId: getDeviceId() },
      jwt: getJWT()
    },
    skip: !message
  });

  // ⚠️ IMPORTANTE: Verificar error primero
  if (data?.aiChat?.error) {
    const { code, message, quota } = data.aiChat.error;

    if (code === 'AI_DAILY_DEVICE_QUOTA_EXCEEDED') {
      return <QuotaExceeded quota={quota} />;
    }

    return <ErrorMessage message={message} />;
  }

  // Si no hay error, mostrar respuesta
  const response = data?.aiChat?.success;

  return (
    <div>
      <p>{response?.aiText}</p>
      <ProductList products={response?.suggestedProducts} />
    </div>
  );
}
```

### Opción 2: Modo Streaming (Nuevo)

**Apollo Client - React**

```typescript
import { gql, useSubscription } from '@apollo/client';

const AI_CHAT_STREAM = gql`
  subscription AiChatStream($input: AiAssistantChatInput!, $jwt: String!) {
    aiChatStream(input: $input, jwt: $jwt) {
      delta
      accumulatedText
      isFinal
      suggestedProducts {
        product { id name price }
        reason
      }
      error { code message }
    }
  }
`;

function ChatStreamingComponent() {
  const [message, setMessage] = useState('');
  const [streamingText, setStreamingText] = useState('');
  const [products, setProducts] = useState([]);
  const [isStreaming, setIsStreaming] = useState(false);

  const { data } = useSubscription(AI_CHAT_STREAM, {
    variables: {
      input: { message, deviceId: getDeviceId() },
      jwt: getJWT()
    },
    skip: !isStreaming,
    onSubscriptionData: ({ subscriptionData }) => {
      const chunk = subscriptionData.data?.aiChatStream;

      // Manejar error
      if (chunk?.error) {
        showError(chunk.error.message);
        setIsStreaming(false);
        return;
      }

      // Actualizar texto en tiempo real
      setStreamingText(chunk.accumulatedText);

      // Si es el chunk final, procesar productos
      if (chunk.isFinal) {
        setProducts(chunk.suggestedProducts);
        setIsStreaming(false);
      }
    }
  });

  return (
    <div>
      <input
        onSubmit={(e) => {
          setMessage(e.target.value);
          setIsStreaming(true);
        }}
      />

      {/* Texto aparece palabra por palabra */}
      <div className="ai-message">
        {streamingText}
        {isStreaming && <span className="cursor">▋</span>}
      </div>

      {/* Productos aparecen al final */}
      {products.length > 0 && (
        <ProductList products={products} />
      )}
    </div>
  );
}
```

---

## 🚨 Códigos de Error a Manejar

| Código | ¿Qué hacer? |
|--------|-------------|
| `AI_MESSAGE_TOO_LONG` | Mostrar: "Mensaje muy largo. Max 30 palabras" |
| `AI_DEVICE_ID_REQUIRED` | Verificar que envías `deviceId` |
| `AI_DAILY_DEVICE_QUOTA_EXCEEDED` | Mostrar: "Límite diario alcanzado (5 consultas/día). Vuelve mañana." + mostrar `quota.remaining` |
| `AI_RATE_LIMIT_EXCEEDED` | Mostrar: "Espera un momento antes de enviar otro mensaje" |
| `AI_SERVICE_ERROR` | Mostrar: "Servicio temporalmente no disponible. Intenta de nuevo." |
| `AI_INVALID_REQUEST` | Verificar JWT y parámetros |

**Ejemplo de UI para quota excedida:**

```typescript
function QuotaExceededDialog({ quota }) {
  return (
    <Dialog>
      <h2>Límite diario alcanzado</h2>
      <p>Has usado {quota.used} de {quota.limit} consultas de IA hoy.</p>
      <p>Vuelve mañana para más consultas.</p>
      <ProgressBar value={quota.used} max={quota.limit} />
    </Dialog>
  );
}
```

---

## 📱 Setup de Apollo Client (si usas streaming)

**Necesitas configurar WebSocket Link**

```typescript
import { ApolloClient, InMemoryCache, HttpLink, split } from '@apollo/client';
import { GraphQLWsLink } from '@apollo/client/link/subscriptions';
import { getMainDefinition } from '@apollo/client/utilities';
import { createClient } from 'graphql-ws';

// HTTP Link para queries/mutations
const httpLink = new HttpLink({
  uri: 'https://tu-api.com/graphql'
});

// WebSocket Link para subscriptions
const wsLink = new GraphQLWsLink(createClient({
  url: 'wss://tu-api.com/graphql',
  connectionParams: {
    authToken: getJWT(),
  }
}));

// Split según el tipo de operación
const splitLink = split(
  ({ query }) => {
    const definition = getMainDefinition(query);
    return (
      definition.kind === 'OperationDefinition' &&
      definition.operation === 'subscription'
    );
  },
  wsLink,      // Usa WebSocket para subscriptions
  httpLink,    // Usa HTTP para queries/mutations
);

const client = new ApolloClient({
  link: splitLink,
  cache: new InMemoryCache()
});
```

---

## 🔑 deviceId: ¿Cómo obtenerlo?

**React Native:**
```typescript
import DeviceInfo from 'react-native-device-info';

const deviceId = DeviceInfo.getUniqueId();
```

**Web (persiste en localStorage):**
```typescript
function getDeviceId(): string {
  let deviceId = localStorage.getItem('llego_device_id');
  if (!deviceId) {
    deviceId = crypto.randomUUID();
    localStorage.setItem('llego_device_id', deviceId);
  }
  return deviceId;
}
```

---

## 🧪 Testing Rápido

### Con Postman/Insomnia (Query mode)

```graphql
query TestAiChat {
  aiChat(
    input: {
      message: "quiero pizza"
      deviceId: "test-device-123"
    }
    jwt: "tu-jwt-aqui"
  ) {
    success {
      aiText
      suggestedProducts {
        product { name price }
      }
    }
    error {
      code
      message
    }
  }
}
```

### Probar error de quota

Haz 6 requests seguidos con el mismo `deviceId` y `jwt`. La 6ta debe retornar:

```json
{
  "data": {
    "aiChat": {
      "success": null,
      "error": {
        "code": "AI_DAILY_DEVICE_QUOTA_EXCEEDED",
        "message": "Límite diario AI por usuario/dispositivo alcanzado",
        "quota": {
          "source": "temp_user_device_daily_limit",
          "limit": 5,
          "used": 5,
          "remaining": 0
        }
      }
    }
  }
}
```

---

## ✅ Checklist de Migración

### Para Query Mode (Mínimo necesario)

- [ ] Actualizar parsing de respuesta: `data.aiChat.success` en vez de `data.aiChat`
- [ ] Agregar manejo de `data.aiChat.error`
- [ ] Mostrar UI específica para `AI_DAILY_DEVICE_QUOTA_EXCEEDED`
- [ ] Validar que envías `deviceId` correctamente
- [ ] Testing con 6 requests (probar quota)

### Para Streaming Mode (Opcional)

- [ ] Instalar `graphql-ws`: `npm install graphql-ws`
- [ ] Configurar WebSocket link en Apollo Client
- [ ] Implementar `useSubscription` en lugar de `useQuery`
- [ ] Manejar chunks en `onSubscriptionData`
- [ ] Mostrar texto acumulado en tiempo real
- [ ] Procesar productos solo cuando `isFinal === true`
- [ ] Testing de conexión WebSocket

---

## 🆘 Problemas Comunes

### "Cannot read property 'aiText' of undefined"

**Causa**: Intentas acceder a `data.aiChat.aiText` directamente

**Solución**: Usa `data.aiChat.success.aiText`

### Subscription no recibe eventos

**Causa**: WebSocket no configurado o URL incorrecta

**Solución**:
1. Verifica que tienes `GraphQLWsLink` configurado
2. URL debe ser `wss://` (no `https://`)
3. Verifica que el servidor soporte WebSocket

### deviceId siempre da error "required"

**Causa**: No estás enviando deviceId en el input

**Solución**:
```typescript
// ❌ Mal
{ message: "pizza" }

// ✅ Bien
{ message: "pizza", deviceId: getDeviceId() }
```

---

## 📊 Comparación Visual

### Query Mode (Legacy mejorado)
```
Usuario: "pizza" → [Espera 2s] → Respuesta completa aparece
```

### Streaming Mode (Nuevo)
```
Usuario: "pizza"
  → "¡Encontré" (0.1s)
  → "varias pizzas" (0.2s)
  → "deliciosas para ti!" (0.5s)
  → [Productos] (2s)
```

**Ventaja**: Misma velocidad total, pero mejor percepción de usuario.

---

## 📞 Contacto

Si tienes dudas sobre la implementación:

1. Revisa la [documentación completa](./AI_CHAT_API.md)
2. Revisa el [schema GraphQL](../scripts/schema.graphql)
3. Busca ejemplos en este documento

---

**Fecha**: 2026-03-04
**Versión Backend**: Compatible desde hoy
**Breaking Changes**: ❌ Ninguno (backward compatible)
