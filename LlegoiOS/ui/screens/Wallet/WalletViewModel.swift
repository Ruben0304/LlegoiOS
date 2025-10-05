import Foundation
import SwiftUI
import Combine

@MainActor
class WalletViewModel: ObservableObject {
    @Published var balance: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var showRechargeSheet: Bool = false
    @Published var showForeignRechargeSheet: Bool = false
    @Published var rechargeAmount: String = ""
    @Published var foreignRechargeURL: String = ""
    @Published var showSuccessMessage: Bool = false
    @Published var successMessage: String = ""

    func loadBalance() {
        // TODO: Fetch balance from GraphQL
        // For now, using mock data
        balance = 125.50
    }

    func processLocalRecharge() {
        guard let amount = Double(rechargeAmount), amount > 0 else {
            return
        }

        isLoading = true

        // Simulate Apple Pay processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.balance += amount
            self?.isLoading = false
            self?.showRechargeSheet = false
            self?.rechargeAmount = ""
            self?.successMessage = "¡Recarga exitosa! Se agregaron $\(String(format: "%.2f", amount)) a tu wallet"
            self?.showSuccessMessage = true

            // Hide success message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self?.showSuccessMessage = false
            }
        }
    }

    func generateForeignRechargeURL() {
        // Generate a random URL for foreign recharge
        let randomID = UUID().uuidString.prefix(8)
        foreignRechargeURL = "https://llego.pay/foreign/\(randomID)"
        showForeignRechargeSheet = true
    }

    func copyURLToClipboard() {
        UIPasteboard.general.string = foreignRechargeURL
    }
}
