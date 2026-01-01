# Implementación de Carga de Detalles con Indicador Nativo

## Archivos Creados

### Para Productos:
- **[ProductDetailRepository.swift](../LlegoiOS/ui/screens/ProductDetail/ProductDetailRepository.swift)**: Repository que usa `GetProductDetailQuery` para cargar detalles completos
- **[ProductDetailViewModel.swift](../LlegoiOS/ui/screens/ProductDetail/ProductDetailViewModel.swift)**: ViewModel con estados de carga (`idle`, `loading`, `success`, `error`)

### Para Tiendas:
- **[StoreDetailRepository.swift](../LlegoiOS/ui/screens/StoreDetail/StoreDetailRepository.swift)**: Repository que usa `GetBranchDetailQuery` para cargar detalles completos
- **[StoreDetailViewModel.swift](../LlegoiOS/ui/screens/StoreDetail/StoreDetailViewModel.swift)**: ViewModel con estados de carga

---

## Ejemplo 1: ProductDetailView con Carga de Detalles

```swift
import SwiftUI

struct ProductDetailView: View {
    let productId: String  // Solo recibe el ID ahora

    @StateObject private var viewModel = ProductDetailViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            CurvedBackground(
                curveStartAbsolute: 170,
                curveEndAbsolute: 170,
                curveInclinationAbsolute: 50,
                invertCurve: true
            ) {
                // INDICADOR DE CARGA NATIVO
                if viewModel.isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.llegoPrimary)

                        Text("Cargando detalles...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // ERROR STATE
                else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)

                        Text(errorMessage)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()

                        Button("Reintentar") {
                            viewModel.loadProductDetail(id: productId)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.llegoPrimary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // SUCCESS STATE - Mostrar detalles completos
                else if let productDetail = viewModel.productDetail {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Product Image
                            AsyncImage(url: URL(string: productDetail.imageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(height: 300)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 300)
                                case .failure:
                                    Image(systemName: "photo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 300)
                                        .foregroundColor(.gray)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .padding(.top, 20)

                            // Product Details (ahora con description y weight completos)
                            HStack(alignment: .top, spacing: 16) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(productDetail.name)
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.black)

                                    // PESO COMPLETO (ahora disponible)
                                    Text(productDetail.weight)
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)

                                    // DESCRIPCIÓN COMPLETA (ahora disponible)
                                    Text(productDetail.description)
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                        .lineLimit(nil)

                                    Spacer()
                                }

                                Spacer()

                                // Price
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(viewModel.formatPrice(
                                        price: productDetail.price,
                                        currency: productDetail.currency
                                    ))
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.llegoPrimary)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.black)
                }
            }
        }
        .onAppear {
            // CARGAR DETALLES CUANDO APARECE LA VISTA
            viewModel.loadProductDetail(id: productId)
        }
    }
}
```

---

## Ejemplo 2: StoreDetailView con Carga de Detalles

```swift
import SwiftUI

struct StoreDetailView: View {
    let storeId: String  // Solo recibe el ID ahora

    @StateObject private var viewModel = StoreDetailViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.llegoBackground.ignoresSafeArea()

            // INDICADOR DE CARGA NATIVO
            if viewModel.isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.llegoPrimary)

                    Text("Cargando información...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // ERROR STATE
            else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.red)

                    Text(errorMessage)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()

                    Button("Reintentar") {
                        viewModel.loadBranchDetail(id: storeId)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.llegoPrimary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // SUCCESS STATE - Mostrar detalles completos
            else if let branchDetail = viewModel.branchDetail {
                ScrollView {
                    VStack(spacing: 20) {
                        // Banner
                        AsyncImage(url: URL(string: viewModel.getBannerUrl())) { image in
                            image.resizable()
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()

                        VStack(alignment: .leading, spacing: 16) {
                            // Logo + Name
                            HStack(spacing: 12) {
                                AsyncImage(url: URL(string: viewModel.getLogoUrl())) { image in
                                    image.resizable()
                                } placeholder: {
                                    Color.gray.opacity(0.3)
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(branchDetail.name)
                                        .font(.system(size: 24, weight: .bold))

                                    if let address = branchDetail.address {
                                        Text(address)
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }

                            // Phone
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.llegoPrimary)
                                Text(branchDetail.phone)
                                    .font(.system(size: 16))
                            }

                            // ETA
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.llegoAccent)
                                Text("\(viewModel.calculateETA(deliveryRadius: branchDetail.deliveryRadius)) min")
                                    .font(.system(size: 16))
                            }

                            // FACILITIES (ahora disponibles)
                            if let facilities = branchDetail.facilities, !facilities.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Facilidades")
                                        .font(.system(size: 18, weight: .semibold))

                                    ForEach(facilities, id: \.self) { facility in
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                            Text(facility)
                                                .font(.system(size: 15))
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // CARGAR DETALLES CUANDO APARECE LA VISTA
            viewModel.loadBranchDetail(id: storeId)
        }
    }
}
```

