import SwiftUI

struct TransactionHistoryView: View {
    let transactions: [WalletTransaction]
    let currentUserId: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Historial de Transacciones")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 20)

            if transactions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("No hay transacciones")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(transactions, id: \.id) { transaction in
                            TransactionRow(
                                transaction: transaction,
                                currentUserId: currentUserId
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: WalletTransaction
    let currentUserId: String

    private var transactionInfo: TransactionInfo {
        switch transaction.type {
        case "deposit":
            return TransactionInfo(
                icon: "arrow.down.circle.fill",
                title: "Depósito",
                subtitle: transaction.description ?? "Recarga de saldo",
                color: .green,
                isIncoming: true
            )
        case "withdrawal":
            return TransactionInfo(
                icon: "arrow.up.circle.fill",
                title: "Retiro",
                subtitle: transaction.description ?? "Retiro de saldo",
                color: .red,
                isIncoming: false
            )
        case "transfer":
            let isIncoming = transaction.toOwnerId == currentUserId
            let otherParty = isIncoming ? transaction.fromOwnerId : transaction.toOwnerId
            return TransactionInfo(
                icon: isIncoming ? "arrow.down.right.circle.fill" : "arrow.up.right.circle.fill",
                title: isIncoming ? "Recibido" : "Enviado",
                subtitle: isIncoming ? "De \(otherParty ?? "Usuario")" : "A \(otherParty ?? "Usuario")",
                color: isIncoming ? .green : .red,
                isIncoming: isIncoming
            )
        default:
            return TransactionInfo(
                icon: "circle.fill",
                title: "Transacción",
                subtitle: transaction.description ?? "",
                color: .gray,
                isIncoming: false
            )
        }
    }

    private var statusBadge: (text: String, color: Color)? {
        switch transaction.status {
        case "pending":
            return ("Pendiente", .orange)
        case "failed":
            return ("Fallida", .red)
        case "reversed":
            return ("Revertida", .purple)
        case "completed":
            return nil // No mostrar badge para completadas
        default:
            return nil
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(transactionInfo.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: transactionInfo.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(transactionInfo.color)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(transactionInfo.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)

                    if let badge = statusBadge {
                        Text(badge.text)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(badge.color)
                            )
                    }
                }

                Text(transactionInfo.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Text(formatDate(transaction.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.8))
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(transactionInfo.isIncoming ? "+" : "-")\(transaction.currency == "usd" ? "$" : "$")\(String(format: "%.2f", transaction.amount))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(transactionInfo.isIncoming ? .green : .red)

                Text(transaction.currency.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray6))
                    )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
    }

    private func formatDate(_ dateString: String) -> String {
        // Parse ISO date string
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let displayFormatter = DateFormatter()

        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            displayFormatter.dateFormat = "'Hoy a las' HH:mm"
        } else if calendar.isDateInYesterday(date) {
            displayFormatter.dateFormat = "'Ayer a las' HH:mm"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            displayFormatter.dateFormat = "d MMM 'a las' HH:mm"
        } else {
            displayFormatter.dateFormat = "d MMM yyyy"
        }

        displayFormatter.locale = Locale(identifier: "es_ES")
        return displayFormatter.string(from: date)
    }
}

struct TransactionInfo {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let isIncoming: Bool
}

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            TransactionRow(
                transaction: WalletTransaction(
                    id: "1",
                    fromOwnerId: nil,
                    fromOwnerType: nil,
                    toOwnerId: "user123",
                    toOwnerType: "user",
                    amount: 50.0,
                    currency: "usd",
                    type: "deposit",
                    status: "completed",
                    description: "Recarga via Apple Pay",
                    createdAt: ISO8601DateFormatter().string(from: Date()),
                    completedAt: nil
                ),
                currentUserId: "user123"
            )

            TransactionRow(
                transaction: WalletTransaction(
                    id: "2",
                    fromOwnerId: "user123",
                    fromOwnerType: "user",
                    toOwnerId: "user456",
                    toOwnerType: "user",
                    amount: 25.0,
                    currency: "usd",
                    type: "transfer",
                    status: "completed",
                    description: "Transferencia entre usuarios",
                    createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600)),
                    completedAt: nil
                ),
                currentUserId: "user123"
            )
        }
        .padding()
    }
}
