# Prompt para Claude Code - Sistema de Órdenes y Pedidos

## Contexto del Proyecto

Estoy desarrollando el backend para **Llego**, una app de delivery similar a Uber Eats/Rappi. El backend está en **Python con Strawberry GraphQL** y usa **MongoDB** como base de datos. Ya tengo implementado:

- Autenticación (JWT, Google, Apple Sign-In)
- Usuarios, Negocios, Sucursales, Productos
- Categorías y búsqueda con vectores
- Validación de pagos por transferencia (OCR con Gemini)
- Integración con Stripe para pagos con tarjeta

Ahora necesito implementar el **sistema completo de órdenes y pedidos** con tracking en tiempo real.

---

## Arquitectura Actual

```
Backend: Python 3.11+ con Strawberry GraphQL
Base de datos: MongoDB (Motor async)
Real-time: GraphQL Subscriptions (websockets)
Hosting: Railway
```

---

## Lo que necesito que implementes

### 1. Modelos MongoDB (Colecciones)

#### Colección `orders`

```python
# Estructura del documento
{
    "_id": ObjectId,
    "order_number": str,           # "ORD-2026-001234" (único, legible para humanos)
    "customer_id": ObjectId,       # ref: users
    "branch_id": ObjectId,         # ref: branches (sucursal que prepara el pedido)
    "business_id": ObjectId,       # ref: businesses
    
    # Items del pedido (snapshot al momento de crear)
    "items": [{
        "product_id": ObjectId,
        "name": str,               # snapshot del nombre del producto
        "price": float,            # snapshot del precio al momento de ordenar
        "quantity": int,
        "image_url": str,
        "was_modified_by_store": bool  # True si la tienda modificó este item
    }],
    
    # Totales calculados
    "subtotal": float,
    "delivery_fee": float,
    "discounts": [{
        "id": str,
        "title": str,              # "Descuento Premium", "Nivel Gold", etc.
        "amount": float,
        "type": str                # "premium" | "level" | "promo"
    }],
    "total": float,
    "currency": str,               # "USD" | "CUP"
    
    # Estado del pedido
    "status": str,                 # Ver enum OrderStatus abajo
    
    # Dirección de entrega
    "delivery_address": {
        "street": str,
        "city": str,
        "reference": str,          # "Casa azul, portón negro"
        "coordinates": {
            "type": "Point",
            "coordinates": [lng, lat]
        }
    },
    
    # Repartidor asignado (nullable hasta que se asigne)
    "delivery_person_id": ObjectId | None,
    "estimated_delivery_time": datetime | None,
    
    # Timeline de eventos (historial completo)
    "timeline": [{
        "status": str,
        "timestamp": datetime,
        "message": str,            # "Pedido confirmado", "Juan está preparando tu orden"
        "actor": str               # "customer" | "business" | "system" | "delivery"
    }],
    
    # Chat/comentarios del pedido
    "comments": [{
        "id": str,
        "author": str,             # "customer" | "business"
        "message": str,
        "timestamp": datetime
    }],
    
    # Información de pago
    "payment_method": str,         # "card" | "transfer" | "cash" | "apple_pay"
    "payment_status": str,         # "pending" | "validated" | "completed" | "failed"
    "payment_id": ObjectId | None, # ref: payments (si aplica)
    
    # Timestamps
    "created_at": datetime,
    "updated_at": datetime,
    "last_status_at": datetime     # Última vez que cambió el status
}
```

#### Colección `delivery_persons` (Repartidores)

```python
{
    "_id": ObjectId,
    "user_id": ObjectId,           # ref: users (el repartidor también es usuario)
    "name": str,
    "phone": str,
    "rating": float,               # 4.8
    "total_deliveries": int,
    "vehicle_type": str,           # "moto" | "bicicleta" | "auto" | "a_pie"
    "vehicle_plate": str | None,   # "ABC-123"
    "profile_image_url": str,
    "is_active": bool,             # Si está disponible para entregas
    "is_online": bool,             # Si está conectado a la app
    "current_location": {
        "type": "Point",
        "coordinates": [lng, lat]
    },
    "current_order_id": ObjectId | None,  # Pedido que está entregando actualmente
    "created_at": datetime,
    "updated_at": datetime
}
```

#### Colección `order_location_updates` (Para tracking en tiempo real)

