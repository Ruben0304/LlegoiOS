import Foundation
import SwiftUI
import Combine

@MainActor
class TutorialsViewModel: ObservableObject {
    @Published var tutorials: [Tutorial] = []
    @Published var selectedTutorial: Tutorial?
    @Published var isPlaying: Bool = false

    init() {
        loadTutorials()
    }

    func loadTutorials() {
        // Mock data - En producción esto vendría de GraphQL
        let baseThumbnailUrl = "https://bucket-production-435ad.up.railway.app/tutoriales/Captura%20de%20pantalla%202025-10-30%20a%20la(s)%2012.17.10%20p.m..png"

        tutorials = [
            Tutorial(
                id: "1",
                title: "Cómo hacer tu primer pedido",
                description: "Aprende a navegar por la app y realizar tu primera compra de manera fácil y rápida.",
                duration: "3:45",
                thumbnailUrl: baseThumbnailUrl,
                videoUrl: "https://bucket-production-435ad.up.railway.app/tutoriales/Generated video 1-2.mp4",
                category: "Primeros pasos"
            ),
            Tutorial(
                id: "2",
                title: "Tips para ahorrar en tus compras",
                description: "Descubre cómo aprovechar las promociones y ofertas especiales de Llego.",
                duration: "5:12",
                thumbnailUrl: baseThumbnailUrl,
                videoUrl: "https://bucket-production-435ad.up.railway.app/tutoriales/Generated video 1-2.mp4",
                category: "Consejos"
            ),
            Tutorial(
                id: "3",
                title: "Rastrea tu pedido en tiempo real",
                description: "Conoce todas las funciones del seguimiento de pedidos en vivo.",
                duration: "4:30",
                thumbnailUrl: baseThumbnailUrl,
                videoUrl: "https://bucket-production-435ad.up.railway.app/tutoriales/Generated video 1-2.mp4",
                category: "Funciones avanzadas"
            ),
            Tutorial(
                id: "4",
                title: "Gestiona tus direcciones de entrega",
                description: "Aprende a añadir, editar y seleccionar tus ubicaciones favoritas.",
                duration: "2:50",
                thumbnailUrl: baseThumbnailUrl,
                videoUrl: "https://bucket-production-435ad.up.railway.app/tutoriales/Generated video 1-2.mp4",
                category: "Configuración"
            ),
            Tutorial(
                id: "5",
                title: "Métodos de pago disponibles",
                description: "Conoce todas las formas de pago que puedes usar en Llego.",
                duration: "3:20",
                thumbnailUrl: baseThumbnailUrl,
                videoUrl: "https://bucket-production-435ad.up.railway.app/tutoriales/Generated video 1-2.mp4",
                category: "Pagos"
            ),
            Tutorial(
                id: "6",
                title: "Programa de referidos Llego",
                description: "Invita a tus amigos y gana beneficios en cada compra.",
                duration: "4:05",
                thumbnailUrl: baseThumbnailUrl,
                videoUrl: "https://bucket-production-435ad.up.railway.app/tutoriales/Generated video 1-2.mp4",
                category: "Beneficios"
            )
        ]
    }

    func selectTutorial(_ tutorial: Tutorial) {
        selectedTutorial = tutorial
        isPlaying = true
    }

    func closeTutorial() {
        selectedTutorial = nil
        isPlaying = false
    }
}
