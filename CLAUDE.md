# LlegoiOS - Guía Técnica

Aplicación de delivery y e-commerce construida con SwiftUI que conecta usuarios con tiendas locales.

## 📋 Stack Tecnológico

- **Framework**: SwiftUI (iOS 15+)
- **Lenguaje**: Swift 5.9+
- **API Cliente**: Apollo iOS 2.0.0 (GraphQL)
- **Cache**: SQLite (ApolloSQLite)
- **Pagos**: Stripe iOS SDK
- **Backend**: GraphQL API (Railway)

## 🏗️ Arquitectura

**Patrón**: MVVM + Repository

```
View (SwiftUI)
  ↓
ViewModel (@MainActor)
  ↓
Repository
  ↓
ApolloClient → GraphQL Backend
```

## 📁 Estructura del Proyecto

```
LlegoiOS/
├── iOSApp.swift                    # Entry point
├── ContentView.swift               # Main TabView navigation
├── GraphQL/                        # Apollo generated code
│   ├── Schema/
│   └── Operations/
├── network/                        # Network layer
│   ├── ApolloClientManager.swift
│   ├── ApolloInterceptors.swift
│   └── StripeConfig.swift
├── helpers/                        # Shared utilities
│   ├── AuthManager.swift          # Authentication state (@MainActor)
│   ├── BranchTypeManager.swift    # Branch type filtering (@MainActor)
│   ├── CartManager.swift          # Shopping cart state
│   ├── FavoritesManager.swift     # Favorites management
│   ├── LocationManager.swift      # Device location
│   ├── UserLocationManager.swift  # User location selection
│   ├── PaymentManager.swift       # Stripe payments
│   ├── OrderManager.swift         # Order tracking
│   ├── ImageCache.swift           # Image caching
│   ├── KeychainHelper.swift       # Secure storage
│   └── OnboardingHelper.swift     # Onboarding state
├── models/                         # UI data models
│   ├── Models.swift               # Product, Store, etc.
│   ├── ChatMessage.swift
│   ├── PaymentMethod.swift
│   └── PaymentIntentResponse.swift
├── ui/
│   ├── screens/                   # Main screens (MVVM)
│   │   ├── Home/
│   │   ├── Auth/                  # Login, Register
│   │   ├── Product/
│   │   │   ├── List/             # ProductListView + ViewModel + Repository
│   │   │   └── Detail/           # ProductDetailView + ViewModel + Repository
│   │   ├── Store/
│   │   │   ├── List/             # StoreListView + ViewModel + Repository
│   │   │   └── Detail/           # StoreDetailView + ViewModel + Repository
│   │   ├── Order/
│   │   │   └── Detail/           # OrderDetailView + ViewModel + Repository
│   │   ├── Map/                   # MapView + ViewModel + Repository
│   │   ├── Profile/               # ProfileView + ViewModel + Repository
│   │   ├── ConversationalSearch/  # AI search
│   │   ├── Onboarding/
│   │   ├── PlansAndPricing/
│   │   ├── Tutorials/
│   │   └── Wallet/
│   ├── sheets/                    # Modal sheets
│   │   ├── Cart/                 # CartView + ViewModel + Repository
│   │   └── Favorites/            # FavoritesView + ViewModel + Repository
│   ├── components/                # Reusable components
│   │   ├── atoms/                # Basic UI elements
│   │   ├── molecules/            # Composite components
│   │   ├── organisms/            # Complex sections
│   │   ├── animations/           # Lottie animations
│   │   ├── skeletons/            # Loading skeletons
│   │   ├── shapes/               # Custom shapes
│   │   └── background/           # Background components
│   └── theme/                     # Design system
│       ├── Theme.swift
│       └── shapes/
└── resources/                      # Static assets

Archivos raíz:
├── schema.graphqls                 # GraphQL schema
├── apollo-codegen-config.json      # Apollo CLI config
├── *.graphql                       # GraphQL operations
└── apollo-ios-cli                  # Code generation CLI
```

## 📚 Documentación Detallada

### Configuración y Setup
- **[GraphQL Setup](docs/GRAPHQL_SETUP.md)** - Apollo iOS, schema, queries, code generation
- **[Concurrency Patterns](docs/CONCURRENCY_PATTERNS.md)** - Main Actor, Task, Sendable

### Arquitectura y Patrones
- **[MVVM + Repository](docs/MVVM_REPOSITORY_PATTERN.md)** - Patrón arquitectónico, ejemplos completos
- **[Design System](docs/DESIGN_SYSTEM.md)** - Colores, componentes, Atomic Design

## ⚡ Flujo de Trabajo Rápido

