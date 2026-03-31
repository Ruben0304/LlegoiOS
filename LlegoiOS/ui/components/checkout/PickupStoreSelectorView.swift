import SwiftUI

struct PickupStoreSelectorView: View {
    @Binding var selection: PickupSelection?
    let currentBranchId: String?

    @State private var isLoading = false
    @State private var loadError: String?
    private let repository = StoreDetailRepository()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tienda de recogida")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)

            if let selection {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selection.branchName)
                        .font(.system(size: 14, weight: .semibold))
                    if let address = selection.address, !address.isEmpty {
                        Text(address)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
            } else if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Cargando tienda...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            } else if let loadError {
                Text(loadError)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.red)
            } else {
                Text("Selecciona una tienda para recoger.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .onAppear {
            if selection == nil {
                loadCurrentBranchSelectionIfNeeded()
            }
        }
    }

    private func loadCurrentBranchSelectionIfNeeded() {
        guard let currentBranchId, !currentBranchId.isEmpty else { return }
        guard !isLoading else { return }
        isLoading = true
        loadError = nil

        repository.fetchBranchDetail(id: currentBranchId) { result in
            Task { @MainActor in
                isLoading = false
                switch result {
                case .success(let detail):
                    selection = PickupSelection(
                        branchId: detail.id,
                        branchName: detail.name,
                        address: detail.address,
                        latitude: detail.coordinates.latitude,
                        longitude: detail.coordinates.longitude,
                        scheduleJson: nil,
                        selectedWindowId: nil
                    )
                case .failure(let error):
                    loadError = error.localizedDescription
                }
            }
        }
    }
}
