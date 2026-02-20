# 📦 Feature: Instrucciones de Entrega + Direcciones Guardadas

> **Fecha:** 2026-02-20  
> **Backend:** LlegoBackend  
> **Estado:** ✅ Implementado y disponible en la API GraphQL

---

## ¿Qué se implementó?

### 1. Instrucciones de entrega en el pedido (al estilo Uber Eats / Glovo)
Se extendió el campo `deliveryAddress` del pedido para soportar información estructurada:
- **Tipo de dirección** → Casa, Apartamento/Edificio, Oficina u Otro
- **Nombre del edificio/conjunto** → ej. "Edificio Habana Center"
- **Piso** → ej. "3", "PB"
- **Número de apartamento** → ej. "3B"
- **Instrucciones libres** → ej. "Tocar timbre 2 veces", "Dejar en portería"

### 2. Direcciones guardadas en el perfil del usuario
El usuario puede guardar múltiples direcciones en su perfil (como en Uber Eats) con un label tipo "Casa", "Trabajo", etc. y marcar una como **predeterminada**. Al hacer un pedido, el frontend puede pre-rellenar la dirección con la guardada por defecto, permitiendo cambiarla en ese momento si está en otro lugar.

---

## Archivos modificados

| Archivo | Cambio |
|---|---|
| `domain/orders.py` | Nuevo enum `AddressType` + 5 campos opcionales en `DeliveryAddress` |
| `schema/orders/inputs.py` | Nuevo enum `AddressTypeInput` + campos en `DeliveryAddressInput` |
| `schema/orders/types.py` | Nuevo enum `AddressTypeEnum` + campos en `DeliveryAddressType` |
| `schema/orders/mutations.py` | Se pasan los nuevos campos en `createOrder` |
| `services/orders_service.py` | Se construye `DeliveryAddress` con los nuevos campos |

---

## GraphQL: Mutation `createOrder`

### Input: `DeliveryAddressInput` (campos nuevos)

```graphql
enum AddressTypeInput {
  HOUSE       # Casa
  APARTMENT   # Apartamento / Edificio
  OFFICE      # Oficina
  OTHER       # Otro
}

input DeliveryAddressInput {
  # Campos existentes (sin cambios)
  street: String!
  latitude: Float!
  longitude: Float!
  city: String
  reference: String

  # Campos NUEVOS (todos opcionales, con defaults seguros)
  addressType: AddressTypeInput  # default: HOUSE
  buildingName: String           # Nombre del edificio o conjunto
  floor: String                  # Piso (ej: "3", "PB")
  apartment: String              # Número de apartamento (ej: "3B")
  deliveryInstructions: String   # Texto libre de instrucciones
}
```

### Ejemplo de uso completo

```graphql
mutation CreateOrder($input: CreateOrderInput!, $jwt: String!) {
  createOrder(input: $input, jwt: $jwt) {
    id
    orderNumber
    deliveryAddress {
      street
      addressType
      buildingName
      floor
      apartment
      deliveryInstructions
      coordinates {
        coordinates
      }
    }
  }
}
```

**Variables:**
```json
{
  "input": {
    "branchId": "abc123",
    "items": [{ "productId": "prod1", "quantity": 2 }],
    "paymentMethod": "cash",
    "deliveryAddress": {
      "street": "Calle 23 entre L y M",
      "latitude": 23.1364,
      "longitude": -82.3666,
      "city": "La Habana",
      "addressType": "APARTMENT",
      "buildingName": "Edificio Habana Center",
      "floor": "5",
      "apartment": "5B",
      "deliveryInstructions": "Tocar timbre 2 veces. No funciona el ascensor."
    }
  },
  "jwt": "..."
}
```

---

## GraphQL: Query / Type `deliveryAddress`

En cualquier query que devuelva un `OrderType`, el campo `deliveryAddress` ahora tiene los campos nuevos disponibles:

