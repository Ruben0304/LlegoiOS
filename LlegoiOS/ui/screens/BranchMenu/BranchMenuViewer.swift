//
//  BranchMenuViewer.swift
//  LlegoiOS
//
//  Carta a pantalla completa con zoom y coincidencias resaltadas
//

import SwiftUI

struct BranchMenuViewer: View {
    let menu: BranchMenuInfo
    let title: String
    /// Polígonos normalizados (0-1) a resaltar; vacío si se abre desde el detalle de sucursal.
    var matches: [[CGPoint]] = []

    @State private var image: UIImage?
    @State private var loadFailed = false
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            if let image {
                let size = fittedSize(image.size, in: geo.size)
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: size.width, height: size.height)
                    matchPath(in: size)
                        .fill(Color.yellow.opacity(0.35))
                        .overlay(matchPath(in: size).stroke(Color.orange, lineWidth: 2))
                        .frame(width: size.width, height: size.height)
                }
                .scaleEffect(scale)
                .offset(offset)
                .frame(width: geo.size.width, height: geo.size.height)
                .gesture(
                    MagnifyGesture()
                        .onChanged { scale = min(max(lastScale * $0.magnification, 1), 4) }
                        .onEnded { _ in lastScale = scale }
                        .simultaneously(with: DragGesture()
                            .onChanged { value in
                                guard scale > 1 else { return }
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in lastOffset = offset })
                )
                .onTapGesture(count: 2) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        scale = 1; lastScale = 1; offset = .zero; lastOffset = .zero
                    }
                }
            } else if loadFailed {
                Text("No se pudo cargar la carta")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadImage() }
    }

    private func loadImage() async {
        guard let url = menu.imageUrl else { loadFailed = true; return }
        if let result = try? await URLSession.shared.data(from: url), let loaded = UIImage(data: result.0) {
            image = loaded
        } else {
            loadFailed = true
        }
    }

    /// Tamaño de la imagen ajustada dentro del contenedor (aspect fit), para que los polígonos coincidan con lo visible.
    private func fittedSize(_ imageSize: CGSize, in container: CGSize) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0 else { return container }
        let ratio = min(container.width / imageSize.width, container.height / imageSize.height)
        return CGSize(width: imageSize.width * ratio, height: imageSize.height * ratio)
    }

    private func matchPath(in size: CGSize) -> Path {
        Path { path in
            for polygon in matches where polygon.count >= 3 {
                let points = polygon.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) }
                path.move(to: points[0])
                points.dropFirst().forEach { path.addLine(to: $0) }
                path.closeSubpath()
            }
        }
    }
}
