import SwiftUI
import MapKit

struct StoreDetailView: View {
    // Support both: passing full Store OR just storeId
    let initialStore: Store?
    let storeId: String

    @StateObject private var viewModel = StoreDetailViewModel()
    @StateObject private var branchLikesManager = BranchLikesManager.shared
    @ObservedObject private var gradientManager = GradientStateManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var region: MKCoordinateRegion
    @State private var selectedProductId: String?
    @State private var selectedComboId: String?
    @State private var selectedShowcase: ShowcaseGraphQL?
    @State private var showShowcaseAddedToast: Bool = false
    @State private var extractedStoreGradient: ExtractedGradient = .placeholder
    @State private var hasExtractedStoreGradient: Bool = false

    // Default images - Empty strings to trigger AsyncImage failure -> shows generic assets
    private let defaultLogoUrl = ""
    private let defaultBannerUrl = ""

    // Helper functions
    private func calculateETA(deliveryRadius: Double?) -> Int {
        guard let radius = deliveryRadius else { return 20 }
        return Int(radius * 5 + 10)
    }

    // Secciones que ya no se usan se eliminan para limpiar el código
    /*
    @ViewBuilder
    private var currencyBadgeIfNeeded: some View { ... }
    
    @ViewBuilder
    private var scheduleStatusBadge: some View { ... }
    */

    private var scheduleStatus: BranchOpenStatus? {
        viewModel.branchDetail?.schedule?.currentStatus()
    }

    @ViewBuilder
    private var scheduleSection: some View {
        if let schedule = viewModel.branchDetail?.schedule {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    sectionHeader(
                        icon: "clock.fill",
                        title: "Horario",
                        subtitle: "Días y horas de atención"
                    )
                    Spacer()
                    if let status = scheduleStatus {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(status.isOpen ? Color.green : Color.red)
                                .frame(width: 7, height: 7)
                            Text(status.label)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(status.isOpen ? Color.green : Color.red)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill((status.isOpen ? Color.green : Color.red).opacity(0.1))
                        )
                    }
                }

