import SwiftUI
import PhotosUI
import UIKit

// MARK: - Main View

struct TshirtCustomizerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = TshirtCustomizerViewModel()

    @State private var pickerItem: PhotosPickerItem? = nil
    @State private var pickerError: String? = nil
    @State private var showPicker: Bool = false
    @State private var showCustomColor: Bool = false

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                topBar

                TshirtSceneView(
                    texture: vm.compositeTexture,
                    garmentType: vm.garmentType,
                    gender: vm.gender,
                    shapeVersion: vm.shapeVersion
                )
                .frame(maxWidth: .infinity)
                .frame(height: UIScreen.main.bounds.height * 0.34)
                .background(
                    RadialGradient(
                        colors: [Color.white.opacity(0.10), .clear],
                        center: .center,
                        startRadius: 30,
                        endRadius: 260
                    )
                )

                bottomPanel
            }
        }
        .photosPicker(isPresented: $showPicker, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, newItem in
            guard let item = newItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    vm.addDecal(img)
                } else {
                    pickerError = "No se pudo cargar la imagen"
                }
                pickerItem = nil
            }
        }
        .alert("Error", isPresented: .constant(pickerError != nil), actions: {
            Button("OK") { pickerError = nil }
        }, message: {
            Text(pickerError ?? "")
        })
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.06, blue: 0.10),
                    Color(red: 0.18, green: 0.07, blue: 0.16),
                    Color(red: 0.10, green: 0.05, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Soft tinted glow synced with shirt color
            RadialGradient(
                colors: [vm.effectiveBaseColor.opacity(0.35), .clear],
                center: .top,
                startRadius: 60,
                endRadius: 460
            )
            .blendMode(.screen)
            .opacity(0.7)
        }
        .ignoresSafeArea()
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(alignment: .center) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(.ultraThinMaterial))
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
            }

            Spacer()

            VStack(spacing: 1) {
                Text("Diseña tu prenda")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text("\(vm.garmentType.rawValue) · \(vm.gender.rawValue)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer()

            ShareLink(
                item: Image(uiImage: vm.compositeTexture),
                preview: SharePreview("Mi diseño", image: Image(uiImage: vm.compositeTexture))
            ) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(.ultraThinMaterial))
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    // MARK: - Bottom Panel

    private var bottomPanel: some View {
        ScrollView {
            VStack(spacing: 18) {
                styleSection
                designSection
                if vm.selectedDecal != nil {
                    decalControls
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ))
                }
                colorSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 36)
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
                .ignoresSafeArea(edges: .bottom)
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: vm.selectedDecalID)
    }

    // MARK: - Style Section

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Estilo", icon: "tshirt")
            HStack(spacing: 10) {
                ForEach(GarmentType.allCases) { t in
                    StyleChip(
                        title: t.rawValue,
                        subtitle: t.subtitle,
                        icon: t.icon,
                        isSelected: vm.garmentType == t
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            vm.setGarmentType(t)
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                ForEach(GarmentGender.allCases) { g in
                    StyleChip(
                        title: g.rawValue,
                        subtitle: nil,
                        icon: g.icon,
                        isSelected: vm.gender == g
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            vm.setGender(g)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Design Section

    private var designSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionHeader("Diseño", icon: "wand.and.stars")
                Spacer()
                Button {
                    showPicker = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Añadir PNG")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(LinearGradient(
                            colors: [Color(red: 0.85, green: 0.30, blue: 0.55),
                                     Color(red: 0.78, green: 0.25, blue: 0.50)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    )
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.20), lineWidth: 1))
                    .shadow(color: Color(red: 0.78, green: 0.25, blue: 0.50).opacity(0.5),
                            radius: 8, x: 0, y: 4)
                }
            }

            DecalCanvas(viewModel: vm)
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )

            if !vm.decals.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(vm.decals) { decal in
                            DecalThumbnail(
                                decal: decal,
                                isSelected: vm.selectedDecalID == decal.id
                            ) {
                                vm.selectedDecalID = decal.id
                                vm.bringToFront(decalID: decal.id)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("Pulsa “Añadir PNG” para insertar una imagen, luego arrástrala, pellizca para escalar y rota con dos dedos.")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Decal Controls (slider panel)

    private var decalControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader("Capa", icon: "slider.horizontal.3")
                Spacer()
                if let d = vm.selectedDecal {
                    Button {
                        vm.sendToBack(decalID: d.id)
                    } label: {
                        Image(systemName: "rectangle.stack")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Color.white.opacity(0.10)))
                    }
                    Button {
                        vm.bringToFront(decalID: d.id)
                    } label: {
                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Color.white.opacity(0.10)))
                    }
                    Button(role: .destructive) {
                        vm.removeSelectedDecal()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.red.opacity(0.9))
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Color.red.opacity(0.15)))
                    }
                }
            }

            if let d = vm.selectedDecal {
                SliderRow(
                    icon: "arrow.up.left.and.arrow.down.right",
                    label: "Tamaño",
                    value: Binding(
                        get: { Double(d.scale) },
                        set: { v in vm.update(decalID: d.id) { $0.scale = CGFloat(v) } }
                    ),
                    range: 0.05...1.5,
                    formatted: { String(format: "%.2f", $0) }
                )

                SliderRow(
                    icon: "arrow.triangle.2.circlepath",
                    label: "Rotación",
                    value: Binding(
                        get: { d.rotation.degrees },
                        set: { v in vm.update(decalID: d.id) { $0.rotation = .degrees(v) } }
                    ),
                    range: -180...180,
                    formatted: { "\(Int($0))°" }
                )

                SliderRow(
                    icon: "circle.lefthalf.filled",
                    label: "Opacidad",
                    value: Binding(
                        get: { d.opacity },
                        set: { v in vm.update(decalID: d.id) { $0.opacity = v } }
                    ),
                    range: 0...1,
                    formatted: { "\(Int($0 * 100))%" }
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - Color Section

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionHeader("Color", icon: "paintpalette.fill")
                Spacer()
                ColorPicker("", selection: Binding(
                    get: { vm.customColor ?? vm.selectedColor.color },
                    set: { vm.setCustomColor($0) }
                ), supportsOpacity: false)
                .labelsHidden()
                .frame(width: 36, height: 28)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ShirtColorOption.presets) { c in
                        ColorSwatch(
                            color: c.color,
                            isSelected: vm.customColor == nil && vm.selectedColor.id == c.id
                        ) {
                            vm.setPresetColor(c)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.65))
            Text(title.uppercased())
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.65))
        }
    }
}

