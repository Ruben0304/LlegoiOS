//
//  OrderFlowCoordinatorView.swift
//  LlegoiOS
//
//  Coordinador de flujo de pedidos que maneja la navegación entre
//  IntroVideo y ConversationalSearch según el estado del flujo
//

import SwiftUI

enum OrderFlowStep {
    case introVideo
    case selectingProductsAndStore
    case paymentMethodVideo
    case selectingPayment
    case thanksVideo
    case finalConfirmation
}

struct OrderFlowCoordinatorView: View {
    @State private var currentStep: OrderFlowStep = .introVideo
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                switch currentStep {
                case .introVideo:
                    IntroVideoView(videoType: .intro) {
                        // Después del video intro, ir a seleccionar productos y tienda
                        withAnimation {
                            currentStep = .selectingProductsAndStore
                        }
                    }
                    
                case .selectingProductsAndStore:
                    ConversationalSearchView(
                        initialStep: .selectingProductAndStore
                    ) {
                        // Después de seleccionar productos + tienda, ir a video de método de pago
                        withAnimation {
                            currentStep = .paymentMethodVideo
                        }
                    }
                    
                case .paymentMethodVideo:
                    IntroVideoView(videoType: .paymentMethod) {
                        // Después del video de método de pago, ir a seleccionar moneda + método
                        withAnimation {
                            currentStep = .selectingPayment
                        }
                    }
                    
                case .selectingPayment:
                    ConversationalSearchView(
                        initialStep: .selectingPayment
                    ) {
                        // Después de seleccionar moneda + método, ir a video de agradecimiento
                        withAnimation {
                            currentStep = .thanksVideo
                        }
                    }
                    
                case .thanksVideo:
                    IntroVideoView(videoType: .thanks) {
                        // Después del video de agradecimiento, mostrar confirmación final
                        withAnimation {
                            currentStep = .finalConfirmation
                        }
                    }
                    
                case .finalConfirmation:
                    ConversationalSearchView(
                        initialStep: .showingConfirmation
                    ) {
                        // Cuando se completa todo, cerrar el flujo
                        dismiss()
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    OrderFlowCoordinatorView()
}