                if let ts = schedule.temporaryStatus {
                    if ts.temporallyClosed {
                        HStack(spacing: 8) {
                            Image(systemName: "moon.zzz.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                            Text(ts.reason ?? "Temporalmente cerrado")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.orange)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.orange.opacity(0.1))
                        )
                    } else if ts.temporallyOpen {
                        HStack(spacing: 8) {
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                            Text(ts.reason ?? "Abierto excepcionalmente")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.green)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.green.opacity(0.1))
                        )
                    }
                }

                let todayIndex = Calendar.current.component(.weekday, from: Date()) - 1
                let sortedDays = schedule.days.sorted { $0.day < $1.day }
                VStack(spacing: 0) {
                    ForEach(Array(sortedDays.enumerated()), id: \.element.day) { index, day in
                        scheduleRow(day: day, isToday: day.day == todayIndex)
                        if index < sortedDays.count - 1 {
                            Divider().padding(.leading, 14)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
            }
            .padding(.horizontal, 20)
        }
    }

    private func scheduleRow(day: DaySchedule, isToday: Bool) -> some View {
        let dayNames = ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"]
        let name = day.day < dayNames.count ? dayNames[day.day] : "Día \(day.day)"
        let accent = gradientManager.currentAccentColor
        return HStack(spacing: 10) {
            Text(name)
                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? .primary : .secondary)
                .frame(width: 36, alignment: .leading)
            if isToday {
                Text("Hoy")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(accent.opacity(0.12)))
            }
            Spacer()
            if !day.isOpen || day.hours.isEmpty {
                Text("Cerrado")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.red.opacity(0.7))
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    ForEach(Array(day.hours.enumerated()), id: \.offset) { _, range in
                        Text("\(range.open) – \(range.close)")
                            .font(.system(size: 13, weight: isToday ? .semibold : .regular))
                            .foregroundColor(isToday ? .primary : .secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isToday ? accent.opacity(0.05) : Color.clear)
    }

    @ViewBuilder
    private func currencyBadge(currency: String, exchangeRate: Int?) -> some View {
        let style = currencyBadgeStyle(currency: currency)
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Image(systemName: style.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(style.iconColor)
                Text(style.label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(style.textColor)
            }
            if currency.uppercased() == "BOTH", let rate = exchangeRate {
                Text("1 USD = \(rate) CUP")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(style.secondaryTextColor)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(style.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(style.border, lineWidth: 1)
                )
        )
    }

    private func currencyBadgeStyle(currency: String) -> (
        label: String,
        icon: String,
        background: Color,
        border: Color,
        textColor: Color,
        secondaryTextColor: Color,
        iconColor: Color
    ) {
        switch currency.uppercased() {
        case "USD":
            return (
                "Solo USD",
                "dollarsign.circle.fill",
                Color.green.opacity(0.1),
                Color.green.opacity(0.3),
                Color.green.opacity(0.9),
                Color.green.opacity(0.75),
                Color.green
            )
        case "CUP":
            return (
                "Solo CUP",
                "coloncurrencysign.circle.fill",
                Color.orange.opacity(0.11),
                Color.orange.opacity(0.3),
                Color.orange.opacity(0.9),
                Color.orange.opacity(0.8),
                Color.orange
            )
        case "BOTH":
            return (
                "USD y CUP",
                "arrow.left.arrow.right.circle.fill",
                gradientManager.currentAccentColor.opacity(0.08),
                gradientManager.currentAccentColor.opacity(0.25),
                gradientManager.currentAccentColor,
                gradientManager.currentAccentColor.opacity(0.75),
                gradientManager.currentAccentColor
            )
        default:
            return (
                currency,
                "creditcard.circle.fill",
                Color.gray.opacity(0.1),
                Color.gray.opacity(0.25),
                Color.gray,
                Color.gray.opacity(0.75),
                Color.gray
            )
        }
    }

    private func formatPrice(price: Double, currency: String) -> String {
        let symbol: String
        switch currency.uppercased() {
        case "USD":
            symbol = "$"
        case "EUR":
            symbol = "€"
        case "CUP":
            symbol = "₱"
        default:
            symbol = currency
        }
        return "\(symbol)\(String(format: "%.2f", price))"
    }

    // Computed property to get current store (prefer viewModel data when available)
    private var store: Store? {
        // Prioritize fresh data from ViewModel if available
        if let detail = viewModel.branchDetail {
            return Store(
                id: detail.id,
                name: detail.name,
                etaMinutes: viewModel.calculateETA(deliveryRadius: detail.deliveryRadius),
                logoUrl: viewModel.getLogoUrl(),
                bannerUrl: viewModel.getBannerUrl(),
                address: detail.address,
                rating: nil
            )
        }

        // Fallback to initial store while loading
        if let initial = initialStore {
            return initial
        }

        return nil
    }

    private var gradientSourceURL: URL? {
        if let logoUrl = store?.logoUrl,
           !logoUrl.isEmpty,
           let url = URL(string: logoUrl) {
            return url
        }
        return nil
    }

    private var resolvedStoreGradient: ExtractedGradient? {
        hasExtractedStoreGradient ? extractedStoreGradient : nil
    }

    // Initializer that accepts full Store (existing code compatibility)
    init(store: Store) {
        self.initialStore = store
        self.storeId = store.id
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 4.6097, longitude: -74.0817),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    // New initializer that accepts only ID (will load details)
    init(storeId: String) {
        self.initialStore = nil
        self.storeId = storeId
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 4.6097, longitude: -74.0817),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        NavigationStack{
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    Color.llegoSurface.ignoresSafeArea()

                    GradientAsyncBackground(
                        url: gradientSourceURL,
                        cacheKey: "store_detail_logo_\(storeId)",
                        gradient: $extractedStoreGradient
                    )
                    .frame(width: 0, height: 0)
                    .opacity(0.001)
                    .allowsHitTesting(false)
                    .id(gradientSourceURL?.absoluteString ?? "no-store-gradient-source")

                    // LOADING STATE - Indicador nativo
                    if initialStore == nil && viewModel.isLoading {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(gradientManager.currentAccentColor)

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
                            .tint(gradientManager.currentAccentColor)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    // SUCCESS STATE - Show store details
                    else if let store = store {
                        ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Banner and Profile Section
                            ZStack(alignment: .bottomLeading) {
                                // Cover photo: full width, fixed height, always cropped to fill
                                GeometryReader { bannerGeo in
                                    AsyncImage(url: URL(string: store.bannerUrl)) { phase in
                                        switch phase {
                                        case .empty:
                                            ZStack {
                                                Color.gray.opacity(0.15)
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .llegoPrimary))
                                                    .scaleEffect(1.5)
                                            }
                                            .frame(width: bannerGeo.size.width, height: 260)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: bannerGeo.size.width, height: 260)
                                                .clipped()
                                        case .failure:
                                            Color.gray.opacity(0.15)
                                                .frame(width: bannerGeo.size.width, height: 260)
                                        @unknown default:
                                            Color.gray.opacity(0.15)
                                                .frame(width: bannerGeo.size.width, height: 260)
                                        }
                                    }
                                }
                                .frame(height: 260)

                                LinearGradient(
                                    colors: [Color.clear, Color.black.opacity(0.3)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 260)

                                AsyncImage(url: URL(string: store.logoUrl)) { phase in
                                    switch phase {
                                    case .empty:
                                        ZStack {
                                            Circle()
                                                .fill(Color.white)
                                            CircularLoadingIndicator(color: .llegoPrimary, lineWidth: 4, size: 30, useHDR: true)
                                        }
                                        .frame(width: 110, height: 110)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 5)
                                        )
                                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 3)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 110, height: 110)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 5)
                                            )
                                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 3)
                                    case .failure:
                                        ZStack {
                                            Circle().fill(Color.gray.opacity(0.15))
                                            Image(systemName: "storefront")
                                                .font(.system(size: 32))
                                                .foregroundColor(.gray.opacity(0.5))
                                        }
                                        .frame(width: 110, height: 110)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 5)
                                        )
                                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 3)
                                    @unknown default:
                                        ZStack {
                                            Circle().fill(Color.gray.opacity(0.15))
                                            Image(systemName: "storefront")
                                                .font(.system(size: 32))
                                                .foregroundColor(.gray.opacity(0.5))
                                        }
                                        .frame(width: 110, height: 110)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 5)
                                        )
                                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 3)
                                    }
                                }
                                .padding(.leading, 20)
                                .offset(y: 55)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 75) // Restaurar el padding bottom original para que el contenido baje

                            // Main Content
                            VStack(alignment: .leading, spacing: 32) {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack(alignment: .top, spacing: 12) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(store.name)
                                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                                .foregroundColor(.primary)
                                                .lineLimit(2)

                                            if let address = store.address {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "mappin.circle.fill")
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .foregroundColor(gradientManager.currentAccentColor)
                                                    Text(address)
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                }
                                            }
                                        }

                                        Spacer()

                                        if let rating = store.rating {
                                            HStack(spacing: 4) {
                                                Image(systemName: "star.fill")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.yellow)
                                                Text(String(format: "%.1f", rating))
                                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                                    .foregroundColor(.primary)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(Color.yellow.opacity(0.15))
                                            )
                                        }
                                    }

                                    HStack(spacing: 12) {
                                        // Tiempo de entrega (Estilo minimalista oscuro)
                                        HStack(spacing: 6) {
                                            Image(systemName: "clock.fill")
                                                .font(.system(size: 11, weight: .semibold))
                                            Text("\(store.etaMinutes) min")
                                                .font(.system(size: 13, weight: .bold))
                                        }
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.black.opacity(0.05))
                                        .clipShape(Capsule())

                                        // Estado del horario
                                        if let status = scheduleStatus {
                                            HStack(spacing: 6) {
                                                Circle()
                                                    .fill(status.isOpen ? Color.green : Color.red)
                                                    .frame(width: 6, height: 6)
                                                Text(status.label)
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(status.isOpen ? Color.green : Color.red)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .strokeBorder((status.isOpen ? Color.green : Color.red).opacity(0.3), lineWidth: 1)
                                                    .background(Capsule().fill((status.isOpen ? Color.green : Color.red).opacity(0.05)))
                                            )
                                        }

                                        // Moneda
                                        if let currency = viewModel.branchDetail?.acceptedCurrency {
                                            let style = currencyBadgeStyle(currency: currency)
                                            HStack(spacing: 4) {
                                                Text(style.label)
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.primary)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
                                                    .background(Capsule().fill(Color.white))
                                            )
                                        }

                                        // Solo catálogo
                                        if viewModel.branchDetail?.catalogOnly == true {
                                            HStack(spacing: 5) {
                                                Image(systemName: "eye.fill")
                                                    .font(.system(size: 11, weight: .semibold))
                                                Text("Solo catálogo")
                                                    .font(.system(size: 12, weight: .bold))
                                            }
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Capsule().fill(Color.llegoPrimary))
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)

                                Divider()
                                    .padding(.horizontal, 20)

                                scheduleSection

                                if let socialMedia = viewModel.socialMedia, !socialMedia.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Divider()
                                            .padding(.horizontal, 20)

                                        VStack(alignment: .leading, spacing: 12) {
                                            sectionHeader(
                                                icon: "person.2.fill",
                                                title: "Conéctate con nosotros",
                                                subtitle: "Canales oficiales de esta tienda"
                                            )

                                            HStack(spacing: 12) {
                                                if let instagramUrl = viewModel.getSocialMediaUrl(for: "instagram") {
                                                    SocialButton(
                                                        iconAsset: "Instagram",
                                                        title: "Instagram",
                                                        gradient: [Color.pink, Color.purple, Color.orange],
                                                        url: instagramUrl
                                                    )
                                                }

                                                if let facebookUrl = viewModel.getSocialMediaUrl(for: "facebook") {
                                                    SocialButton(
                                                        iconAsset: "Facebook",
                                                        title: "Facebook",
                                                        color: Color.blue,
                                                        url: facebookUrl
                                                    )
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 16) {
                                    Divider()
                                        .padding(.horizontal, 20)

                                    VStack(alignment: .leading, spacing: 12) {
                                        sectionHeader(
                                            icon: "map.fill",
                                            title: "Ubicación",
                                            subtitle: "Dirección de la sucursal"
                                        )

                                        if viewModel.hasCoordinates,
                                           let coordinates = viewModel.branchDetail?.coordinates {
                                            Map(position: mapPositionBinding) {
                                                Marker("", coordinate: CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude))
                                            }
                                            .frame(height: 200)
                                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                            )
                                            .onAppear {
                                                region = MKCoordinateRegion(
                                                    center: CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude),
                                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                                )
                                            }
                                        } else {
                                            VStack(spacing: 10) {
                                                Image(systemName: "map")
                                                    .font(.system(size: 30, weight: .medium))
                                                    .foregroundColor(.secondary.opacity(0.7))
                                                Text("Sin ubicación disponible")
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundColor(.secondary)
                                                Text("Esta tienda aún no ha configurado su ubicación")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.secondary.opacity(0.85))
                                            }
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 170)
                                            .background(Color.black.opacity(0.03))
                                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }

                                if !viewModel.siblingBranches.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Divider()
                                            .padding(.horizontal, 20)

                                        VStack(alignment: .leading, spacing: 14) {
                                            sectionHeader(
                                                icon: "building.2.fill",
                                                title: "Otras sedes",
                                                subtitle: "Más sucursales del negocio"
                                            )
                                            .padding(.horizontal, 20)

                                            if viewModel.isLoadingSiblings {
                                                HStack {
                                                    Spacer()
                                                    ProgressView()
                                                        .padding(.vertical, 12)
                                                    Spacer()
                                                }
                                            } else {
                                                ScrollView(.horizontal, showsIndicators: false) {
                                                    HStack(spacing: 12) {
                                                        ForEach(viewModel.siblingBranches, id: \.id) { branch in
                                                            NavigationLink(destination: StoreDetailView(storeId: branch.id)) {
                                                                SiblingBranchCard(
                                                                    branch: branch,
                                                                    eta: calculateETA(deliveryRadius: branch.deliveryRadius)
                                                                )
                                                            }
                                                            .buttonStyle(.plain)
                                                        }
                                                    }
                                                    .padding(.horizontal, 20)
                                                    .padding(.bottom, 6)
                                                }
                                            }
                                        }
                                    }
                                }

                                if !viewModel.similarBranches.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Divider()
                                            .padding(.horizontal, 20)

                                        VStack(alignment: .leading, spacing: 14) {
                                            sectionHeader(
                                                icon: "sparkles",
                                                title: "Tiendas similares",
                                                subtitle: "Negocios con oferta parecida"
                                            )
                                            .padding(.horizontal, 20)

                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 12) {
                                                    ForEach(viewModel.similarBranches, id: \.id) { branch in
                                                        NavigationLink(destination: StoreDetailView(storeId: branch.id)) {
                                                            SiblingBranchCard(
                                                                branch: branch,
                                                                eta: calculateETA(deliveryRadius: branch.deliveryRadius)
                                                            )
                                                        }
                                                        .buttonStyle(.plain)
                                                    }
                                                }
                                                .padding(.horizontal, 20)
                                                .padding(.bottom, 6)
                                            }
                                        }
                                    }
                                }

                                if viewModel.isLoadingCombos || !viewModel.branchCombos.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Divider()
                                            .padding(.horizontal, 20)
                                        combosSection(store: store)
                                    }
                                }

                                if !viewModel.branchShowcases.isEmpty && viewModel.branchDetail?.catalogOnly != true {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Divider()
                                            .padding(.horizontal, 20)
                                        showcasesSection()
                                    }
                                }

                                if viewModel.isLoadingProducts || !viewModel.branchProducts.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Divider()
                                            .padding(.horizontal, 20)

                                        VStack(alignment: .leading, spacing: 14) {
                                            HStack {
                                                sectionHeader(
                                                    icon: "bag.fill",
                                                    title: "Productos",
                                                    subtitle: "\(viewModel.branchProducts.count) disponibles"
                                                )
                                                Spacer()
                                                NavigationLink(destination: ProductListView(branchId: storeId, branchName: store.name, storeGradient: resolvedStoreGradient, catalogOnly: viewModel.branchDetail?.catalogOnly ?? false)) {
                                                    HStack(spacing: 4) {
                                                        Text("Ver todos")
                                                            .font(.system(size: 13, weight: .semibold))
                                                        Image(systemName: "chevron.right")
                                                            .font(.system(size: 11, weight: .bold))
                                                    }
                                                    .foregroundColor(gradientManager.currentAccentColor)
                                                }
                                            }
                                            .padding(.horizontal, 20)

                                            if viewModel.isLoadingProducts {
                                                HStack {
                                                    Spacer()
                                                    ProgressView()
                                                        .padding(.vertical, 14)
                                                    Spacer()
                                                }
                                            } else {
                                                LazyVGrid(
                                                    columns: [
                                                        GridItem(.flexible(), spacing: 14),
                                                        GridItem(.flexible(), spacing: 14),
                                                    ],
                                                    spacing: 18
                                                ) {
                                                    ForEach(Array(viewModel.branchProducts.prefix(4)), id: \.id) { product in
                                                        ProductCard(
                                                            product: Product(
                                                                id: product.id,
                                                                name: product.name,
                                                                shop: store.name,
                                                                weight: "",
                                                                price: formatPrice(price: product.price, currency: product.currency),
                                                                imageUrl: product.imageUrl
                                                            ),
                                                            count: .constant(0),
                                                            onIncrement: {},
                                                            onDecrement: {},
                                                            onProductTap: {
                                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                                selectedProductId = product.id
                                                            }
                                                        )
                                                    }
                                                }
                                                .padding(.horizontal, 20)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 40)
                            .frame(maxWidth: .infinity)
                            .background(Color.llegoSurface) // Quitar la hoja blanca
                        }
                        }
                        .ignoresSafeArea(edges: .top)
                    } // End of else if let store
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .tabBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButton(action: {
                        dismiss()
                    })
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        toggleBranchLike()
                    }) {
                        ZStack(alignment: .bottomTrailing) {
                            Image(systemName: branchLikesManager.isLiked(branchId: storeId) ? "heart.fill" : "heart")
                                .font(.system(size: 17, weight: .semibold))
                            if !branchLikesManager.isLiked(branchId: storeId) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .background(Circle().fill(Color.white))
                                    .offset(x: 2, y: 2)
                            }
                        }
                        .foregroundColor(gradientManager.currentAccentColor)
                    }
                    .accessibilityLabel(
                        branchLikesManager.isLiked(branchId: storeId)
                            ? "Quitar de favoritos" : "Agregar a favoritos"
                    )
                    .accessibilityHint("Este botón agrega o quita este negocio de favoritos")
                }
            }
            .onAppear {
                // ALWAYS load full details from backend, even if we have initialStore
                // This ensures we get products, siblings, business info, etc.
                viewModel.loadBranchDetail(id: storeId)
            }
            .onChange(of: extractedStoreGradient) { _, _ in
                if gradientSourceURL != nil {
                    hasExtractedStoreGradient = true
                }
            }
            .onChange(of: gradientSourceURL?.absoluteString) { _, newValue in
                hasExtractedStoreGradient = newValue != nil
            }
            .fullScreenCover(item: $selectedProductId) { productId in
                ProductDetailView(productId: productId, catalogOnly: viewModel.branchDetail?.catalogOnly ?? false)
            }
            .fullScreenCover(item: $selectedComboId) { comboId in
                ComboDetailView(comboId: comboId)
            }
            .sheet(item: $selectedShowcase) { showcase in
                ShowcaseOrderSheet(
                    showcase: showcase,
                    branchId: storeId,
                    branchName: store?.name ?? "Tienda"
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        showShowcaseAddedToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showShowcaseAddedToast = false
                        }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if showShowcaseAddedToast {
                    Text("Se agregó el pedido de vitrina al carrito")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.black.opacity(0.85)))
                        .padding(.bottom, 18)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private var mapPositionBinding: Binding<MapCameraPosition> {
        Binding(
            get: { .region(region) },
            set: { newPosition in
                _ = newPosition
            }
        )
    }

    private func sectionHeader(icon: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(gradientManager.currentAccentColor)
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    private func infoPill(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(tint.opacity(0.12))
        )
    }

    @ViewBuilder
    private func showcasesSection() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                icon: "sparkles.rectangle.stack.fill",
                title: "Vitrinas",
                subtitle: "Pide por descripción manual"
            )
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.branchShowcases, id: \.id) { showcase in
                        VStack(alignment: .leading, spacing: 10) {
                            AsyncImage(url: URL(string: showcase.imageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    ZStack {
                                        Color.gray.opacity(0.12)
                                        ProgressView()
                                    }
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure:
                                    ZStack {
                                        Color.gray.opacity(0.15)
                                        Image(systemName: "photo")
                                            .font(.system(size: 22, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                @unknown default:
                                    Color.gray.opacity(0.12)
                                }
                            }
                            .frame(width: 264, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            Text(showcase.title)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                                .lineLimit(2)

                            if let description = showcase.description, !description.isEmpty {
                                Text(description)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }

                            if let items = showcase.items, !items.isEmpty {
                                Text("\(min(items.count, 3)) items sugeridos")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(gradientManager.currentAccentColor)
                            } else {
                                Text("Pide por descripción libre")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(gradientManager.currentAccentColor)
                            }

                            Button(action: {
                                selectedShowcase = showcase
                            }) {
                                Text("Pedir desde vitrina")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(gradientManager.currentAccentColor)
                                    )
                            }
                        }
                        .padding(12)
                        .frame(width: 286, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 20)
                .frame(height: 292)
            }
        }
    }

    // MARK: - Combos Section

    @ViewBuilder
    private func combosSection(store: Store) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                icon: "shippingbox.fill",
                title: "Combos especiales",
                subtitle: !viewModel.branchCombos.isEmpty
                    ? "\(viewModel.branchCombos.count) \(viewModel.branchCombos.count == 1 ? "combo disponible" : "combos disponibles")"
                    : "Cargando combos"
            )
            .padding(.horizontal, 20)

            if viewModel.isLoadingCombos {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, 12)
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.branchCombos) { combo in
                            ComboCard(
                                combo: Combo(
                                    id: combo.id,
                                    name: combo.name,
                                    description: combo.description,
                                    imageUrl: combo.imageUrl,
                                    shop: combo.branchName,
                                    shopLogoUrl: combo.branchLogoUrl ?? "",
                                    finalPrice: combo.finalPrice,
                                    savings: combo.savings,
                                    startingFinalPrice: combo.startingFinalPrice,
                                    startingSavings: combo.startingSavings,
                                    currency: combo.currency,
                                    discountType: combo.discountType,
                                    discountValue: combo.discountValue,
                                    slotCount: combo.slots.count,
                                    giftOptionsCount: combo.giftOptions.count,
                                    hasFreeSlots: combo.hasFreeSlots,
                                    representativeImageUrls: combo.representativeProducts.map { $0.imageUrl }
                                ),
                                onTap: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    selectedComboId = combo.id
                                }
                            )
                            .frame(width: 220)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func toggleBranchLike() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            branchLikesManager.toggleLike(branchId: storeId)
        }
    }
}