// MARK: - Decal Canvas (2D editor)

struct DecalCanvas: View {
    @ObservedObject var viewModel: TshirtCustomizerViewModel

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Shirt color background
                viewModel.effectiveBaseColor

                // Subtle radial highlight to mimic fabric
                RadialGradient(
                    colors: [Color.white.opacity(0.10), .clear],
                    center: .top,
                    startRadius: 10,
                    endRadius: max(geo.size.width, geo.size.height)
                )

                // Print area guide
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        Color.black.opacity(0.18),
                        style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                    )
                    .padding(.horizontal, 26)
                    .padding(.vertical, 22)

                // Decals
                ForEach(viewModel.decals) { decal in
                    DecalLayerView(
                        decal: decal,
                        isSelected: viewModel.selectedDecalID == decal.id,
                        canvasSize: geo.size,
                        viewModel: viewModel
                    )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.selectedDecalID = nil
            }
        }
    }
}

// MARK: - Single Decal Layer (gestures)

struct DecalLayerView: View {
    let decal: Decal
    let isSelected: Bool
    let canvasSize: CGSize
    @ObservedObject var viewModel: TshirtCustomizerViewModel

    @State private var dragStartPos: CGPoint? = nil
    @State private var scaleStart: CGFloat? = nil
    @State private var rotationStart: Angle? = nil

