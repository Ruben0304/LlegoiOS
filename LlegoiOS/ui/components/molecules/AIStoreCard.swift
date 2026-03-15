//
//  AIStoreCard.swift
//  LlegoiOS
//
//  Componente para mostrar tiendas en el chat con IA
//

import SwiftUI

struct AIStoreCard: View {
    let branch: AIChatBranchEntity
    @ObservedObject private var gradientManager = GradientStateManager.shared

    // Calcular ETA basado en coordenadas (placeholder por ahora)
    private var etaMinutes: Int {
        // TODO: Implementar cálculo real con ubicación del usuario
        return Int.random(in: 15...45)
    }

    // URL del avatar de la tienda desde el backend
    private var logoUrl: String {
        branch.avatarUrl ?? "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center"
    }

    private var bannerUrl: String {
        "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center"
    }

    var body: some View {
        let bannerHeight: CGFloat = 100
        let logoSize: CGFloat = 56
        let padding: CGFloat = 12
        let nameFontSize: CGFloat = 15
        let detailFontSize: CGFloat = 12
        let cornerRadius: CGFloat = 16
        let logoOffset = logoSize / 2

        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                // Banner Image
                AsyncImage(url: URL(string: bannerUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(red: 240/255, green: 242/255, blue: 246/255))
                        .overlay(
                            ProgressView()
                                .tint(gradientManager.currentAccentColor)
                        )
                }
                .frame(height: bannerHeight)
                .frame(maxWidth: .infinity)
                .clipped()

                // Store Info
                VStack(alignment: .leading, spacing: 6) {
                    // Nombre de la tienda
                    Text(branch.name)
                        .font(.system(size: nameFontSize, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let reason = branch.reason, !reason.isEmpty {
                        Text(reason)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(gradientManager.currentAccentColor)
                            .lineLimit(2)
                    }

                    // Dirección
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)

                        Text(branch.address)
                            .font(.system(size: detailFontSize))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    // ETA y Estado
                    HStack {
                        HStack(spacing: 4) {
                            Text("⚡")
                                .font(.system(size: detailFontSize))

                            Text("\(etaMinutes) min")
                                .font(.system(size: detailFontSize, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Estado de la tienda
                        let normalizedStatus = branch.status?
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .lowercased()

                        if normalizedStatus == "open" {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                Text("Abierto")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.green)
                            }
                        } else if normalizedStatus == "closed" {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                Text("Cerrado")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding(.horizontal, padding)
                .padding(.top, logoOffset + (padding * 0.5))
                .padding(.bottom, padding)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
            )

            // Store Logo - overlapping design con ProgressView accent
            AsyncImage(url: URL(string: logoUrl)) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Circle()
                            .fill(Color.llegoBackground)
                        ProgressView()
                            .tint(.llegoAccent)
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    ZStack {
                        Circle()
                            .fill(Color.llegoBackground)
                        Image(systemName: "storefront")
                            .font(.system(size: 24))
                            .foregroundColor(gradientManager.currentAccentColor)
                    }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: logoSize, height: logoSize)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 3)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 2)
            .offset(x: padding, y: bannerHeight - logoOffset)
        }
    }
}