```python
{
    "_id": ObjectId,
    "order_id": ObjectId,
    "delivery_person_id": ObjectId,
    "location": {
        "type": "Point",
        "coordinates": [lng, lat]
    },
    "timestamp": datetime,
    "speed": float | None,         # km/h
    "heading": float | None        # dirección en grados
}
```

---

### 2. Enums de Estado

```python
class OrderStatus(str, Enum):
    PENDING_ACCEPTANCE = "pending_acceptance"    # Esperando que la tienda acepte
    MODIFIED_BY_STORE = "modified_by_store"      # Tienda modificó items, esperando confirmación cliente
    ACCEPTED = "accepted"                         # Tienda aceptó el pedido
    PREPARING = "preparing"                       # En preparación
    READY_FOR_PICKUP = "ready_for_pickup"        # Listo para que el repartidor recoja
    ON_THE_WAY = "on_the_way"                    # Repartidor en camino
    DELIVERED = "delivered"                       # Entregado
    CANCELLED = "cancelled"                       # Cancelado

class PaymentStatus(str, Enum):
    PENDING = "pending"
    VALIDATED = "validated"
    COMPLETED = "completed"
    FAILED = "failed"

class DiscountType(str, Enum):
    PREMIUM = "premium"
    LEVEL = "level"
    PROMO = "promo"

class OrderActor(str, Enum):
    CUSTOMER = "customer"
    BUSINESS = "business"
    SYSTEM = "system"
    DELIVERY = "delivery"
```

---

### 3. Schema GraphQL Completo

#### Types

```graphql
type OrderType {
  id: String!
  orderNumber: String!
  customer: UserType!
  branch: BranchType!
  business: BusinessType!
  items: [OrderItemType!]!
  subtotal: Float!
  deliveryFee: Float!
  discounts: [OrderDiscountType!]!
  total: Float!
  currency: String!
  status: OrderStatusEnum!
  deliveryAddress: DeliveryAddressType!
  deliveryPerson: DeliveryPersonType
  estimatedDeliveryTime: DateTime
  timeline: [OrderTimelineType!]!
  comments: [OrderCommentType!]!
  paymentMethod: String!
  paymentStatus: PaymentStatusEnum!
  createdAt: DateTime!
  updatedAt: DateTime!
  lastStatusAt: DateTime!
  
  # Computed fields
  isEditable: Boolean!              # True si status == modified_by_store
  canCancel: Boolean!               # True si no está delivered/cancelled
  estimatedMinutesRemaining: Int    # Minutos estimados para entrega
}

type OrderItemType {
  productId: String!
  name: String!
  price: Float!
  quantity: Int!
  imageUrl: String!
  wasModifiedByStore: Boolean!
  lineTotal: Float!                 # price * quantity
}

type OrderDiscountType {
  id: String!
  title: String!
  amount: Float!
  type: DiscountTypeEnum!
}

type DeliveryAddressType {
  street: String!
  city: String
  reference: String
  coordinates: CoordinatesType!
}

type DeliveryPersonType {
  id: String!
  name: String!
  phone: String!
  rating: Float!
  totalDeliveries: Int!
  vehicleType: String!
  vehiclePlate: String
  profileImageUrl: String
  currentLocation: CoordinatesType
  isOnline: Boolean!
}

type OrderTimelineType {
  status: OrderStatusEnum!
  timestamp: DateTime!
  message: String!
  actor: OrderActorEnum!
}

type OrderCommentType {
  id: String!
  author: OrderActorEnum!
  message: String!
  timestamp: DateTime!
}

type OrderTrackingType {
  order: OrderType!
  deliveryPersonLocation: CoordinatesType
  storeLocation: CoordinatesType!
  deliveryLocation: CoordinatesType!
  estimatedMinutes: Int
  distanceKm: Float
  routePolyline: String             # Encoded polyline para mostrar ruta en mapa
}

type OrdersConnectionType {
  orders: [OrderType!]!
  totalCount: Int!
  hasMore: Boolean!
}
```

#### Enums