```graphql
type DeliveryAddressType {
  street: String!
  city: String
  reference: String
  coordinates: CoordinatesType!

  # Campos NUEVOS
  addressType: AddressTypeEnum!         # HOUSE | APARTMENT | OFFICE | OTHER
  buildingName: String                  # null si no aplica
  floor: String                         # null si no aplica
  apartment: String                     # null si no aplica
  deliveryInstructions: String          # null si el cliente no dejó instrucciones
}
```

---

## Comportamiento importante

### ✅ Retrocompatibilidad total
- Los pedidos **ya existentes en MongoDB** (sin estos campos) seguirán funcionando sin error.  
  El backend usa `addressType = "house"` como default y `None` para el resto.
- Todos los campos nuevos son **opcionales** tanto en el input como en el modelo.

### ✅ Enum values (case sensitive en la API)
Enviar el valor en mayúsculas como indica el enum:

| Valor API | Descripción |
|---|---|
| `HOUSE` | Casa unifamiliar |
| `APARTMENT` | Apartamento o edificio |
| `OFFICE` | Oficina |
| `OTHER` | Otro tipo de lugar |

---

## Recomendaciones UX para el frontend (al estilo Glovo/Uber Eats)

```
Paso: Confirmar dirección de entrega
────────────────────────────────
[📍 Calle 23 entre L y M, La Habana]

Tipo de lugar:
  🏠 Casa     🏢 Edificio     🏢 Oficina     📍 Otro
  [seleccionado: Edificio]

Si es Edificio/Oficina:
  Nombre del edificio: [Habana Center        ]
  Piso:                [5                    ]
  Apartamento/Oficina: [5B                   ]

Instrucciones para el repartidor (opcional):
  [Tocar timbre 2 veces. No funciona el ascensor.]
  💡 Ej: Tocar timbre, Dejar en portería, Código de acceso...
────────────────────────────────
     [Confirmar dirección →]
```

### Lógica sugerida (condicional)
- Mostrar `buildingName`, `floor`, `apartment` **solo si** `addressType === "APARTMENT"` o `"OFFICE"`
- El campo `deliveryInstructions` mostrarlo **siempre** como texto libre opcional
- Placeholder sugerido: `"Ej: Tocar timbre 2 veces, dejar con el portero..."`

---

## Campos visibles para el repartidor

En la pantalla de entrega del repartidor, se recomienda mostrar claramente:

```
📍 Calle 23 entre L y M
🏢 Edificio Habana Center · Piso 5 · Apto 5B
💬 "Tocar timbre 2 veces. No funciona el ascensor."
```

---

## Preguntas / Contacto

Cualquier duda sobre la implementación, consultar con el equipo backend.

---

## Parte 2: Direcciones Guardadas en el Perfil

### Archivos modificados (adicionales)

| Archivo | Cambio |
|---|---|
| `domain/models.py` | Nuevo modelo `SavedAddress` + campos `savedAddresses` / `defaultAddressId` en `User` |
| `repositories/user_repository.py` | 4 nuevos métodos: `add_saved_address`, `remove_saved_address`, `update_saved_address`, `set_default_address` |
| `schema/users/types.py` | Nuevo tipo `SavedAddressType` + campos en `UserType` |
| `schema/users/inputs.py` | Nuevos inputs `SavedAddressInput` y `UpdateSavedAddressInput` |
| `schema/users/mutations.py` | 4 nuevas mutaciones de gestión de direcciones |

---

### GraphQL: Tipo `SavedAddressType`

```graphql
type SavedAddressType {
  id: String!              # UUID autogenerado por el backend
  label: String!           # Alias del usuario (ej: "Casa", "Trabajo")
  street: String!
  city: String
  reference: String
  addressType: String!     # "house" | "apartment" | "office" | "other"
  buildingName: String
  floor: String
  apartment: String
  deliveryInstructions: String
  latitude: Float!
  longitude: Float!
}
```

