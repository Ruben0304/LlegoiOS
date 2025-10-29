import Foundation
import SwiftUI
import Combine

enum WalletCurrency: String, CaseIterable, Identifiable {
    case usd
    case cup

    var id: String { rawValue }

    var currencyCode: String {
        switch self {
        case .usd:
            return "USD"
        case .cup:
            return "CUP"
        }
    }

    var symbol: String {
        switch self {
        case .usd, .cup:
            return "$"
        }
    }
}

@MainActor
class WalletViewModel: ObservableObject {
    @Published var balance: Double = 0.0
    @Published var cupBalance: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var showRechargeSheet: Bool = false
    @Published var showForeignRechargeSheet: Bool = false
    @Published var showRefundSheet: Bool = false
    @Published var rechargeAmount: String = ""
    @Published var foreignRechargeURL: String = ""
    @Published var showSuccessMessage: Bool = false
    @Published var successMessage: String = ""
    @Published var showTransferSheet: Bool = false
    @Published var transferUsername: String = ""
    @Published var transferAmount: String = ""

    func loadBalance() {
        // TODO: Fetch balance from GraphQL
        // For now, using mock data
        balance = 125.50
        cupBalance = 2987.40
    }

    func balance(for currency: WalletCurrency) -> Double {
        switch currency {
        case .usd:
            return balance
        case .cup:
            return cupBalance
        }
    }

    func prepareCupTransfer(amountText: String) {
        rechargeAmount = sanitizeAmount(amountText)
    }

    var cupTransferAmountDisplay: String {
        let sanitized = sanitizeAmount(rechargeAmount)
        return sanitized
    }

    func processLocalRecharge(for currency: WalletCurrency) {
        guard let amount = Double(rechargeAmount), amount > 0 else {
            return
        }

        isLoading = true

        // Simulate Apple Pay processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self else { return }

            switch currency {
            case .usd:
                self.balance += amount
            case .cup:
                self.cupBalance += amount
            }

            self.isLoading = false
            self.showRechargeSheet = false
            self.rechargeAmount = ""

            let formattedAmount = String(format: "%.2f", amount)
            self.successMessage = "¡Recarga exitosa! Se agregaron \(currency.symbol)\(formattedAmount) \(currency.currencyCode) a tu wallet"
            self.showSuccessMessage = true

            // Hide success message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showSuccessMessage = false
            }
        }
    }

    func completeCupTransferRecharge(amountString: String) {
        let sanitizedAmount = sanitizeAmount(amountString)
        guard let amount = Double(sanitizedAmount), amount > 0 else {
            return
        }

        cupBalance += amount
        rechargeAmount = ""

        let formattedAmount = String(format: "%.2f", amount)
        successMessage = "¡Transferencia CUP registrada! Se agregaron \(WalletCurrency.cup.symbol)\(formattedAmount) \(WalletCurrency.cup.currencyCode) a tu wallet"
        showSuccessMessage = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.showSuccessMessage = false
        }
    }

    private func sanitizeAmount(_ text: String) -> String {
        let allowed = CharacterSet(charactersIn: "0123456789.,")
        let filteredScalars = text.unicodeScalars.filter { allowed.contains($0) }
        var sanitized = String(String.UnicodeScalarView(filteredScalars))
        sanitized = sanitized.replacingOccurrences(of: ",", with: ".")
        return sanitized
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

    func presentTransferSheet() {
        transferUsername = ""
        transferAmount = ""
        showTransferSheet = true
    }

    func sanitizeTransferAmount() {
        let sanitized = sanitizeAmount(transferAmount)
        if sanitized != transferAmount {
            transferAmount = sanitized
        }
    }

    var isTransferFormValid: Bool {
        let trimmedUsername = transferUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        let amountValue = Double(sanitizeAmount(transferAmount)) ?? 0
        return !trimmedUsername.isEmpty && amountValue > 0
    }

    func performTransfer(for currency: WalletCurrency) {
        let trimmedUsername = transferUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedAmount = sanitizeAmount(transferAmount)
        guard
            !trimmedUsername.isEmpty,
            let amountValue = Double(sanitizedAmount),
            amountValue > 0
        else {
            return
        }

        isLoading = true
        let formattedAmount = String(format: "%.2f", amountValue)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }

            self.isLoading = false
            self.showTransferSheet = false
            self.transferUsername = ""
            self.transferAmount = ""

            self.successMessage = "Transferencia enviada a \(trimmedUsername). \(currency.symbol)\(formattedAmount) \(currency.currencyCode)"
            self.showSuccessMessage = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showSuccessMessage = false
            }
        }
    }
}