```graphql
enum OrderStatusEnum {
  PENDING_ACCEPTANCE
  MODIFIED_BY_STORE
  ACCEPTED
  PREPARING
  READY_FOR_PICKUP
  ON_THE_WAY
  DELIVERED
  CANCELLED
}

enum PaymentStatusEnum {
  PENDING
  VALIDATED
  COMPLETED
  FAILED
}

enum DiscountTypeEnum {
  PREMIUM
  LEVEL
  PROMO
}

enum OrderActorEnum {
  CUSTOMER
  BUSINESS
  SYSTEM
  DELIVERY
}

enum VehicleTypeEnum {
  MOTO
  BICICLETA
  AUTO
  A_PIE
}
```

#### Inputs

```graphql
input CreateOrderInput {
  branchId: String!
  items: [OrderItemInput!]!
  deliveryAddress: DeliveryAddressInput!
  paymentMethod: String!            # "card" | "transfer" | "cash" | "apple_pay"
  paymentIntentId: String           # Solo si paymentMethod == "card"
  comments: String                  # Comentario inicial opcional
  promoCode: String                 # Código promocional opcional
}

input OrderItemInput {
  productId: String!
  quantity: Int!
}

input DeliveryAddressInput {
  street: String!
  city: String
  reference: String
  latitude: Float!
  longitude: Float!
}

input UpdateOrderStatusInput {
  orderId: String!
  status: OrderStatusEnum!
  message: String                   # Mensaje opcional para el timeline
}

input AddOrderCommentInput {
  orderId: String!
  message: String!
}

input ModifyOrderItemsInput {
  orderId: String!
  items: [OrderItemInput!]!         # Nueva lista de items
  reason: String!                   # "Producto agotado", "Cambio de precio", etc.
}

input UpdateDeliveryLocationInput {
  orderId: String!
  latitude: Float!
  longitude: Float!
  speed: Float
  heading: Float
}

input AssignDeliveryPersonInput {
  orderId: String!
  deliveryPersonId: String!
  estimatedMinutes: Int
}
```

#### Queries

```graphql
extend type Query {
  # Para clientes
  "Obtener mis pedidos con paginación"
  myOrders(
    status: OrderStatusEnum
    limit: Int = 20
    offset: Int = 0
    jwt: String!
  ): OrdersConnectionType!
  
  "Obtener un pedido específico por ID"
  order(id: String!, jwt: String!): OrderType
  
  "Obtener pedido por número de orden"
  orderByNumber(orderNumber: String!, jwt: String!): OrderType
  
  "Tracking completo de un pedido (incluye ubicación del repartidor)"
  orderTracking(orderId: String!, jwt: String!): OrderTrackingType
  
  # Para negocios/sucursales
  "Pedidos de una sucursal (para managers)"
  branchOrders(
    branchId: String!
    status: OrderStatusEnum
    fromDate: DateTime
    toDate: DateTime
    limit: Int = 50
    offset: Int = 0
    jwt: String!
  ): OrdersConnectionType!
  
  "Pedidos pendientes de una sucursal (para notificaciones)"
  pendingBranchOrders(branchId: String!, jwt: String!): [OrderType!]!
  
  # Para repartidores
  "Pedidos disponibles para recoger cerca del repartidor"
  availableOrdersForDelivery(
    latitude: Float!
    longitude: Float!
    radiusKm: Float = 5
    jwt: String!
  ): [OrderType!]!
  
  "Pedido actual del repartidor"
  myCurrentDelivery(jwt: String!): OrderType
  
  # Para admin
  "Estadísticas de pedidos"
  orderStats(
    branchId: String
    fromDate: DateTime!
    toDate: DateTime!
    jwt: String!
  ): OrderStatsType!
}

type OrderStatsType {
  totalOrders: Int!
  completedOrders: Int!
  cancelledOrders: Int!
  totalRevenue: Float!
  averageOrderValue: Float!
  averageDeliveryTime: Int!         # en minutos
}
```

#### Mutations