El campo `savedAddresses` y `defaultAddressId` ahora están disponibles en `UserType`:

```graphql
type UserType {
  # ... campos existentes ...
  savedAddresses: [SavedAddressType!]!
  defaultAddressId: String   # null si no hay default
}
```

---

### GraphQL: Mutations de Saved Addresses

#### `addSavedAddress` — Guardar nueva dirección

```graphql
mutation AddSavedAddress($input: SavedAddressInput!, $jwt: String!) {
  addSavedAddress(input: $input, jwt: $jwt) {
    id
    savedAddresses { id label street addressType floor apartment deliveryInstructions }
    defaultAddressId
  }
}
```

```json
{
  "input": {
    "label": "Casa",
    "street": "Calle 23 entre L y M",
    "latitude": 23.1364,
    "longitude": -82.3666,
    "addressType": "apartment",
    "buildingName": "Edificio Habana Center",
    "floor": "5",
    "apartment": "5B",
    "deliveryInstructions": "Tocar timbre 2 veces",
    "setAsDefault": true
  },
  "jwt": "..."
}
```

#### `updateSavedAddress` — Editar dirección existente

```graphql
mutation UpdateSavedAddress($input: UpdateSavedAddressInput!, $jwt: String!) {
  updateSavedAddress(input: $input, jwt: $jwt) {
    savedAddresses { id label street }
    defaultAddressId
  }
}
```

```json
{
  "input": {
    "addressId": "uuid-de-la-direccion",
    "floor": "6",
    "deliveryInstructions": "Dejar con el portero si no hay respuesta"
  }
}
```
> Solo los campos que se envíen se actualizarán. El resto conserva su valor anterior.

#### `removeSavedAddress` — Eliminar dirección

```graphql
mutation RemoveSavedAddress($addressId: String!, $jwt: String!) {
  removeSavedAddress(addressId: $addressId, jwt: $jwt) {
    savedAddresses { id label }
    defaultAddressId
  }
}
```
> Si se elimina la dirección que era el default, `defaultAddressId` queda en `null` automáticamente.

#### `setDefaultAddress` — Cambiar dirección predeterminada

```graphql
mutation SetDefaultAddress($addressId: String!, $jwt: String!) {
  setDefaultAddress(addressId: $addressId, jwt: $jwt) {
    defaultAddressId
  }
}
```

---

### Flujo recomendado en el frontend

```
1. Al abrir el checkout:
   → Consultar user.savedAddresses y user.defaultAddressId
   → Si hay defaultAddressId, pre-rellenar el form con esa dirección
   → Mostrar lista de direcciones guardadas para seleccionar una diferente
   → Opción "Usar otra dirección" abre el formulario nuevo

2. Al confirmar la dirección (nueva o existente):
   → Ofrecer "¿Guardar esta dirección?" con campo para el label (Casa / Trabajo / Otro)
   → Checkbox "Usar como predeterminada"
   → Si marca guardar → llamar a addSavedAddress antes o después de createOrder

3. Gestión en perfil (pantalla "Mis Direcciones"):
   → Listar savedAddresses
   → Botón ⭐ para marcar default (setDefaultAddress)
   → Botón ✏️ para editar (updateSavedAddress)
   → Botón 🗑️ para eliminar (removeSavedAddress)
```

---

### UX de pantalla "Mis Direcciones" (Perfil)

```
┌─────────────────────────────────┐
│  Mis Direcciones                │
├─────────────────────────────────┤
│ ⭐ Casa                   [✏️] [🗑️]│
│  Calle 23 entre L y M          │
│  Edif. Habana Center · P5 · 5B │
│  "Tocar timbre 2 veces"         │
├─────────────────────────────────┤
│    Trabajo                [✏️] [🗑️]│
│  Av. Paseo #12, Vedado         │
├─────────────────────────────────┤
│  [+ Agregar nueva dirección]    │
└─────────────────────────────────┘
```