struct ShowcaseOrderSheet: View {
    let showcase: ShowcaseGraphQL
    let branchId: String
    let branchName: String
    let onAdded: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var requestDescription: String = ""
    @State private var quantity: Int = 1
    @State private var showValidationError: Bool = false

    private var suggestedRequestDescription: String {
        guard let items = showcase.items, !items.isEmpty else { return "" }

        return items.map { item in
            if let description = item.description, !description.isEmpty {
                return "- \(item.name): \(description)"
            }
            return "- \(item.name)"
        }
        .joined(separator: "\n")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Vitrina") {
                    Text(showcase.title)
                        .font(.system(size: 16, weight: .semibold))
                    Text("Este pedido será confirmado por la tienda según disponibilidad y precio final.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }

                if let items = showcase.items, !items.isEmpty {
                    Section("Productos de la vitrina") {
                        ForEach(items, id: \.id) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.name)
                                        .font(.system(size: 14, weight: .semibold))
                                    Spacer()
                                    if let price = item.price {
                                        Text(String(format: "%.2f", price))
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                }

                                if let description = item.description, !description.isEmpty {
                                    Text(description)
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                Section("Qué necesitas") {
                    TextEditor(text: $requestDescription)
                        .frame(minHeight: 120)
                    if showValidationError {
                        Text("Debes escribir una descripción para pedir desde vitrina.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                    }
                }

                Section("Cantidad") {
                    Stepper(value: $quantity, in: 1...20) {
                        Text("\(quantity)")
                    }
                }
            }
            .navigationTitle("Pedir desde vitrina")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if requestDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    requestDescription = suggestedRequestDescription
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Agregar") {
                        let trimmedDescription = requestDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedDescription.isEmpty else {
                            showValidationError = true
                            return
                        }

                        CartManager.shared.addShowcaseToCart(
                            showcaseId: showcase.id,
                            branchId: branchId,
                            branchName: branchName,
                            title: showcase.title,
                            imageUrl: showcase.imageUrl,
                            requestDescription: trimmedDescription,
                            quantity: quantity
                        )
                        onAdded()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                }
            }
        }
    }
}

// Social Button Component
struct SocialButton: View {
    let iconAsset: String
    let title: String
    var gradient: [Color]? = nil
    var color: Color? = nil
    var url: String? = nil