```graphql
extend type Mutation {
  # Para clientes
  "Crear nuevo pedido desde el carrito"
  createOrder(input: CreateOrderInput!, jwt: String!): OrderType!
  
  "Aceptar modificaciones hechas por la tienda"
  acceptOrderModifications(orderId: String!, jwt: String!): OrderType!
  
  "Rechazar modificaciones y cancelar pedido"
  rejectOrderModifications(orderId: String!, jwt: String!): OrderType!
  
  "Cancelar pedido (solo si está en estados iniciales)"
  cancelOrder(orderId: String!, reason: String, jwt: String!): OrderType!
  
  "Añadir comentario al pedido"
  addOrderComment(input: AddOrderCommentInput!, jwt: String!): OrderType!
  
  "Calificar pedido después de entrega"
  rateOrder(orderId: String!, rating: Int!, comment: String, jwt: String!): OrderType!
  
  # Para negocios/sucursales
  "Aceptar pedido"
  acceptOrder(orderId: String!, estimatedMinutes: Int!, jwt: String!): OrderType!
  
  "Rechazar pedido"
  rejectOrder(orderId: String!, reason: String!, jwt: String!): OrderType!
  
  "Modificar items del pedido (productos agotados, etc.)"
  modifyOrderItems(input: ModifyOrderItemsInput!, jwt: String!): OrderType!
  
  "Actualizar estado del pedido"
  updateOrderStatus(input: UpdateOrderStatusInput!, jwt: String!): OrderType!
  
  "Marcar pedido como listo para recoger"
  markOrderReady(orderId: String!, jwt: String!): OrderType!
  
  # Para repartidores
  "Aceptar pedido para entrega"
  acceptDelivery(orderId: String!, jwt: String!): OrderType!
  
  "Confirmar recogida del pedido en la tienda"
  confirmPickup(orderId: String!, jwt: String!): OrderType!
  
  "Actualizar ubicación durante la entrega"
  updateDeliveryLocation(input: UpdateDeliveryLocationInput!, jwt: String!): Boolean!
  
  "Confirmar entrega completada"
  confirmDelivery(orderId: String!, jwt: String!): OrderType!
  
  # Para admin
  "Asignar repartidor manualmente"
  assignDeliveryPerson(input: AssignDeliveryPersonInput!, jwt: String!): OrderType!
  
  "Forzar cambio de estado (admin only)"
  forceOrderStatus(orderId: String!, status: OrderStatusEnum!, reason: String!, jwt: String!): OrderType!
}
```

#### Subscriptions (Real-time con WebSockets)

```graphql
type Subscription {
  # Para clientes - seguir su pedido
  "Escuchar todos los cambios en un pedido específico"
  orderUpdated(orderId: String!): OrderType!
  
  "Ubicación del repartidor en tiempo real (actualiza cada 5-10 segundos)"
  deliveryLocationUpdated(orderId: String!): DeliveryLocationUpdateType!
  
  # Para negocios - recibir nuevos pedidos
  "Nuevos pedidos entrantes para una sucursal"
  newBranchOrder(branchId: String!): OrderType!
  
  "Cambios en pedidos de una sucursal"
  branchOrderUpdated(branchId: String!): OrderType!
  
  # Para repartidores
  "Nuevos pedidos disponibles cerca"
  newAvailableDelivery(latitude: Float!, longitude: Float!, radiusKm: Float!): OrderType!
  
  "Actualizaciones del pedido que está entregando"
  currentDeliveryUpdated(deliveryPersonId: String!): OrderType!
}

type DeliveryLocationUpdateType {
  orderId: String!
  location: CoordinatesType!
  timestamp: DateTime!
  estimatedMinutesRemaining: Int
  distanceRemainingKm: Float
}
```

---

### 4. Lógica de Negocio Importante

#### Generación de número de orden
```python
def generate_order_number() -> str:
    """Genera número único legible: ORD-2026-XXXXXX"""
    year = datetime.now().year
    # Usar contador en Redis o secuencia en MongoDB
    sequence = get_next_sequence("orders")
    return f"ORD-{year}-{sequence:06d}"
```

#### Validaciones al crear orden
```python
async def create_order(input: CreateOrderInput, user_id: str):
    # 1. Validar que la sucursal existe y está activa
    # 2. Validar que todos los productos existen y están disponibles
    # 3. Validar stock de productos
    # 4. Calcular subtotal con precios actuales (snapshot)
    # 5. Calcular delivery fee basado en distancia
    # 6. Aplicar descuentos (premium, nivel, promo)
    # 7. Validar pago si es con tarjeta (verificar paymentIntent)
    # 8. Crear orden con status PENDING_ACCEPTANCE
    # 9. Notificar a la sucursal (push notification + subscription)
    # 10. Retornar orden creada
```

