import SwiftUI
import Combine

struct SavedAddressesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SavedAddressesViewModel()
    @State private var showingAddForm = false
    
    let isSelectingDeliveryAddress: Bool
    let onSelectAddress: ((SavedAddress) -> Void)?
    
    var body: some View {
        NavigationStack {
            List {
                if let addresses = AuthManager.shared.currentUser?.savedAddresses, !addresses.isEmpty {
                    ForEach(addresses) { address in
                        Button(action: {
                            if isSelectingDeliveryAddress {
                                onSelectAddress?(address)
                                dismiss()
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(address.label)
                                        .font(.headline)
                                    Text(address.street)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    if let city = address.city {
                                        Text(city)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                if address.id == AuthManager.shared.currentUser?.defaultAddressId {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.removeAddress(id: address.id)
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                            
                            if address.id != AuthManager.shared.currentUser?.defaultAddressId {
                                Button {
                                    viewModel.setDefaultAddress(id: address.id)
                                } label: {
                                    Label("Establecer como principal", systemImage: "star.fill")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                } else {
                    Text("No tienes direcciones guardadas.")
                        .foregroundColor(.secondary)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle(isSelectingDeliveryAddress ? "Selecciona dirección" : "Mis Direcciones")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddForm = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                if isSelectingDeliveryAddress {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cerrar") {
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddForm) {
                AddressFormView { input, _ in
                    viewModel.addAddress(input: input)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .alert(isPresented: .constant(viewModel.errorMessage != nil)) {
                Alert(title: Text("Error"), message: Text(viewModel.errorMessage ?? ""), dismissButton: .default(Text("OK")) {
                    viewModel.errorMessage = nil
                })
            }
        }
    }
}

@MainActor
class SavedAddressesViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    private let repository = SavedAddressRepository()
    
    func addAddress(input: LlegoAPI.SavedAddressInput) {
        isLoading = true
        Task { @MainActor in
            do {
                guard let token = AuthManager.shared.getAccessToken() else {
                    isLoading = false
                    return
                }
                _ = try await repository.addSavedAddress(jwt: token, input: input)
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func removeAddress(id: String) {
        isLoading = true
        Task { @MainActor in
            do {
                guard let token = AuthManager.shared.getAccessToken() else {
                    isLoading = false
                    return
                }
                _ = try await repository.removeSavedAddress(jwt: token, id: id)
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func setDefaultAddress(id: String) {
        isLoading = true
        Task { @MainActor in
            do {
                guard let token = AuthManager.shared.getAccessToken() else {
                    isLoading = false
                    return
                }
                _ = try await repository.setDefaultAddress(jwt: token, id: id)
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
