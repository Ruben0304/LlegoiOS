//
//  BranchMenuSearchSection.swift
//  LlegoiOS
//
//  Sección "Cartas" de la búsqueda: una fila por sucursal con nº de coincidencias
//

import SwiftUI

struct BranchMenuSearchSection: View {
    let hits: [MenuSearchHit]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cartas")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.horizontal, 20)

            ForEach(hits) { hit in
                NavigationLink {
                    BranchMenuViewer(menu: hit.menu, title: hit.branchName, matches: hit.matches)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(hit.branchName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("\(hit.matchCount) \(hit.matchCount == 1 ? "coincidencia" : "coincidencias") en la carta")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
}
