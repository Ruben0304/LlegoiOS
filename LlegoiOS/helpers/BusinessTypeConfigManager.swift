import Foundation
import SwiftUI
import Combine
import Apollo

/// Manager principal para tipos de negocio dinámicos
/// Maneja sincronización con backend, descarga de modelos 3D y cache local
@MainActor
final class BusinessTypeConfigManager: ObservableObject {
    static let shared = BusinessTypeConfigManager()
    
    // MARK: - Published Properties
    
    /// Todos los tipos de negocio disponibles (ordenados por sortOrder)
    @Published private(set) var businessTypes: [BusinessTypeConfig] = []
    
    /// Estado de descarga por tipo de negocio (key -> state)
    @Published private(set) var downloadStates: [String: Model3DDownloadState] = [:]
    
    /// Indica si está sincronizando con el backend
    @Published private(set) var isSyncing = false
    
    /// Error de la última operación
    @Published var lastError: String?
    
    // MARK: - Private Properties
    
    private let apolloClient = ApolloClientManager.shared.apollo
    private let cacheKey = "BusinessTypeConfigs"
    private let lastSyncKey = "BusinessTypeConfigsLastSync"
    private let modelVersionsKey = "BusinessTypeModelVersions"
    
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private var observations: [String: NSKeyValueObservation] = [:]
    
    // MARK: - Initialization
    
    private init() {
        loadFromCache()
        updateDownloadStates()
    }
    
    // MARK: - Public Methods
    
    /// Sincroniza con el backend (llamar al iniciar app y cuando llega push)
    func syncWithBackend() async {
        guard !isSyncing else { return }
        isSyncing = true
        lastError = nil
        
        defer { isSyncing = false }
        
        do {
            let configs = try await fetchBusinessTypeConfigs()
            
            // Merge con los existentes
            var updatedTypes = businessTypes
            
            for config in configs {
                if let existingIndex = updatedTypes.firstIndex(where: { $0.id == config.id }) {
                    // Actualizar existente
                    let existing = updatedTypes[existingIndex]
                    updatedTypes[existingIndex] = config
                    
                    // Si cambió la versión del modelo, marcar para re-descarga
                    if existing.model3dVersion != config.model3dVersion && !config.isLocalBundle {
                        downloadStates[config.key] = .notDownloaded
                        // Eliminar modelo viejo
                        deleteDownloadedModel(for: config)
                    }
                } else {
                    // Nuevo tipo
                    updatedTypes.append(config)
                    if !config.isLocalBundle {
                        downloadStates[config.key] = .notDownloaded
                    }
                }
            }
            
            // Ordenar por sortOrder
            updatedTypes.sort { $0.sortOrder < $1.sortOrder }
            
            // Filtrar solo activos
            businessTypes = updatedTypes.filter { $0.isActive }
            
            // Guardar en cache
            saveToCache()
            saveLastSyncDate()
            updateDownloadStates()
            
        } catch {
            lastError = error.localizedDescription
            print("❌ BusinessTypeConfigManager sync error: \(error)")
        }
    }
    
