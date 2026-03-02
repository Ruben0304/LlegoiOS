# Frontend Handoff: Vitrinas + Órdenes Mixtas

## Contexto breve
El problema identificado fue que para muchos negocios es costoso mantener catálogo producto por producto (foto + datos individuales).  
Se implementó una nueva entidad **Vitrina** para que el negocio pueda publicar una **foto principal** de una sucursal y, opcionalmente, una lista de ítems detectados o editados manualmente.

Puntos clave de diseño:
- La vitrina se asocia a **`branchId`** (no usa `businessId`).
- `items` en vitrina es **opcional** (`null` permitido).
- Los `items` de vitrina no tienen `currency` (solo `price` opcional).
- Las órdenes ahora soportan mezcla de ítems:
  - `PRODUCT` (producto normal)
  - `SHOWCASE` (pedido desde vitrina con descripción manual del cliente)

---

## Flujo recomendado de frontend
1. Subir foto de vitrina por REST.
2. (Opcional) pasar foto por detección IA para prellenar ítems.
3. Crear vitrina por GraphQL.
4. Mostrar vitrinas por sucursal (`showcasesByBranch`).
5. Crear orden con ítems mixtos (`createOrder`).

---

## Autenticación
### REST
- Header: `Authorization: Bearer <JWT>`

### GraphQL (`/graphql`)
- El token se pasa como argumento `jwt` en queries/mutations.
- Debe enviarse el token plano (sin `Bearer`).

---

## REST: uploads y detección

## 1) Subir imagen de vitrina
`POST /upload/showcase/image`

- `multipart/form-data`
- campo archivo: `image`
- auth requerida

Ejemplo:
```bash
curl -X POST "https://TU_API/upload/showcase/image" \
  -H "Authorization: Bearer <JWT>" \
  -F "image=@/ruta/foto-vitrina.jpg"
```

Respuesta:
```json
{
  "image_path": "showcases/....jpg",
  "image_url": "https://...presigned..."
}
```

Usar `image_path` al crear/actualizar vitrina.

## 2) (Opcional) Detección IA desde vitrina
`POST /products/detect-from-showcase`

- `multipart/form-data`
- campo archivo: `file`
- auth requerida

Ejemplo:
```bash
curl -X POST "https://TU_API/products/detect-from-showcase" \
  -H "Authorization: Bearer <JWT>" \
  -F "file=@/ruta/foto-vitrina.jpg"
```

Respuesta:
```json
{
  "products": [
    {
      "name": "Pan integral",
      "description": "....",
      "price": 2.5,
      "currency": "USD",
      "weight": ""
    }
  ]
}
```

Nota: detección IA **no persiste** en BD. Solo devuelve sugerencias para UI.

---

## GraphQL: contrato de Vitrinas

## Inputs
```graphql
input ShowcaseItemInput {
  id: String = null
  name: String!
  description: String = null
  price: Float = null
  availability: Boolean! = true
}

input CreateShowcaseInput {
  branchId: String!
  title: String!
  image: String!
  description: String = null
  items: [ShowcaseItemInput!] = null
}

input UpdateShowcaseInput {
  title: String = null
  image: String = null
  description: String = null
  items: [ShowcaseItemInput!] = null
  isActive: Boolean = null
}
```

## Tipo de respuesta
```graphql
type ShowcaseType {
  id: String!
  branchId: String!
  title: String!
  image: String!
  description: String
  items: [ShowcaseItemType!]
  isActive: Boolean!
  createdAt: DateTime!
  updatedAt: DateTime!
  imageUrl: String!
  branch: BranchType
}
```

## Queries
### Obtener por ID
```graphql
query ShowcaseById($showcaseId: String!, $jwt: String!) {
  showcase(showcaseId: $showcaseId, jwt: $jwt) {
    id
    branchId
    title
    description
    image
    imageUrl
    isActive
    items {
      id
      name
      description
      price
      availability
    }
    createdAt
    updatedAt
  }
}
```

### Obtener por sucursal
```graphql
query ShowcasesByBranch($branchId: String!, $jwt: String!) {
  showcasesByBranch(branchId: $branchId, activeOnly: true, jwt: $jwt) {
    id
    title
    description
    imageUrl
    isActive
    items {
      id
      name
      price
      availability
    }
  }
}
```

### Obtener todas
```graphql
query AllShowcases($jwt: String!) {
  allShowcases(activeOnly: false, jwt: $jwt) {
    id
    branchId
    title
    isActive
  }
}
```

## Mutations
### Crear vitrina (solo foto, sin items)
```graphql
mutation CreateShowcase($input: CreateShowcaseInput!, $jwt: String!) {
  createShowcase(input: $input, jwt: $jwt) {
    id
    title
    image
    imageUrl
    items
    isActive
  }
}
```