    var body: some View {
        let imgAspect = max(decal.image.size.width, 1) / max(decal.image.size.height, 1)
        let widthOnCanvas  = canvasSize.width * decal.scale
        let heightOnCanvas = widthOnCanvas / imgAspect
        let centerX = decal.position.x * canvasSize.width
        let centerY = decal.position.y * canvasSize.height

        let drag = DragGesture(minimumDistance: 0)
            .onChanged { value in
                if dragStartPos == nil {
                    dragStartPos = decal.position
                    viewModel.selectedDecalID = decal.id
                    viewModel.bringToFront(decalID: decal.id)
                }
                guard let start = dragStartPos else { return }
                let dx = value.translation.width / canvasSize.width
                let dy = value.translation.height / canvasSize.height
                viewModel.update(decalID: decal.id) { d in
                    d.position = CGPoint(
                        x: min(max(start.x + dx, 0), 1),
                        y: min(max(start.y + dy, 0), 1)
                    )
                }
            }
            .onEnded { _ in dragStartPos = nil }

        let magnify = MagnificationGesture()
            .onChanged { value in
                if scaleStart == nil {
                    scaleStart = decal.scale
                    viewModel.selectedDecalID = decal.id
                }
                guard let start = scaleStart else { return }
                viewModel.update(decalID: decal.id) { d in
                    d.scale = min(max(start * value, 0.05), 1.5)
                }
            }
            .onEnded { _ in scaleStart = nil }

        let rotate = RotationGesture()
            .onChanged { value in
                if rotationStart == nil {
                    rotationStart = decal.rotation
                    viewModel.selectedDecalID = decal.id
                }
                guard let start = rotationStart else { return }
                viewModel.update(decalID: decal.id) { d in
                    d.rotation = start + value
                }
            }
            .onEnded { _ in rotationStart = nil }

        Image(uiImage: decal.image)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: widthOnCanvas, height: heightOnCanvas)
            .opacity(decal.opacity)
            .rotationEffect(decal.rotation)
            .overlay(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 2)
                            .strokeBorder(Color.white, style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                            .shadow(color: .black.opacity(0.4), radius: 1)
                            .padding(-3)
                            .rotationEffect(decal.rotation)
                    }
                }
            )
            .position(x: centerX, y: centerY)
            .gesture(drag)
            .simultaneousGesture(magnify)
            .simultaneousGesture(rotate)
    }
}

// MARK: - Style Chip

struct StyleChip: View {
    let title: String
    let subtitle: String?
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                    if let sub = subtitle {
                        Text(sub)
                            .font(.system(size: 10, weight: .medium))
                            .opacity(0.65)
                    }
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    if isSelected {
                        LinearGradient(
                            colors: [Color(red: 0.85, green: 0.30, blue: 0.55),
                                     Color(red: 0.55, green: 0.18, blue: 0.42)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.white.opacity(0.07)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.white.opacity(0.30) : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(
                color: isSelected ? Color(red: 0.78, green: 0.25, blue: 0.50).opacity(0.45) : .clear,
                radius: 8, x: 0, y: 4
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color Swatch

struct ColorSwatch: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 38, height: 38)
                    .overlay(
                        Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)

                if isSelected {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .frame(width: 46, height: 46)
                }
            }
            .frame(width: 50, height: 50)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Decal Thumbnail

struct DecalThumbnail: View {
    let decal: Decal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(uiImage: decal.image)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.92))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isSelected ? Color(red: 0.85, green: 0.30, blue: 0.55) : Color.white.opacity(0.15),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Slider Row

struct SliderRow: View {
    let icon: String
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let formatted: (Double) -> String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 18)
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 70, alignment: .leading)
            Slider(value: $value, in: range)
                .tint(Color(red: 0.85, green: 0.30, blue: 0.55))
            Text(formatted(value))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 48, alignment: .trailing)
        }
    }
}
