import SwiftUI
import MapKit

@available(iOS 26.0, *)
struct RouteOverlay: View {
    let startCoordinate: CLLocationCoordinate2D
    let endCoordinate: CLLocationCoordinate2D
    let driverLocation: CLLocationCoordinate2D?
    @Binding var region: MKCoordinateRegion

    private var routePoints: [CLLocationCoordinate2D] {
        generateRoutePoints(from: startCoordinate, to: endCoordinate)
    }

    private var completedRoutePoints: [CLLocationCoordinate2D] {
        guard let driverLoc = driverLocation else { return [] }

        // Encontrar el índice del conductor en la ruta
        var closestIndex = 0
        var minDistance = Double.infinity

        for (index, point) in routePoints.enumerated() {
            let distance = sqrt(pow(point.latitude - driverLoc.latitude, 2) +
                              pow(point.longitude - driverLoc.longitude, 2))
            if distance < minDistance {
                minDistance = distance
                closestIndex = index
            }
        }

        // Retornar puntos hasta el conductor
        return Array(routePoints.prefix(closestIndex + 1))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Línea gris (ruta completa)
                Path { path in
                    guard !routePoints.isEmpty else { return }

                    let firstPoint = convertCoordinate(routePoints[0], in: geometry.size)
                    path.move(to: firstPoint)

                    for point in routePoints.dropFirst() {
                        let cgPoint = convertCoordinate(point, in: geometry.size)
                        path.addLine(to: cgPoint)
                    }
                }
                .stroke(Color.gray.opacity(0.3), lineWidth: 5)

                // Línea verde (ruta completada)
                Path { path in
                    guard !completedRoutePoints.isEmpty else { return }

                    let firstPoint = convertCoordinate(completedRoutePoints[0], in: geometry.size)
                    path.move(to: firstPoint)

                    for point in completedRoutePoints.dropFirst() {
                        let cgPoint = convertCoordinate(point, in: geometry.size)
                        path.addLine(to: cgPoint)
                    }
                }
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.llegoPrimary, Color.llegoAccent]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 5
                )
            }
        }
    }

    private func convertCoordinate(_ coordinate: CLLocationCoordinate2D, in size: CGSize) -> CGPoint {
        let span = region.span
        let center = region.center

        // Calcular la posición relativa
        let x = (coordinate.longitude - (center.longitude - span.longitudeDelta / 2)) / span.longitudeDelta
        let y = ((center.latitude + span.latitudeDelta / 2) - coordinate.latitude) / span.latitudeDelta

        return CGPoint(
            x: x * size.width,
            y: y * size.height
        )
    }

    private func generateRoutePoints(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        var points: [CLLocationCoordinate2D] = []
        let numberOfPoints = 40

        for i in 0...numberOfPoints {
            let progress = Double(i) / Double(numberOfPoints)
            let baseLat = start.latitude + (end.latitude - start.latitude) * progress
            let baseLon = start.longitude + (end.longitude - start.longitude) * progress
            let variation = sin(progress * .pi * 3) * 0.0005

            points.append(CLLocationCoordinate2D(
                latitude: baseLat + variation,
                longitude: baseLon + variation * 0.7
            ))
        }

        return points
    }
}