Variables ejemplo:
```json
{
  "jwt": "TOKEN_PLANO",
  "input": {
    "branchId": "67f....",
    "title": "Vitrina principal",
    "image": "showcases/....jpg",
    "description": "Actualizada hoy",
    "items": null
  }
}
```

### Crear vitrina con items
```graphql
mutation CreateShowcaseWithItems($input: CreateShowcaseInput!, $jwt: String!) {
  createShowcase(input: $input, jwt: $jwt) {
    id
    title
    items {
      id
      name
      description
      price
      availability
    }
  }
}
```

### Actualizar vitrina
```graphql
mutation UpdateShowcase($showcaseId: String!, $input: UpdateShowcaseInput!, $jwt: String!) {
  updateShowcase(showcaseId: $showcaseId, input: $input, jwt: $jwt) {
    id
    title
    description
    image
    imageUrl
    isActive
    items {
      id
      name
      price
      availability
    }
    updatedAt
  }
}
```

### Activar/desactivar
```graphql
mutation ToggleShowcase($showcaseId: String!, $isActive: Boolean!, $jwt: String!) {
  toggleShowcaseAvailability(showcaseId: $showcaseId, isActive: $isActive, jwt: $jwt) {
    id
    isActive
  }
}
```

### Eliminar
```graphql
mutation DeleteShowcase($showcaseId: String!, $jwt: String!) {
  deleteShowcase(showcaseId: $showcaseId, jwt: $jwt)
}
```

---

## GraphQL: órdenes mixtas (PRODUCT + SHOWCASE)

## Input de ítem de orden
```graphql
enum OrderItemTypeInput {
  PRODUCT
  SHOWCASE
}

input OrderItemInput {
  quantity: Int!
  itemType: OrderItemTypeInput! = PRODUCT
  productId: String = null
  showcaseId: String = null
  description: String = null
}
```

Reglas de negocio:
- `PRODUCT`: requiere `productId`.
- `SHOWCASE`: requiere `showcaseId` y **`description` obligatoria** (texto manual del cliente).

## Crear orden mixta
```graphql
mutation CreateOrder($input: CreateOrderInput!, $jwt: String!) {
  createOrder(input: $input, jwt: $jwt) {
    id
    orderNumber
    subtotal
    total
    status
    items {
      itemType
      itemId
      productId
      name
      quantity
      basePrice
      finalPrice
      requestDescription
      imageUrl
      lineTotal
    }
  }
}
```

Variables ejemplo:
```json
{
  "jwt": "TOKEN_PLANO",
  "input": {
    "branchId": "67f....",
    "paymentMethod": "cash",
    "comments": "Tocar puerta",
    "deliveryAddress": {
      "street": "Calle 1",
      "latitude": 23.12,
      "longitude": -82.38,
      "city": "La Habana"
    },
    "items": [
      {
        "itemType": "PRODUCT",
        "productId": "680....",
        "quantity": 2
      },
      {
        "itemType": "SHOWCASE",
        "showcaseId": "681....",
        "description": "Quiero 2 panes integrales y 1 croqueta",
        "quantity": 1
      }
    ]
  }
}
```

---

## Detalles de UX recomendados
- En detalle de vitrina, mostrar CTA: **"Pedir desde vitrina"**.
- Para item `SHOWCASE`, abrir textarea obligatorio:
  - placeholder sugerido: `"Describe exactamente qué quieres (cantidad, variantes, etc.)"`.
- Mostrar aviso al usuario:
  - `"Este pedido será confirmado por la tienda según disponibilidad y precio final."`
- Si la vitrina no tiene `items`, se puede pedir igual por descripción manual.

---

## Consideraciones técnicas importantes
- `items` en `UpdateShowcaseInput`:
  - si no envías `items`, no se modifica.
  - si envías `items: []`, limpias la lista.
- `SHOWCASE` entra a la orden con `basePrice/finalPrice = 0.0` inicialmente.
- El backend mantiene compatibilidad legacy en órdenes (`productId/price`) para clientes antiguos.
- `imageUrl` es presigned temporal; persistir siempre `image` (`image_path`) como referencia canónica.

---

## Checklist de integración frontend
- Subida de imagen vitrina (`/upload/showcase/image`) lista.
- Pantalla crear/editar vitrina lista (con `items` opcionales).
- Listado de vitrinas por sucursal (`showcasesByBranch`) integrado.
- Flujo de crear orden con `OrderItemInput.itemType` integrado.
- Validación UI de `description` obligatoria para `SHOWCASE`.
- Manejo de errores GraphQL (ejemplo: `Vitrina no encontrada`, `Para ítems de vitrina debes escribir una descripción...`).