#### Flujo de estados permitidos
```python
ALLOWED_TRANSITIONS = {
    "pending_acceptance": ["accepted", "modified_by_store", "cancelled"],
    "modified_by_store": ["accepted", "cancelled"],  # Cliente acepta o rechaza
    "accepted": ["preparing", "cancelled"],
    "preparing": ["ready_for_pickup", "cancelled"],
    "ready_for_pickup": ["on_the_way", "cancelled"],
    "on_the_way": ["delivered", "cancelled"],
    "delivered": [],  # Estado final
    "cancelled": [],  # Estado final
}
```

#### Cálculo de delivery fee
```python
def calculate_delivery_fee(branch_coords, delivery_coords) -> float:
    distance_km = haversine_distance(branch_coords, delivery_coords)
    
    BASE_FEE = 1.50  # USD
    PER_KM_FEE = 0.50
    
    if distance_km <= 2:
        return BASE_FEE
    else:
        return BASE_FEE + (distance_km - 2) * PER_KM_FEE
```

---

### 5. Índices MongoDB Requeridos

```python
# Crear estos índices al inicializar la app

# orders
await db.orders.create_index([("customer_id", 1), ("created_at", -1)])
await db.orders.create_index([("branch_id", 1), ("status", 1), ("created_at", -1)])
await db.orders.create_index("order_number", unique=True)
await db.orders.create_index("status")
await db.orders.create_index([("delivery_address.coordinates", "2dsphere")])
await db.orders.create_index([("payment_status", 1), ("status", 1)])

# delivery_persons
await db.delivery_persons.create_index([("current_location", "2dsphere")])
await db.delivery_persons.create_index([("is_active", 1), ("is_online", 1)])
await db.delivery_persons.create_index("user_id", unique=True)

# order_location_updates (TTL para limpiar datos viejos)
await db.order_location_updates.create_index("order_id")
await db.order_location_updates.create_index(
    "timestamp", 
    expireAfterSeconds=86400  # Eliminar después de 24 horas
)
```

---

### 6. Estructura de Archivos Sugerida

```
app/
├── orders/
│   ├── __init__.py
│   ├── models.py              # Modelos Pydantic/dataclasses
│   ├── repository.py          # Operaciones MongoDB
│   ├── service.py             # Lógica de negocio
│   ├── schema.py              # Types y resolvers GraphQL
│   ├── mutations.py           # Mutations GraphQL
│   ├── queries.py             # Queries GraphQL
│   ├── subscriptions.py       # Subscriptions GraphQL
│   └── utils.py               # Helpers (calcular fee, generar número, etc.)
├── delivery/
│   ├── __init__.py
│   ├── models.py
│   ├── repository.py
│   ├── service.py
│   ├── schema.py
│   └── tracking.py            # Lógica de tracking en tiempo real
```

---

### 7. Consideraciones de Real-time

Para las subscriptions necesitas:

1. **Redis Pub/Sub** para comunicar entre instancias del servidor
2. **Broadcast channels** por orden y por sucursal
3. **Rate limiting** en actualizaciones de ubicación (máx 1 cada 5 segundos)

```python
# Ejemplo de publicar actualización
async def publish_order_update(order_id: str, order: OrderType):
    await redis.publish(f"order:{order_id}", order.json())
    
# Ejemplo de publicar ubicación
async def publish_location_update(order_id: str, location: dict):
    await redis.publish(f"delivery_location:{order_id}", json.dumps(location))
```

---

### 8. Notificaciones Push

Implementar notificaciones para:

- **Cliente**: Nuevo estado del pedido, repartidor asignado, pedido entregado
- **Negocio**: Nuevo pedido recibido, pedido cancelado
- **Repartidor**: Nuevo pedido disponible, pedido asignado

---

## Resumen de lo que debes crear

1. ✅ Modelos MongoDB para `orders`, `delivery_persons`, `order_location_updates`
2. ✅ Enums de estado
3. ✅ Schema GraphQL completo (types, inputs, queries, mutations, subscriptions)
4. ✅ Lógica de negocio (validaciones, transiciones de estado, cálculos)
5. ✅ Índices MongoDB
6. ✅ Sistema de subscriptions con Redis Pub/Sub
7. ✅ Integración con el sistema de pagos existente

El código debe seguir el patrón existente del proyecto (repository pattern, async/await, Strawberry GraphQL).
