//
//  OrderFlowCoordinatorView.swift
//  LlegoiOS
//
//  Coordinador de flujo de pedidos simplificado
//

import SwiftUI

struct OrderFlowCoordinatorView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ConversationalSearchView()
                .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    OrderFlowCoordinatorView()
}


