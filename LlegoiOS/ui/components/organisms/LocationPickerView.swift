import SwiftUI
@preconcurrency import MapKit

struct LocationPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var locationManager: LocationManager

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 23.1136, longitude: -82.3666), // La Habana
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var searchText = ""
    @State private var showingConfirmation = false
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var showSearchResults = false

    var body: some View {
        ZStack {
            // Mapa simple
            Map(coordinateRegion: .constant(region))
                .ignoresSafeArea()

            // Pin central
            VStack {
                Spacer()
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.llegoPrimary)
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                Spacer()
            }

            VStack {
                // Header con búsqueda
                VStack(spacing: 0) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 40, height: 40)
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)

                            CloseButton(action: {
                                presentationMode.wrappedValue.dismiss()
                            })
                        }

                        Spacer()

                        Button(action: {
                            locationManager.getCurrentLocation()
                            if let location = locationManager.location {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    region.center = location
                                }
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 40, height: 40)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)

                                Image(systemName: "location.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.llegoAccent)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 16)

                    // Barra de búsqueda
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            Image(systemName: isSearching ? "hourglass" : "magnifyingglass")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)

                            TextField("Buscar dirección...", text: $searchText)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.llegoPrimary)
                                .onSubmit {
                                    searchAddress()
                                }

                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    searchResults = []
                                    showSearchResults = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                        )

                        // Resultados de búsqueda
                        if showSearchResults && !searchResults.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(searchResults.prefix(5), id: \.self) { mapItem in
                                    Button(action: {
                                        selectSearchResult(mapItem)
                                    }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "mappin.circle.fill")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.llegoAccent)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(mapItem.name ?? "Ubicación")
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundColor(.llegoPrimary)

                                                if let address = formatAddress(from: mapItem) {
                                                    Text(address)
                                                        .font(.system(size: 13, weight: .medium))
                                                        .foregroundColor(.gray)
                                                        .lineLimit(1)
                                                }
                                            }

                                            Spacer()
                                        }
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 12)
                                    }

                                    if mapItem != searchResults.prefix(5).last {
                                        Divider()
                                            .padding(.horizontal, 18)
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                            )
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.95),
                            Color.white.opacity(0.8),
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Spacer()

                // Panel de confirmación
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.llegoAccent.opacity(0.1))
                                .frame(width: 48, height: 48)

                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.llegoPrimary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ubicación de entrega")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)

                            Text(getAddressText())
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.llegoPrimary)
                                .lineLimit(2)
                        }

                        Spacer()
                    }

                    Button(action: {
                        locationManager.updateLocation(coordinate: region.center)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showingConfirmation = true
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        HStack(spacing: 8) {
                            if showingConfirmation {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .transition(.scale.combined(with: .opacity))
                            }

                            Text(showingConfirmation ? "Ubicación confirmada" : "Confirmar ubicación")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            Group {
                                if showingConfirmation {
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.llegoAccent, Color.llegoAccent.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                } else {
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.llegoPrimary, Color.llegoPrimary.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                }
                            }
                        )
                        .cornerRadius(27)
                        .shadow(color: (showingConfirmation ? Color.llegoAccent : Color.llegoPrimary).opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .disabled(showingConfirmation)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: -4)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if let location = locationManager.location {
                region.center = location
            }
        }
    }

    private func getAddressText() -> String {
        let lat = String(format: "%.4f", region.center.latitude)
        let lon = String(format: "%.4f", region.center.longitude)
        return "Lat: \(lat), Lon: \(lon)"
    }

    private func searchAddress() {
        guard !searchText.isEmpty else {
            searchResults = []
            showSearchResults = false
            return
        }

        isSearching = true
        showSearchResults = true

        let searchQuery = searchText

        Task { @MainActor in
            let mapItems: [MKMapItem]

            if let request = MKGeocodingRequest(addressString: searchQuery) {
                do {
                    mapItems = try await request.mapItems
                } catch {
                    print("Error searching address: \(error.localizedDescription)")
                    mapItems = []
                }
            } else {
                mapItems = []
            }

            self.searchResults = mapItems
            self.isSearching = false
        }
    }

    private func selectSearchResult(_ mapItem: MKMapItem) {
        let coordinate = mapItem.location.coordinate

        withAnimation(.easeInOut(duration: 0.4)) {
            region.center = coordinate
            region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        }

        searchText = mapItem.name ?? ""
        showSearchResults = false
        searchResults = []
    }

    private func formatAddress(from mapItem: MKMapItem) -> String? {
        // Keep it simple - just use the name or fallback to fullAddress
        if let name = mapItem.name, !name.isEmpty {
            return name
        }
        
        if let address = mapItem.address {
            return address.fullAddress
        }
        
        return nil
    }
}

