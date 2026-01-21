import Foundation
import SwiftUI
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var walletBalance: Double = 0.0
    @Published var walletBalanceLocal: Double = 0.0
    @Published var isLoadingWallet: Bool = false
    @Published var walletStatus: String = "active"

    private let repository = HomeRepository()
    private let authManager = AuthManager.shared

    // MARK: - Load Wallet Balance
    func loadWalletBalance() async {
        guard let jwt = await authManager.getAccessToken() else {
            print("⚠️ No JWT token available for home wallet")
            return
        }

        isLoadingWallet = true

        do {
            let balance = try await repository.fetchWalletBalance(jwt: jwt)
            await MainActor.run {
                self.walletBalance = balance.usd
                self.walletBalanceLocal = balance.local
                self.walletStatus = balance.status
                self.isLoadingWallet = false
            }
        } catch {
            print("❌ Error loading home wallet balance: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoadingWallet = false
            }
        }
    }

    // Computed property para mostrar el balance formateado
    var formattedBalance: String {
        return String(format: "$%.2f", walletBalance)
    }
}