    /// Descarga el modelo 3D de un tipo de negocio
    func downloadModel3D(for config: BusinessTypeConfig) {
        guard let urlString = config.model3dUrl,
              let url = URL(string: urlString) else {
            downloadStates[config.key] = .failed("URL inválida")
            return
        }
        
        // Cancelar descarga previa si existe
        cancelDownload(for: config.key)
        
        downloadStates[config.key] = .downloading(0)
        
        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let error = error {
                    self.downloadStates[config.key] = .failed(error.localizedDescription)
                    return
                }
                
                guard let tempURL = tempURL else {
                    self.downloadStates[config.key] = .failed("No se recibió el archivo")
                    return
                }
                
                // Mover a directorio de modelos
                let destinationURL = BusinessTypeConfig.downloadedModelsDirectory
                    .appendingPathComponent(config.model3dFileName)
                
                do {
                    // Eliminar si ya existe
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    
                    try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                    
                    self.downloadStates[config.key] = .downloaded
                    self.saveModelVersion(config.key, version: config.model3dVersion)
                    
                    print("✅ Modelo 3D descargado: \(config.model3dFileName)")
                    
                } catch {
                    self.downloadStates[config.key] = .failed(error.localizedDescription)
                    print("❌ Error guardando modelo: \(error)")
                }
                
                self.downloadTasks.removeValue(forKey: config.key)
                self.observations.removeValue(forKey: config.key)
            }
        }
        
        // Observar progreso
        let observation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            Task { @MainActor [weak self] in
                self?.downloadStates[config.key] = .downloading(progress.fractionCompleted)
            }
        }
        
        downloadTasks[config.key] = task
        observations[config.key] = observation
        
        task.resume()
    }
    
    /// Cancela la descarga de un modelo
    func cancelDownload(for key: String) {
        downloadTasks[key]?.cancel()
        downloadTasks.removeValue(forKey: key)
        observations.removeValue(forKey: key)
    }
    
    /// Elimina un modelo descargado
    func deleteDownloadedModel(for config: BusinessTypeConfig) {
        guard !config.isLocalBundle else { return }
        
        let fileURL = BusinessTypeConfig.downloadedModelsDirectory
            .appendingPathComponent(config.model3dFileName)
        
        try? FileManager.default.removeItem(at: fileURL)
        downloadStates[config.key] = .notDownloaded
        removeModelVersion(config.key)
        
        print("🗑️ Modelo eliminado: \(config.model3dFileName)")
    }
    
    /// Obtiene el tipo de negocio por índice
    func getBusinessType(at index: Int) -> BusinessTypeConfig? {
        guard index >= 0 && index < businessTypes.count else { return nil }
        return businessTypes[index]
    }
    
    /// Obtiene el tipo de negocio por key
    func getBusinessType(byKey key: String) -> BusinessTypeConfig? {
        businessTypes.first { $0.key == key }
    }
    
    /// Obtiene las features para un índice dado
    func getFeatures(at index: Int) -> [Feature] {
        guard let config = getBusinessType(at: index) else { return [] }
        return config.features
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { $0.toFeature() }
    }
    
    /// Obtiene el color de glow para un índice dado
    func getGlowColor(at index: Int) -> Color {
        guard let config = getBusinessType(at: index) else {
            return Color(red: 0.9, green: 0.3, blue: 0.2)
        }
        return config.glowSwiftUIColor
    }
    
    /// Obtiene la paleta de colores del gradiente para un índice dado
    func getGradientPalette(at index: Int) -> (dark: Color, medium: Color, light: Color, veryLight: Color, overlay: Color) {
        guard let config = getBusinessType(at: index) else {
            // Default: Restaurantes
            return (
                dark: Color(red: 0.5, green: 0.15, blue: 0.1),
                medium: Color(red: 0.7, green: 0.25, blue: 0.15),
                light: Color(red: 0.85, green: 0.45, blue: 0.3),
                veryLight: Color(red: 0.95, green: 0.88, blue: 0.85),
                overlay: Color(red: 0.45, green: 0.12, blue: 0.08)
            )
        }
        return config.gradient.colorPalette
    }
    
    /// Verifica si un tipo necesita descarga
    func needsDownload(at index: Int) -> Bool {
        guard let config = getBusinessType(at: index) else { return false }
        if config.isLocalBundle { return false }
        return downloadStates[config.key] == .notDownloaded
    }
    
    /// Obtiene el estado de descarga para un índice
    func getDownloadState(at index: Int) -> Model3DDownloadState {
        guard let config = getBusinessType(at: index) else { return .notNeeded }
        if config.isLocalBundle { return .notNeeded }
        return downloadStates[config.key] ?? .notDownloaded
    }
    
    /// Tamaño total de modelos descargados
    func getDownloadedModelsSize() -> Int64 {
        let directory = BusinessTypeConfig.downloadedModelsDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: directory.path) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        for file in files {
            let filePath = directory.appendingPathComponent(file).path
            if let attributes = try? FileManager.default.attributesOfItem(atPath: filePath),
               let size = attributes[.size] as? Int64 {
                totalSize += size
            }
        }
        return totalSize
    }
    
    /// Lista de tipos descargados (para mostrar en Profile)
    func getDownloadedTypes() -> [BusinessTypeConfig] {
        businessTypes.filter { config in
            !config.isLocalBundle && downloadStates[config.key] == .downloaded
        }
    }
}

// MARK: - Private Methods

private extension BusinessTypeConfigManager {
    
