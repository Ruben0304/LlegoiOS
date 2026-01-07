import SwiftUI

struct CustomerLevelBenefitsView: View {
    @Environment(\.dismiss) private var dismiss

    private let levels: [LevelInfo] = [
        LevelInfo(
            level: .bronze,
            subtitle: "Primer salto de beneficios",
            perks: [
                "Promos exclusivas en tiendas seleccionadas",
                "Atención prioritaria en soporte",
                "Acceso temprano a nuevos features"
            ]
        ),
        LevelInfo(
            level: .silver,
            subtitle: "Más ahorro, más prioridad",
            perks: [
                "Cupones extra cada mes",
                "Soporte con respuesta más rápida",
                "Envíos con prioridad en franjas pico"
            ]
        ),
        LevelInfo(
            level: .gold,
            subtitle: "Máximo reconocimiento",
            perks: [
                "Promos premium y beneficios sorpresa",
                "Soporte preferente 1:1",
                "Acceso anticipado a eventos especiales"
            ]
        ),
        LevelInfo(
            level: .platinum,
            subtitle: "Experiencia top",
            perks: [
                "Beneficios exclusivos personalizados",
                "Soporte VIP",
                "Acceso priorizado a lanzamientos"
            ]
        )
    ]

    private let pointsInfo: [String] = [
        "Compra en la app y completa pedidos",
        "Califica tus compras y deja reseñas",
        "Invita amigos y gana puntos extra",
        "Participa en promociones de temporada"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.llegoBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection

                        ForEach(levels) { item in
                            levelCard(item)
                        }

                        pointsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Privilegios")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButton(action: {
                        dismiss()
                    })
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Niveles de Cliente")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.llegoPrimary)

            Text("Conoce los beneficios de cada nivel y como obtener puntos.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func levelCard(_ item: LevelInfo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Circle()
                    .fill(item.level.color)
                    .frame(width: 10, height: 10)

                Text(item.level.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.llegoPrimary)

                Spacer()
            }

            Text(item.subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)

            ForEach(item.perks, id: \.self) { perk in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(item.level.color)

                    Text(perk)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.llegoPrimary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    private var pointsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Como se obtienen los puntos")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.llegoPrimary)

            ForEach(pointsInfo, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.llegoAccent)

                    Text(item)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.llegoPrimary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

private struct LevelInfo: Identifiable {
    let id = UUID()
    let level: CustomerLevel
    let subtitle: String
    let perks: [String]
}