    var body: some View {
        Button(action: {
            if let urlString = url, let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 8) {
                Image(iconAsset)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                Group {
                    if let gradient = gradient {
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else if let color = color {
                        color
                    }
                }
            )
            .cornerRadius(14)
            .shadow(color: (color ?? Color.pink).opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

// New Card Design for Sibling Branches
struct SiblingBranchCard: View {
    let branch: BranchGraphQL
    let eta: Int
    @ObservedObject private var gradientManager = GradientStateManager.shared

    var body: some View {
        HStack(spacing: 0) {
            // Image
            AsyncImage(url: URL(string: branch.preferredAvatarSmallUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.1)
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    ZStack {
                        Color.gray.opacity(0.1)
                        Image(systemName: "storefront")
                            .font(.system(size: 22))
                            .foregroundColor(.gray.opacity(0.4))
                    }
                @unknown default:
                    Color.gray.opacity(0.1)
                }
            }
            .frame(width: 80, height: 80)
            .clipped()

            // Info Content
            VStack(alignment: .leading, spacing: 6) {
                Text(branch.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(1)

                if !branch.address.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Text(branch.address)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(gradientManager.currentAccentColor)
                    Text("\(eta) min")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(gradientManager.currentAccentColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(gradientManager.currentAccentColor.opacity(0.1))
                .cornerRadius(6)
            }
            .padding(12)
            .frame(height: 80)

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gray.opacity(0.5))
                .padding(.trailing, 12)
        }
        .frame(width: 300, height: 80)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

struct StoreDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StoreDetailView(storeId: "1")
        }
    }
}
