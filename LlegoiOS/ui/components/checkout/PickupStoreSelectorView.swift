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
                .scaledFont(size: 15, weight: .semibold, relativeTo: .subheadline)
                .foregroundColor(.primary)

            if let selection {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selection.branchName)
                        .scaledFont(size: 14, weight: .semibold, relativeTo: .subheadline)
                    if let address = selection.address, !address.isEmpty {
                        Text(address)
                            .scaledFont(size: 13, relativeTo: .footnote)
                            .foregroundColor(.secondary)
                    }
                }
            } else if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Cargando tienda...")
                        .scaledFont(size: 13, weight: .medium, relativeTo: .footnote)
                        .foregroundColor(.secondary)
                }
            } else if let loadError {
                Text(loadError)
                    .scaledFont(size: 13, weight: .medium, relativeTo: .footnote)
                    .foregroundColor(.red)
            } else {
                Text("Selecciona una tienda para recoger.")
                    .scaledFont(size: 13, weight: .medium, relativeTo: .footnote)
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