### Crear una Nueva Pantalla

1. **Crear carpeta**: `ui/screens/[NombrePantalla]/`
2. **Crear archivos**:
   - `[NombrePantalla]View.swift`
   - `[NombrePantalla]ViewModel.swift`
   - `[NombrePantalla]Repository.swift` (si necesita datos)
3. **Query GraphQL** (si necesario):
   - Crear archivo `.graphql` en raíz
   - Ejecutar: `./apollo-ios-cli generate`
4. **Implementar patrón MVVM** (ver [MVVM_REPOSITORY_PATTERN.md](docs/MVVM_REPOSITORY_PATTERN.md))

### Generar Código Apollo

```bash
# Desde la raíz del proyecto
./apollo-ios-cli generate
```

Ejecutar cada vez que:
- Creas/modificas archivos `.graphql`
- Actualizas `schema.graphqls`

## 🎨 Sistema de Diseño

### Colores Principales

```swift
Color.llegoPrimary      // Dark teal #023133
Color.llegoSecondary    // Warm beige #E1C78E
Color.llegoAccent       // Light green #B2D69A
Color.llegoBackground   // Light gray #F3F3F3
```

### Componentes (Atomic Design)

- **Atoms**: `ui/components/atoms/` - Elementos básicos
- **Molecules**: `ui/components/molecules/` - Componentes compuestos
- **Organisms**: `ui/components/organisms/` - Secciones complejas

Ver detalles en [DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md)

## 🚨 Reglas Críticas

### 1. Loading States
✅ **USAR**: `ProgressView` nativo 
❌ **NO USAR**: `LottieView` para indicadores de carga



### 2. Main Actor en Repositories
⚠️ **IMPORTANTE**: Acceder a `@MainActor` managers desde Repositories

```swift
// ✅ Correcto
func fetchData(completion: @escaping @Sendable (Result<Data, Error>) -> Void) {
    let client = apolloClient

    Task { @MainActor in
        let jwt = AuthManager.shared.getAccessToken()
        let branchType = BranchTypeManager.shared.selectedType.rawValue

        client.fetch(query: query) { result in
            // ...
        }
    }
}
```

Ver [CONCURRENCY_PATTERNS.md](docs/CONCURRENCY_PATTERNS.md) para detalles completos.

### 3. Una Repository por Pantalla
- Cada pantalla tiene su propio Repository
- Repository contiene SOLO las queries/mutations de esa pantalla
- Ejemplo: `HomeRepository` solo para `HomeView`

### 4. GraphQL Models vs UI Models
- **GraphQL Models**: Definidos en Repository (`*GraphQL` structs)
- **UI Models**: Definidos en `models/Models.swift` (`Product`, `Store`)
- ViewModel mapea GraphQL → UI Models

## 🔧 Helpers Principales

| Helper | Propósito | Ubicación |
|--------|-----------|-----------|
| `AuthManager` | Estado de autenticación (@MainActor) | `helpers/AuthManager.swift` |
| `BranchTypeManager` | Filtro de tipo de tienda (@MainActor) | `helpers/BranchTypeManager.swift` |
| `CartManager` | Carrito de compras | `helpers/CartManager.swift` |
| `UserLocationManager` | Ubicación del usuario | `helpers/UserLocationManager.swift` |
| `PaymentManager` | Integración Stripe | `helpers/PaymentManager.swift` |
| `OrderManager` | Gestión de pedidos | `helpers/OrderManager.swift` |

## 🌐 Backend

- **URL**: `https://llegobackend-production.up.railway.app/graphql`
- **Schema**: Ver `schema.graphqls`
- **Queries**: Ver archivos `*.graphql` en raíz

## 📦 Dependencias

Instaladas via SPM (Swift Package Manager):
- Apollo iOS 2.0.0
- ApolloAPI
- ApolloSQLite
- Lottie iOS
- Stripe iOS SDK

## 🐛 Troubleshooting

### Regenerar código Apollo
```bash
rm -rf LlegoiOS/GraphQL/Operations
./apollo-ios-cli generate
# Xcode: Product → Clean Build Folder (Cmd+Shift+K)
```

### Actualizar schema
```bash
npx --yes @apollo/rover graph introspect \
  https://llegobackend-production.up.railway.app/graphql \
  > schema.graphqls
```

## 📖 Recursos

- [Apollo iOS Docs](https://www.apollographql.com/docs/ios/)
- [SwiftUI Docs](https://developer.apple.com/documentation/swiftui)
- [Stripe iOS SDK](https://stripe.com/docs/payments/accept-a-payment?platform=ios)

---

**Última actualización**: Enero 2025
