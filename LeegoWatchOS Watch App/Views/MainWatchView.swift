//
//  MainWatchView.swift
//  LeegoWatchOS Watch App
//
//  Created by Claude on 10/27/25.
//

import SwiftUI

struct MainWatchView: View {
    @StateObject private var orderManager = WatchOrderManager.shared
    @State private var showOrderTracking = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: geometry.size.height * 0.025) {
                        // Header con logo
                        VStack(spacing: geometry.size.height * 0.01) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.llegoPrimary.opacity(0.2),
                                                Color.llegoAccent.opacity(0.1)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * 0.25, height: geometry.size.width * 0.25)

                                Image(systemName: "bicycle")
                                    .font(.system(size: geometry.size.width * 0.13, weight: .semibold))
                                    .foregroundColor(.llegoPrimary)
                            }

                            Text("Llegó")
                                .font(.system(size: geometry.size.width * 0.11, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .minimumScaleFactor(0.7)
                        }
                        .padding(.top, 5)

                        // Pedido activo (si existe)
                        if let currentOrder = orderManager.currentOrder,
                           orderManager.orderStatus != .delivered {
                            VStack(spacing: geometry.size.height * 0.015) {
                                Text("Pedido en curso")
                                    .font(.system(size: geometry.size.width * 0.07, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Button(action: {
                                    showOrderTracking = true
                                }) {
                                    OrderTrackingCardWatch(orderManager: orderManager)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Mensaje de inicio si no hay pedidos
                        if orderManager.currentOrder == nil && orderManager.lastOrder == nil {
                            VStack(spacing: geometry.size.height * 0.02) {
                                Image(systemName: "cart.circle.fill")
                                    .font(.system(size: geometry.size.width * 0.25))
                                    .foregroundColor(.llegoAccent.opacity(0.6))

                                Text("No hay pedidos")
                                    .font(.system(size: geometry.size.width * 0.08, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .minimumScaleFactor(0.7)

                                Button(action: {
                                    startMockOrder()
                                }) {
                                    Text("Hacer pedido demo")
                                        .font(.system(size: geometry.size.width * 0.07, weight: .semibold))
                                        .foregroundColor(.white)
                                        .minimumScaleFactor(0.7)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, geometry.size.height * 0.04)
                                        .background(
                                            Capsule()
                                                .fill(Color.llegoPrimary)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.top, geometry.size.height * 0.03)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .frame(minHeight: geometry.size.height)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showOrderTracking) {
                LiveOrderTrackingWatchView()
            }
        }
    }

    private func startMockOrder() {
        orderManager.startMockOrder()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showOrderTracking = true
        }
    }
}

#Preview {
    MainWatchView()
}