    func fetchBusinessTypeConfigs() async throws -> [BusinessTypeConfig] {
        try await withCheckedThrowingContinuation { continuation in
            let lastSync = getLastSyncDate()
            let query = LlegoAPI.GetBusinessTypeConfigsQuery(lastSyncAt: lastSync.map { .some($0) } ?? .none)
            
            apolloClient.fetchCompat(query: query, cachePolicy: .fetchIgnoringCacheData) { result in
                switch result {
                case .success(let graphQLResult):
                    guard let data = graphQLResult.data else {
                        continuation.resume(throwing: NSError(domain: "BusinessTypeConfig", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"]))
                        return
                    }
                    
                    let configs = data.businessTypeConfigs.map { item -> BusinessTypeConfig in
                        let gradient = GradientConfig(
                            darkColor: item.gradient.darkColor,
                            mediumColor: item.gradient.mediumColor,
                            lightColor: item.gradient.lightColor,
                            veryLightColor: item.gradient.veryLightColor,
                            overlayColor: item.gradient.overlayColor
                        )
                        
                        let camera = CameraConfig(
                            positionX: Float(item.camera.positionX),
                            positionY: Float(item.camera.positionY),
                            positionZ: Float(item.camera.positionZ),
                            eulerX: item.camera.eulerX.map { Float($0) },
                            eulerY: item.camera.eulerY.map { Float($0) },
                            eulerZ: item.camera.eulerZ.map { Float($0) }
                        )
                        
                        let features = item.features.map { f in
                            FeatureConfig(
                                icon: f.icon,
                                title: f.title,
                                subtitle: f.subtitle,
                                sortOrder: f.sortOrder
                            )
                        }
                        
                        let dateFormatter = ISO8601DateFormatter()
                        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        
                        return BusinessTypeConfig(
                            id: item.id,
                            key: item.key,
                            name: item.name,
                            description: item.description,
                            icon: item.icon,
                            model3dFileName: item.model3dFileName,
                            model3dUrl: item.model3dUrl,
                            model3dVersion: item.model3dVersion,
                            gradient: gradient,
                            camera: camera,
                            glowColor: item.glowColor,
                            features: features,
                            sortOrder: item.sortOrder,
                            isActive: item.isActive,
                            createdAt: dateFormatter.date(from: item.createdAt) ?? Date(),
                            updatedAt: dateFormatter.date(from: item.updatedAt) ?? Date()
                        )
                    }
                    
                    continuation.resume(returning: configs)
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func loadFromCache() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let configs = try? JSONDecoder().decode([BusinessTypeConfig].self, from: data) else {
            return
        }
        businessTypes = configs.filter { $0.isActive }.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    func saveToCache() {
        guard let data = try? JSONEncoder().encode(businessTypes) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
    }
    
    func getLastSyncDate() -> String? {
        UserDefaults.standard.string(forKey: lastSyncKey)
    }
    
    func saveLastSyncDate() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        UserDefaults.standard.set(formatter.string(from: Date()), forKey: lastSyncKey)
    }
    
    func updateDownloadStates() {
        for config in businessTypes {
            if config.isLocalBundle {
                downloadStates[config.key] = .notNeeded
            } else if config.isModel3DAvailable {
                // Verificar versión
                let savedVersion = getModelVersion(config.key)
                if savedVersion == config.model3dVersion {
                    downloadStates[config.key] = .downloaded
                } else {
                    downloadStates[config.key] = .notDownloaded
                }
            } else {
                downloadStates[config.key] = .notDownloaded
            }
        }
    }
    
    func getModelVersion(_ key: String) -> Int {
        let versions = UserDefaults.standard.dictionary(forKey: modelVersionsKey) as? [String: Int] ?? [:]
        return versions[key] ?? 0
    }
    
    func saveModelVersion(_ key: String, version: Int) {
        var versions = UserDefaults.standard.dictionary(forKey: modelVersionsKey) as? [String: Int] ?? [:]
        versions[key] = version
        UserDefaults.standard.set(versions, forKey: modelVersionsKey)
    }
    
    func removeModelVersion(_ key: String) {
        var versions = UserDefaults.standard.dictionary(forKey: modelVersionsKey) as? [String: Int] ?? [:]
        versions.removeValue(forKey: key)
        UserDefaults.standard.set(versions, forKey: modelVersionsKey)
    }
}
