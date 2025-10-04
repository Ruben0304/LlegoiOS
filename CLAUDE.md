# LlegoiOS - Guía Técnica Completa

## 📋 Índice
1. [Visión General del Proyecto](#visión-general-del-proyecto)
2. [Arquitectura del Proyecto](#arquitectura-del-proyecto)
3. [Integración Apollo GraphQL](#integración-apollo-graphql)
4. [Estructura de Pantallas y Repositorios](#estructura-de-pantallas-y-repositorios)
5. [Sistema de Diseño (Theme)](#sistema-de-diseño-theme)
6. [Modelos de Datos](#modelos-de-datos)
7. [Helpers y Utilidades](#helpers-y-utilidades)
8. [Componentes UI](#componentes-ui)
9. [Gestión de Estado](#gestión-de-estado)

---

## Visión General del Proyecto

**LlegoiOS** es una aplicación de delivery y e-commerce construida con SwiftUI que conecta a usuarios con tiendas locales. La aplicación utiliza GraphQL para la comunicación con el backend y sigue una arquitectura MVVM con repositorios.

### Stack Tecnológico
- **Framework**: SwiftUI (iOS)
- **Lenguaje**: Swift
- **Cliente GraphQL**: Apollo iOS 2.0.0
- **Gestión de Dependencias**: Swift Package Manager (SPM) + CocoaPods
- **Cache**: SQLite (ApolloSQLite)
- **Backend**: GraphQL API en Railway
- **Animaciones**: Lottie iOS

### Estadísticas del Proyecto
- **Total de archivos Swift**: 59
- **Pantallas principales**: 15+
- **Componentes UI**: 30+
- **Helpers**: 4

---

## Arquitectura del Proyecto

El proyecto sigue el patrón **MVVM + Repository** con la siguiente estructura:

```
LlegoiOS/
├── iOSApp.swift                    # Entry point
├── ContentView.swift               # Tab bar principal
├── GraphQL/                        # Código generado y configuración Apollo
│   ├── Schema/                     # Tipos del schema GraphQL
│   ├── Operations/                 # Queries y Mutations
│   └── LlegoAPI.graphql.swift     # API generada
├── network/                        # Cliente de red
│   └── ApolloClientManager.swift
├── ui/
│   ├── screens/                    # Pantallas (View + ViewModel + Repository)
│   ├── components/                 # Componentes reutilizables
│   │   ├── atoms/
│   │   ├── molecules/
│   │   └── organisms/
│   └── theme/                      # Sistema de diseño
├── models/                         # Modelos de datos
├── helpers/                        # Utilidades
└── Resources/                      # Assets y recursos

Archivos raíz:
├── schema.graphqls                 # Schema GraphQL
├── apollo-codegen-config.json      # Configuración Apollo CLI
├── GetHomeData.graphql             # Query principal
└── GetProducts.graphql             # Query de productos
```

---

## Integración Apollo GraphQL

### Versiones
- **Apollo iOS**: 2.0.0
- **Apollo CLI**: 2.0 (configuración moderna)

### Configuración Apollo CLI (`apollo-codegen-config.json`)

```json
{
  "schemaNamespace": "LlegoAPI",
  "input": {
    "operationSearchPaths": [
      "**/*.graphql"
    ],
    "schemaSearchPaths": [
      "schema.graphqls"
    ]
  },
  "output": {
    "testMocks": {
      "none": {}
    },
    "schemaTypes": {
      "path": "./LlegoiOS/GraphQL",
      "moduleType": {
        "embeddedInTarget": {
          "name": "LlegoiOS",
          "accessModifier": "public"
        }
      }
    },
    "operations": {
      "inSchemaModule": {}
    }
  }
}
```

### Instalación de Apollo

#### 1. Añadir Apollo iOS via SPM
En Xcode:
1. File → Add Package Dependencies
2. URL: `https://github.com/apollographql/apollo-ios.git`
3. Versión: 2.0.0
4. Seleccionar:
   - Apollo
   - ApolloAPI
   - ApolloSQLite
   - ApolloWebSocket

#### 2. Instalación Apollo iOS CLI

El proyecto incluye el ejecutable `apollo-ios-cli` en la raíz del proyecto. Este CLI se utiliza para generar código Swift a partir de los archivos GraphQL.

**Ubicación del CLI:**
```
/Users/suncar/projects/Llego Org/LlegoiOS/apollo-ios-cli
```

**Comando para generar código:**
```bash
# Desde la raíz del proyecto
./apollo-ios-cli generate
```

Este comando:
1. Lee la configuración de `apollo-codegen-config.json`
2. Busca todos los archivos `.graphql` en el proyecto (según `operationSearchPaths`)
3. Usa el schema en `schema.graphqls` (según `schemaSearchPaths`)
4. Genera código Swift en `LlegoiOS/GraphQL/`
5. Crea tipos para queries, mutations y schemas

**IMPORTANTE:** Debes ejecutar este comando cada vez que:
- Creas un nuevo archivo `.graphql` con queries o mutations
- Modificas queries existentes
- Actualizas el `schema.graphqls`

### Cliente Apollo (`ApolloClientManager.swift`)

```swift
import Foundation
import Apollo
import ApolloSQLite

final class ApolloClientManager: @unchecked Sendable {
    nonisolated(unsafe) static let shared = ApolloClientManager()

    private(set) lazy var apollo: ApolloClient = {
        let url = URL(string: "https://llegobackend-production.up.railway.app/graphql")!
        let store = ApolloStore(cache: cache)
        return ApolloClient(url: url)
    }()

    private lazy var cache: SQLiteNormalizedCache = {
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask,
            true
        ).first!
        let documentsURL = URL(fileURLWithPath: documentsPath)
        let sqliteFileURL = documentsURL.appendingPathComponent("llego_apollo_cache.sqlite")

        do {
            let sqliteCache = try SQLiteNormalizedCache(fileURL: sqliteFileURL)
            return sqliteCache
        } catch {
            fatalError("Failed to create SQLite cache: \(error)")
        }
    }()

    private init() {}
}
```

### Schema GraphQL (`schema.graphqls`)

```graphql
scalar DateTime
scalar JSON

type Query {
  users: [UserType!]!
  user(id: String!): UserType
  businesses: [BusinessType!]!
  business(id: String!): BusinessType
  branches: [BranchType!]!
  branch(id: String!): BranchType
  products: [ProductType!]!
  product(id: String!): ProductType
  searchProducts(query: String!): [ProductType!]!
}

type ProductType {
  id: String!
  branchId: String!
  name: String!
  description: String!
  weight: String!
  price: Float!
  currency: String!
  image: String!
  availability: Boolean!
  createdAt: DateTime!
}

type BranchType {
  id: String!
  businessId: String!
  name: String!
  address: String!
  coordinates: CoordinatesType!
  phone: String!
  schedule: JSON!
  status: String!
  createdAt: DateTime!
}

type CoordinatesType {
  type: String!
  coordinates: [Float!]!
}
```

### Queries GraphQL

#### `GetHomeData.graphql`
```graphql
query GetHomeData {
  products {
    id
    branchId
    name
    description
    weight
    price
    currency
    image
    availability
    createdAt
  }
  branches {
    id
    businessId
    name
    address
    coordinates {
      type
      coordinates
    }
    phone
    status
    createdAt
  }
}
```

#### `GetProducts.graphql`
```graphql
query GetProducts {
  products {
    id
    branchId
    name
    description
    weight
    price
    currency
    image
    availability
    createdAt
  }
}
```

#### `SearchProducts.graphql`
```graphql
query SearchProducts($query: String!) {
  searchProducts(query: $query) {
    id
    branchId
    name
    description
    weight
    price
    currency
    image
    availability
    createdAt
  }
}
```

#### `SearchBranches.graphql`
```graphql
query SearchBranches($query: String!) {
  searchBranches(query: $query) {
    id
    businessId
    name
    address
    coordinates {
      type
      coordinates
    }
    phone
    status
    createdAt
  }
}
```

### Generación de Código Apollo

**Comando oficial del proyecto:**
```bash
# Desde la raíz del proyecto
./apollo-ios-cli generate
```

**Verificar archivos generados:**
```bash
ls -la LlegoiOS/GraphQL/Operations/Queries/
```

Los archivos generados incluyen:
- `GetHomeDataQuery.graphql.swift`
- `GetProductsQuery.graphql.swift`
- `SearchProductsQuery.graphql.swift`
- `SearchBranchesQuery.graphql.swift`

**Actualizar schema desde el backend:**
```bash
# Usando Rover para descargar el schema actualizado
npx --yes @apollo/rover graph introspect \
  https://llegobackend-production.up.railway.app/graphql \
  > schema.graphqls
```

### Custom Scalars

#### `DateTime.swift`
```swift
import ApolloAPI

public typealias DateTime = String

extension DateTime: CustomScalarType {
    public init(_jsonValue value: JSONValue) throws {
        guard let stringValue = value as? String else {
            throw JSONDecodingError.couldNotConvert(value: value, to: String.self)
        }
        self = stringValue
    }

    public var _jsonValue: JSONValue {
        return self
    }
}
```

#### `JSON.swift`
```swift
import ApolloAPI

public typealias JSON = [String: Any]

extension JSON: CustomScalarType {
    public init(_jsonValue value: JSONValue) throws {
        guard let dict = value as? [String: Any] else {
            throw JSONDecodingError.couldNotConvert(value: value, to: [String: Any].self)
        }
        self = dict
    }

    public var _jsonValue: JSONValue {
        return self
    }
}
```

---

## Estructura de Pantallas y Repositorios

### Patrón MVVM + Repository: Arquitectura del Proyecto

El proyecto sigue el patrón **MVVM (Model-View-ViewModel) + Repository**, donde cada pantalla tiene tres capas bien definidas:

```
📱 View (SwiftUI)
    ↓ Usuario interactúa
📊 ViewModel (@MainActor, @ObservableObject)
    ↓ Llama métodos del repository
🗄️ Repository
    ↓ Ejecuta queries GraphQL
🌐 ApolloClient → Backend GraphQL
```

#### Principios del Patrón:

1. **Una Repository por Pantalla (No por Modelo)**
   - Cada pantalla tiene su propio Repository específico
   - El Repository contiene SOLO las queries/mutations que esa pantalla necesita
   - Ejemplo: `HomeRepository` solo para `HomeView`, `SearchRepository` solo para `SearchView`

2. **Separación de Responsabilidades:**
   - **View**: Renderiza UI, captura eventos del usuario
   - **ViewModel**: Maneja estado de UI, lógica de presentación, transforma datos
   - **Repository**: Comunicación con backend GraphQL, mapeo de modelos GraphQL

3. **Flujo de Datos:**
   ```
   View → ViewModel.loadData()
   ViewModel → Repository.fetchData()
   Repository → Apollo → GraphQL Backend
   GraphQL Backend → Apollo → Repository (GraphQL Models)
   Repository → ViewModel (UI Models)
   ViewModel (@Published) → View (re-render)
   ```

4. **Modelos de Datos:**
   - **GraphQL Models**: Definidos en Repository (ej: `SearchProductGraphQL`)
   - **UI Models**: Definidos en `Models.swift` (ej: `Product`, `Store`)
   - El ViewModel convierte GraphQL Models → UI Models

### Patrón: Una Repository por Pantalla (No por Modelo)

Cada pantalla tiene su propio **Repository** que maneja específicamente las queries y datos que esa pantalla necesita.

### Cómo Crear una Nueva Pantalla (Ejemplo: SearchView)

Sigue estos pasos para crear cualquier pantalla nueva usando el patrón MVVM + Repository:

**Paso 1: Crear Queries GraphQL**
- Crea archivos `.graphql` en la raíz del proyecto
- Usa queries definidas en `schema.graphqls`
- Ejemplo: `SearchProducts.graphql`, `SearchBranches.graphql`

**Paso 2: Generar Código Apollo**
```bash
./apollo-ios-cli generate
```

**Paso 3: Crear Repository**
- Ubicación: `ui/screens/[NombrePantalla]/[NombrePantalla]Repository.swift`
- Responsabilidades:
  - Ejecutar queries GraphQL usando `ApolloClientManager.shared.apollo`
  - Mapear respuestas GraphQL a modelos intermedios (`*GraphQL`)
  - Manejar errores de red y GraphQL
- Patrón: Define structs `Sendable` para modelos GraphQL dentro del mismo archivo

**Paso 4: Crear ViewModel**
- Ubicación: `ui/screens/[NombrePantalla]/[NombrePantalla]ViewModel.swift`
- Usar: `@MainActor class ... : ObservableObject`
- Responsabilidades:
  - Mantener estado de UI usando `@Published`
  - Llamar métodos del Repository
  - Transformar modelos GraphQL → UI Models (Product, Store)
  - Lógica de presentación (formateo, cálculos)
- Estados comunes: `idle`, `loading`, `success`, `error(String)`

**Paso 5: Integrar en View**
- Usar: `@StateObject private var viewModel = [NombrePantalla]ViewModel()`
- Llamar métodos del ViewModel en `.onAppear` o `.onChange`
- Renderizar según `viewModel.state` y `@Published` properties

**Importante:** Siempre revisa `HomeViewModel` y `HomeRepository` como referencia para seguir el mismo patrón.

---

### Ejemplo: HomeView

#### 1. Repository (`HomeRepository.swift`)
```swift
import Foundation
import Apollo

class HomeRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    func fetchHomeData(completion: @escaping @Sendable (Result<HomeData, Error>) -> Void) {
        apolloClient.fetch(
            query: LlegoAPI.GetHomeDataQuery(),
            cachePolicy: .returnCacheDataAndFetch
        ) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    print("❌ GraphQL Errors:")
                    errors.forEach { print("  - \($0.localizedDescription)") }
                    completion(.failure(NSError(domain: "GraphQL", code: -1)))
                    return
                }

                guard let data = graphQLResult.data else {
                    completion(.success(HomeData(products: [], branches: [])))
                    return
                }

                // Map GraphQL to local models
                let mappedProducts = data.products.map { product in
                    HomeProductGraphQL(
                        id: product.id,
                        branchId: product.branchId,
                        name: product.name,
                        description: product.description,
                        weight: product.weight,
                        price: product.price,
                        currency: product.currency,
                        image: product.image,
                        availability: product.availability,
                        createdAt: product.createdAt
                    )
                }

                let mappedBranches = data.branches.map { branch in
                    BranchGraphQL(
                        id: branch.id,
                        businessId: branch.businessId,
                        name: branch.name,
                        address: branch.address,
                        coordinates: CoordinatesGraphQL(
                            type: branch.coordinates.type,
                            coordinates: branch.coordinates.coordinates
                        ),
                        phone: branch.phone,
                        status: branch.status,
                        createdAt: branch.createdAt
                    )
                }

                completion(.success(HomeData(
                    products: mappedProducts,
                    branches: mappedBranches
                )))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Models específicos de HomeRepository
struct HomeData: Sendable {
    let products: [HomeProductGraphQL]
    let branches: [BranchGraphQL]
}

struct HomeProductGraphQL: Identifiable, Sendable {
    let id: String
    let branchId: String
    let name: String
    let description: String
    let weight: String
    let price: Double
    let currency: String
    let image: String
    let availability: Bool
    let createdAt: String
}

struct BranchGraphQL: Identifiable, Sendable {
    let id: String
    let businessId: String
    let name: String
    let address: String
    let coordinates: CoordinatesGraphQL
    let phone: String
    let status: String
    let createdAt: String
}
```

#### 2. ViewModel (`HomeViewModel.swift`)
```swift
import Foundation
import SwiftUI
import Combine

enum HomeViewState {
    case idle
    case loading
    case success
    case error(String)
}

@MainActor
class HomeViewModel: ObservableObject {
    @Published var state: HomeViewState = .idle
    @Published var products: [Product] = []
    @Published var stores: [Store] = []
    @Published var errorMessage: String?

    private let repository = HomeRepository()

    func loadHomeData() {
        state = .loading
        errorMessage = nil

        repository.fetchHomeData { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let homeData):
                    // Map to UI models
                    self.products = homeData.products.map { productGraphQL in
                        Product(
                            id: Int(productGraphQL.id.hashValue),
                            name: productGraphQL.name,
                            shop: "Store",
                            weight: productGraphQL.weight,
                            price: formatPrice(
                                price: productGraphQL.price,
                                currency: productGraphQL.currency
                            ),
                            imageUrl: productGraphQL.image
                        )
                    }

                    self.stores = homeData.branches.map { branchGraphQL in
                        Store(
                            id: branchGraphQL.id,
                            name: branchGraphQL.name,
                            etaMinutes: calculateETA(coordinates: branchGraphQL.coordinates),
                            logoUrl: defaultLogoUrl,
                            bannerUrl: defaultBannerUrl,
                            address: branchGraphQL.address,
                            rating: nil
                        )
                    }

                    self.state = .success

                case .failure(let error):
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    self.state = .error(errorMessage!)
                }
            }
        }
    }
}
```

#### 3. View (`HomeView.swift`)
```swift
import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var currentLocation = "Calle 23, Vedado, La Habana"

    var body: some View {
        ZStack {
            Color.llegoBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HomeHeaderExample(location: $currentLocation)

                    // Promo Section
                    PromoSection()

                    // Products
                    if !viewModel.products.isEmpty {
                        ProductSection(products: viewModel.products)
                    }

                    // Stores
                    if !viewModel.stores.isEmpty {
                        StoreSection(stores: viewModel.stores)
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadHomeData()
        }
    }
}
```

### Ejemplo: ProductDetailView

#### `ProductRepository.swift`
```swift
import Foundation
import Apollo

class ProductRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    func fetchProducts(completion: @escaping @Sendable (Result<[ProductGraphQL], Error>) -> Void) {
        apolloClient.fetch(
            query: LlegoAPI.GetProductsQuery(),
            cachePolicy: .returnCacheDataAndFetch
        ) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    completion(.failure(NSError(domain: "GraphQL", code: -1)))
                    return
                }

                guard let products = graphQLResult.data?.products else {
                    completion(.success([]))
                    return
                }

                let mappedProducts = products.map { product in
                    ProductGraphQL(
                        id: product.id,
                        branchId: product.branchId,
                        name: product.name,
                        description: product.description,
                        weight: product.weight,
                        price: product.price,
                        currency: product.currency,
                        image: product.image,
                        availability: product.availability,
                        createdAt: product.createdAt
                    )
                }

                completion(.success(mappedProducts))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

struct ProductGraphQL: Identifiable, Sendable {
    let id: String
    let branchId: String
    let name: String
    let description: String
    let weight: String
    let price: Double
    let currency: String
    let image: String
    let availability: Bool
    let createdAt: String
}
```

### Pantallas Implementadas

1. **[HomeView.swift](LlegoiOS/ui/screens/Home/HomeView.swift)** - Pantalla principal con productos y tiendas
2. **[ProductDetailView.swift](LlegoiOS/ui/screens/ProductDetail/ProductDetailView.swift)** - Detalle de producto
3. **[CategoriesView.swift](LlegoiOS/ui/screens/Categories/CategoriesView.swift)** - Categorías de productos
4. **[CartView.swift](LlegoiOS/ui/screens/Cart/CartView.swift)** - Carrito de compras
5. **[CheckoutView.swift](LlegoiOS/ui/screens/Checkout/CheckoutView.swift)** - Proceso de pago
6. **[StoreDetailView.swift](LlegoiOS/ui/screens/StoreDetail/StoreDetailView.swift)** - Detalle de tienda
7. **[SearchView.swift](LlegoiOS/ui/screens/Search/SearchView.swift)** - Búsqueda de productos
8. **[ProfileView.swift](LlegoiOS/ui/screens/Profile/ProfileView.swift)** - Perfil de usuario
9. **[LocationPickerView.swift](LlegoiOS/ui/screens/LocationPicker/LocationPickerView.swift)** - Selección de ubicación
10. **[OnboardingView.swift](LlegoiOS/ui/screens/Onboarding/OnboardingView.swift)** - Onboarding inicial
11. **[PlansAndPricingView.swift](LlegoiOS/ui/screens/PlansAndPricing/PlansAndPricingView.swift)** - Planes de suscripción
12. **[LiveOrderTrackingView.swift](LlegoiOS/ui/screens/LiveOrderTracking/LiveOrderTrackingView.swift)** - Seguimiento en vivo
13. **[OrderConfirmationView.swift](LlegoiOS/ui/screens/OrderConfirmation/OrderConfirmationView.swift)** - Confirmación de pedido

---

## Sistema de Diseño (Theme)

### Paleta de Colores (`Theme.swift`)

```swift
struct LlegoTheme {
    // Colores primarios
    static let primaryColor = Color(red: 2/255, green: 49/255, blue: 51/255)
    static let onPrimaryColor = Color.white
    static let secondaryColor = Color(red: 225/255, green: 199/255, blue: 142/255)
    static let tertiaryColor = Color(red: 124/255, green: 65/255, blue: 43/255)
    static let backgroundColor = Color(red: 243/255, green: 243/255, blue: 243/255)
    static let surfaceColor = Color.white
    static let accentColor = Color(red: 178/255, green: 214/255, blue: 154/255)
    static let buttonColor = Color(red: 90/255, green: 132/255, blue: 103/255)
}

extension Color {
    static let llegoPrimary = LlegoTheme.primaryColor
    static let llegoOnPrimary = LlegoTheme.onPrimaryColor
    static let llegoSecondary = LlegoTheme.secondaryColor
    static let llegoTertiary = LlegoTheme.tertiaryColor
    static let llegoBackground = LlegoTheme.backgroundColor
    static let llegoSurface = LlegoTheme.surfaceColor
    static let llegoAccent = LlegoTheme.accentColor
    static let llegoButton = LlegoTheme.buttonColor
}
```

### Shapes Personalizados

- **[CurvedBottomShape.swift](LlegoiOS/ui/theme/shapes/CurvedBottomShape.swift)** - Forma curva inferior
- **[CounterControlsShape.swift](LlegoiOS/ui/theme/shapes/CounterControlsShape.swift)** - Controles de contador

---

## Modelos de Datos

### Modelos UI (`Models.swift`)

```swift
// Productos para UI
struct Product: Identifiable, Hashable {
    let id: Int
    let name: String
    let shop: String
    let weight: String
    let price: String
    let imageUrl: String
}

// Tiendas para UI
struct Store: Identifiable, Hashable {
    let id: String
    let name: String
    let etaMinutes: Int
    let logoUrl: String
    let bannerUrl: String
    let address: String
    let rating: Double?
}
```

---

## Helpers y Utilidades

### 1. ImageCache (`ImageCache.swift`)
Cache de imágenes con AsyncImage:
```swift
struct CachedAsyncImage<Content: View>: View {
    let url: URL?
    @ViewBuilder let content: (AsyncImagePhase) -> Content

    var body: some View {
        AsyncImage(url: url) { phase in
            content(phase)
        }
    }
}
```

### 2. LocationManager (`LocationManager.swift`)
Gestión de ubicación del usuario:
```swift
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus

    func requestPermission() { }
    func startUpdatingLocation() { }
}
```

### 3. PaymentManager (`PaymentManager.swift`)
Gestión de pagos (StoreKit):
```swift
class PaymentManager: ObservableObject {
    @Published var isPurchasing = false
    @Published var purchaseError: String?

    func purchasePlan(_ planType: PlanType) async { }
}
```

### 4. OnboardingHelper (`OnboardingHelper.swift`)
Estado de onboarding:
```swift
class OnboardingHelper: ObservableObject {
    @Published var hasSeenOnboarding: Bool
}
```

---

## Componentes UI

### Atomic Design Structure

#### Atoms (Componentes básicos)
- **[LlegoCartButton.swift](LlegoiOS/ui/components/atoms/LlegoCartButton.swift)** - Botón de carrito
- **[AddToCartOverlay.swift](LlegoiOS/ui/components/atoms/AddToCartOverlay.swift)** - Overlay de añadir al carrito
- **[AddToCartAnimation.swift](LlegoiOS/ui/components/atoms/AddToCartAnimation.swift)** - Animación de carrito
- **[CategoryItem.swift](LlegoiOS/ui/components/atoms/CategoryItem.swift)** - Item de categoría
- **[PositionObserver.swift](LlegoiOS/ui/components/atoms/PositionObserver.swift)** - Observer de posición

#### Molecules (Componentes compuestos)
- **[ProductCard.swift](LlegoiOS/ui/components/molecules/ProductCard.swift)** - Tarjeta de producto
- **[StoreCard.swift](LlegoiOS/ui/components/molecules/StoreCard.swift)** - Tarjeta de tienda
- **[LlegoSearchBar.swift](LlegoiOS/ui/components/molecules/LlegoSearchBar.swift)** - Barra de búsqueda
- **[SubscriptionPromoCard.swift](LlegoiOS/ui/components/molecules/SubscriptionPromoCard.swift)** - Promo de suscripción
- **[FamilyPaymentPromoCard.swift](LlegoiOS/ui/components/molecules/FamilyPaymentPromoCard.swift)** - Promo familiar
- **[OrderTrackingCard.swift](LlegoiOS/ui/components/molecules/OrderTrackingCard.swift)** - Tracking de orden

#### Organisms (Componentes complejos)
- **[ProductSection.swift](LlegoiOS/ui/components/organisms/ProductSection.swift)** - Sección de productos
- **[StoreSection.swift](LlegoiOS/ui/components/organisms/StoreSection.swift)** - Sección de tiendas
- **[PromoSection.swift](LlegoiOS/ui/components/organisms/PromoSection.swift)** - Sección de promos
- **[HomeHeaderExample.swift](LlegoiOS/ui/components/organisms/HomeHeaderExample.swift)** - Header principal
- **[SemicircularSlider.swift](LlegoiOS/ui/components/organisms/SemicircularSlider.swift)** - Slider semicircular de categorías

#### Background
- **[CurvedBackground.swift](LlegoiOS/ui/components/background/CurvedBackground.swift)** - Fondo curvo

---

## Gestión de Estado

### Cache Policy
El proyecto usa `.returnCacheDataAndFetch` para todas las queries, permitiendo:
1. Mostrar datos cacheados inmediatamente
2. Actualizar con datos frescos del servidor
3. Funcionar offline con datos previos

### Estado de Views
Usando `@StateObject`, `@ObservedObject`, `@Published`:
```swift
@MainActor
class HomeViewModel: ObservableObject {
    @Published var state: HomeViewState = .idle
    @Published var products: [Product] = []
    @Published var stores: [Store] = []
}
```

---

## Flujo de Trabajo

### 1. Añadir una nueva Query

#### Paso 1: Crear archivo `.graphql`
```graphql
# GetStoreDetail.graphql
query GetStoreDetail($id: String!) {
  branch(id: $id) {
    id
    name
    address
    phone
    status
  }
}
```

#### Paso 2: Generar código Swift
```bash
npx apollo codegen:generate --config apollo-codegen-config.json --target swift
```

#### Paso 3: Crear Repository
```swift
// StoreDetailRepository.swift
class StoreDetailRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    func fetchStoreDetail(id: String, completion: @escaping (Result<StoreDetail, Error>) -> Void) {
        apolloClient.fetch(query: LlegoAPI.GetStoreDetailQuery(id: id)) { result in
            // Handle result
        }
    }
}
```

#### Paso 4: Crear ViewModel
```swift
@MainActor
class StoreDetailViewModel: ObservableObject {
    @Published var store: StoreDetail?
    private let repository = StoreDetailRepository()

    func loadStore(id: String) {
        repository.fetchStoreDetail(id: id) { result in
            // Update UI
        }
    }
}
```

### 2. Añadir una nueva Pantalla

1. Crear carpeta en `ui/screens/NombrePantalla/`
2. Crear archivos:
   - `NombrePantallaView.swift`
   - `NombrePantallaViewModel.swift`
   - `NombrePantallaRepository.swift` (si necesita datos)
3. Definir query GraphQL si es necesario
4. Conectar con navegación

---

## Best Practices

### 1. Estados de Carga con LottieView

**IMPORTANTE**: Siempre usar `LottieView` para indicadores de carga en lugar del `ProgressView` nativo de iOS.

```swift
// ❌ NO USAR ProgressView nativo
if viewModel.isLoading {
    ProgressView()
        .scaleEffect(1.5)
}

// ✅ USAR LottieView
if viewModel.isLoading {
    VStack(spacing: 20) {
        LottieView(name: "loading")
            .frame(width: 150, height: 150)
        Text("Cargando...")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.gray)
    }
}
```

**Ubicación del componente**: [`LottieView.swift`](LlegoiOS/ui/components/atoms/LottieView.swift)

**Uso básico**:
```swift
// Con archivo Lottie local
LottieView(name: "loading")
    .frame(width: 150, height: 150)

// Con archivo .lottie
LottieView(dotLottieName: "loading")
    .frame(width: 120, height: 120)

// Personalizado
LottieView(
    name: "loading",
    loopMode: .loop,
    contentMode: .scaleAspectFit,
    speed: 1.0
)
```

**Ejemplos implementados**:
- [`HomeView.swift`](LlegoiOS/ui/screens/Home/HomeView.swift) - Loading state con LottieView
- [`SearchView.swift`](LlegoiOS/ui/screens/Search/SearchView.swift) - Loading overlay con LottieView

### 2. Manejo de Errores GraphQL
```swift
if let errors = graphQLResult.errors {
    print("❌ GraphQL Errors:")
    errors.forEach { print("  - \($0.localizedDescription)") }
    completion(.failure(NSError(domain: "GraphQL", code: -1)))
    return
}
```

### 2. Cache Policy
Usar `.returnCacheDataAndFetch` para mejor UX:
```swift
apolloClient.fetch(
    query: LlegoAPI.GetHomeDataQuery(),
    cachePolicy: .returnCacheDataAndFetch
)
```

### 3. Threading con @MainActor
```swift
Task { @MainActor in
    // Update UI here
    self.products = mappedProducts
}
```

### 4. Sendable Compliance
Marcar closures y structs como `@Sendable`:
```swift
func fetchData(completion: @escaping @Sendable (Result<Data, Error>) -> Void)

struct MyData: Sendable {
    let id: String
}
```

### 5. Logging
```swift
print("✅ Fetched \(count) items from GraphQL")
print("❌ Error: \(error.localizedDescription)")
print("⚠️ No data received")
```

---

## Troubleshooting

### Regenerar Código Apollo
```bash
# 1. Limpiar archivos generados
rm -rf LlegoiOS/GraphQL/Operations

# 2. Regenerar
npx apollo codegen:generate --config apollo-codegen-config.json --target swift

# 3. Limpiar build en Xcode
Product → Clean Build Folder (Cmd + Shift + K)
```

### Actualizar Schema
```bash
# Descargar schema actualizado del backend
npx apollo schema:download \
  --endpoint=https://llegobackend-production.up.railway.app/graphql \
  schema.graphqls
```

### Errores Comunes

1. **"Cannot find LlegoAPI in scope"**
   - Regenerar código Apollo
   - Verificar que `embeddedInTarget` esté en config

2. **Cache no funciona**
   - Verificar que SQLiteNormalizedCache esté inicializado
   - Comprobar permisos de escritura

3. **Queries no se generan**
   - Verificar que `.graphql` esté en `operationSearchPaths`
   - Confirmar sintaxis GraphQL correcta

---

## Recursos

- **Backend GraphQL**: https://llegobackend-production.up.railway.app/graphql
- **Apollo iOS Docs**: https://www.apollographql.com/docs/ios/
- **SwiftUI**: https://developer.apple.com/documentation/swiftui

---

## Próximos Pasos

- [ ] Implementar mutations (crear pedidos, actualizar carrito)
- [ ] Añadir autenticación de usuarios
- [ ] Implementar subscriptions GraphQL para tracking en tiempo real
- [ ] Añadir tests unitarios para repositories
- [ ] Mejorar manejo de errores con retry logic
- [ ] Implementar paginación en listas de productos
- [ ] Añadir filtros y búsqueda avanzada

---

*Última actualización: Octubre 2024*