---

## Ejemplo 3: Navegación desde Lista a Detalle

```swift
// En HomeView o cualquier lista de productos
ForEach(products) { product in
    NavigationLink(value: product.id) {
        ProductCard(
            product: product,
            count: $count,
            onIncrement: { },
            onDecrement: { }
        )
    }
}
.navigationDestination(for: String.self) { productId in
    // Pasa solo el ID, el ViewModel carga los detalles
    ProductDetailView(productId: productId)
}
```

---

## Beneficios de esta Implementación

1. **Performance Optimizado**
   - Listados cargan solo datos mínimos (rápidos)
   - Detalles se cargan bajo demanda (cuando el usuario hace clic)

2. **UX Mejorado**
   - `ProgressView()` nativo muestra estado de carga
   - Estados de error con botón de reintentar
   - Transiciones suaves

3. **Queries Optimizadas**
   - `GetProducts`: Solo campos para listado
   - `GetProductDetail`: Campos completos (description, weight, etc.)
   - `GetBranches`: Solo campos para listado
   - `GetBranchDetail`: Campos completos (facilities, etc.)

4. **Arquitectura Limpia**
   - Separation of Concerns: Repository → ViewModel → View
   - Estados bien definidos: `idle`, `loading`, `success`, `error`
   - Testeable y mantenible

---

## Estados del ViewModel

### ProductDetailViewModel / StoreDetailViewModel

```swift
enum ProductDetailState {
    case idle        // Estado inicial
    case loading     // Cargando detalles del servidor
    case success(ProductDetailGraphQL)  // Detalles cargados correctamente
    case error(String)  // Error al cargar
}
```

### Propiedades Computadas

```swift
var isLoading: Bool {
    if case .loading = state { return true }
    return false
}

var errorMessage: String? {
    if case .error(let message) = state { return message }
    return nil
}
```

---

## Queries GraphQL Optimizadas

### Listados (Rápidos)
- **GetProducts**: `id`, `branchId`, `name`, `price`, `currency`, `imageUrl`, `availability`
- **GetBranches**: `id`, `name`, `address`, `coordinates`, `phone`, `status`, `avatarUrl`, `coverUrl`, `deliveryRadius`

### Detalles (Completos)
- **GetProductDetail**: Incluye `description`, `weight`, `categoryId`
- **GetBranchDetail**: Incluye `facilities` (lista de servicios disponibles)

---

## Testing

```swift
// Test del ViewModel
func testLoadProductDetail() async {
    let viewModel = ProductDetailViewModel()

    // Estado inicial
    XCTAssertTrue(case .idle = viewModel.state)

    // Cargar detalles
    viewModel.loadProductDetail(id: "test-id")

    // Debe pasar a loading
    XCTAssertTrue(viewModel.isLoading)

    // Esperar respuesta...
    try? await Task.sleep(nanoseconds: 1_000_000_000)

    // Verificar success o error
    XCTAssertFalse(viewModel.isLoading)
}
```
