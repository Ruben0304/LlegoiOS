import Foundation
import Combine

@MainActor
final class TutorialDownloadManager: NSObject, ObservableObject {
    static let shared = TutorialDownloadManager()

    enum DownloadStatus: Equatable {
        case notDownloaded
        case downloading(Double)
        case downloaded(URL)
        case failed(String)
    }

    private struct StoredDownload: Codable {
        let fileName: String
        let sourceURL: String
        let downloadedAt: Date
    }

    @Published private(set) var statuses: [String: DownloadStatus] = [:]

    private var session: URLSession!
    private var activeTasksByTutorialId: [String: URLSessionDownloadTask] = [:]
    private var tutorialIdByTaskIdentifier: [Int: String] = [:]
    private var sourceURLByTutorialId: [String: URL] = [:]
    private var storedDownloads: [String: StoredDownload] = [:]

    private let downloadsDirectoryURL: URL
    private let manifestURL: URL
    private let fileManager = FileManager.default
    private let logPrefix = "📥 TutorialDownload"

    override private init() {
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let baseDirectoryURL = appSupportURL.appendingPathComponent("TutorialDownloads", isDirectory: true)
        self.downloadsDirectoryURL = baseDirectoryURL
        self.manifestURL = baseDirectoryURL.appendingPathComponent("manifest.json")
        super.init()

        let configuration = URLSessionConfiguration.default
        configuration.allowsExpensiveNetworkAccess = true
        configuration.allowsConstrainedNetworkAccess = true
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)

        ensureDownloadDirectoryExists()
        loadManifest()
        restoreStatusesFromStoredDownloads()
        log("Manager inicializado. Carpeta: \(downloadsDirectoryURL.path)")
    }

    func status(for tutorialId: String) -> DownloadStatus {
        statuses[tutorialId] ?? .notDownloaded
    }

    func isDownloaded(_ tutorialId: String) -> Bool {
        if case .downloaded = status(for: tutorialId) {
            return true
        }
        return false
    }

    func isDownloading(_ tutorialId: String) -> Bool {
        if case .downloading = status(for: tutorialId) {
            return true
        }
        return false
    }

    func progress(for tutorialId: String) -> Double {
        if case .downloading(let progress) = status(for: tutorialId) {
            return progress
        }
        return 0
    }

    func playbackURL(for tutorial: Tutorial) -> URL? {
        if case .downloaded(let localURL) = status(for: tutorial.id),
           fileManager.fileExists(atPath: localURL.path) {
            log("Playback local para \(tutorial.id): \(localURL.lastPathComponent)")
            return localURL
        }
        log("Playback streaming para \(tutorial.id)")
        return URL(string: tutorial.videoUrl)
    }

    func startDownload(for tutorial: Tutorial) {
        let tutorialId = tutorial.id

        if isDownloaded(tutorialId) || isDownloading(tutorialId) {
            log("Saltando descarga para \(tutorialId): ya descargado o en curso")
            return
        }

        guard let remoteURL = URL(string: tutorial.videoUrl) else {
            log("Error URL inválida para \(tutorialId): \(tutorial.videoUrl)")
            statuses[tutorialId] = .failed("URL de video inválida")
            return
        }

        let task = session.downloadTask(with: remoteURL)
        activeTasksByTutorialId[tutorialId] = task
        tutorialIdByTaskIdentifier[task.taskIdentifier] = tutorialId
        sourceURLByTutorialId[tutorialId] = remoteURL
        statuses[tutorialId] = .downloading(0)
        log("Iniciando descarga \(tutorialId) task=\(task.taskIdentifier) url=\(remoteURL.absoluteString)")
        task.resume()
    }

    func cancelDownload(for tutorialId: String) {
        guard let task = activeTasksByTutorialId[tutorialId] else { return }

        log("Cancelando descarga \(tutorialId) task=\(task.taskIdentifier)")
        task.cancel()
        removeTaskMappings(for: task.taskIdentifier)
        sourceURLByTutorialId[tutorialId] = nil

        if let stored = storedDownloads[tutorialId] {
            statuses[tutorialId] = .downloaded(localURL(from: stored))
        } else {
            statuses[tutorialId] = .notDownloaded
        }
    }

    func deleteDownload(for tutorialId: String) {
        if let task = activeTasksByTutorialId[tutorialId] {
            log("Eliminando descarga activa \(tutorialId) task=\(task.taskIdentifier)")
            task.cancel()
            removeTaskMappings(for: task.taskIdentifier)
        }

        if let stored = storedDownloads[tutorialId] {
            let fileURL = localURL(from: stored)
            log("Eliminando archivo descargado \(tutorialId): \(fileURL.lastPathComponent)")
            try? fileManager.removeItem(at: fileURL)
            storedDownloads[tutorialId] = nil
            saveManifest()
        }

        sourceURLByTutorialId[tutorialId] = nil
        statuses[tutorialId] = .notDownloaded
    }

    private func ensureDownloadDirectoryExists() {
        if !fileManager.fileExists(atPath: downloadsDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: downloadsDirectoryURL, withIntermediateDirectories: true)
                log("Carpeta de descargas creada")
            } catch {
                log("Error creando carpeta de descargas: \(error.localizedDescription)")
            }
        }
    }

    private func restoreStatusesFromStoredDownloads() {
        log("Restaurando manifest con \(storedDownloads.count) elementos")
        for (tutorialId, stored) in storedDownloads {
            let fileURL = localURL(from: stored)
            if fileManager.fileExists(atPath: fileURL.path) {
                statuses[tutorialId] = .downloaded(fileURL)
                log("Restaurado \(tutorialId) -> \(fileURL.lastPathComponent)")
            } else {
                log("Archivo faltante para \(tutorialId), limpiando manifest")
                storedDownloads[tutorialId] = nil
            }
        }
        saveManifest()
    }

    private func destinationURL(for tutorialId: String, sourceURL: URL) -> URL {
        let pathExtension = sourceURL.pathExtension.isEmpty ? "mp4" : sourceURL.pathExtension
        let sanitizedId = tutorialId.replacingOccurrences(of: "/", with: "_")
        return downloadsDirectoryURL.appendingPathComponent("\(sanitizedId).\(pathExtension)")
    }

    private func localURL(from stored: StoredDownload) -> URL {
        downloadsDirectoryURL.appendingPathComponent(stored.fileName)
    }

    private func loadManifest() {
        guard let data = try? Data(contentsOf: manifestURL),
              let decoded = try? JSONDecoder().decode([String: StoredDownload].self, from: data) else {
            storedDownloads = [:]
            log("Manifest no encontrado o inválido, iniciando vacío")
            return
        }
        storedDownloads = decoded
        log("Manifest cargado con \(decoded.count) elementos")
    }

    private func saveManifest() {
        guard let data = try? JSONEncoder().encode(storedDownloads) else { return }
        do {
            try data.write(to: manifestURL, options: .atomic)
        } catch {
            log("Error guardando manifest: \(error.localizedDescription)")
        }
    }

    private func removeTaskMappings(for taskIdentifier: Int) {
        if let tutorialId = tutorialIdByTaskIdentifier[taskIdentifier] {
            activeTasksByTutorialId[tutorialId] = nil
            log("Liberando task \(taskIdentifier) para \(tutorialId)")
        }
        tutorialIdByTaskIdentifier[taskIdentifier] = nil
    }

    private func handleDownloadFinished(taskIdentifier: Int, temporaryFileURL: URL) {
        guard let tutorialId = tutorialIdByTaskIdentifier[taskIdentifier],
              let sourceURL = sourceURLByTutorialId[tutorialId] else {
            log("didFinish sin mapeo. task=\(taskIdentifier)")
            removeTaskMappings(for: taskIdentifier)
            return
        }

        let destination = destinationURL(for: tutorialId, sourceURL: sourceURL)
        log("didFinish task=\(taskIdentifier) tutorial=\(tutorialId) temp=\(temporaryFileURL.lastPathComponent) dest=\(destination.lastPathComponent)")

        do {
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.moveItem(at: temporaryFileURL, to: destination)
        } catch {
            log("moveItem falló para \(tutorialId): \(error.localizedDescription). Intentando copyItem")
            do {
                if fileManager.fileExists(atPath: destination.path) {
                    try fileManager.removeItem(at: destination)
                }
                try fileManager.copyItem(at: temporaryFileURL, to: destination)
            } catch {
                statuses[tutorialId] = .failed("No se pudo guardar la descarga: \(error.localizedDescription)")
                log("copyItem también falló para \(tutorialId): \(error.localizedDescription)")
                sourceURLByTutorialId[tutorialId] = nil
                removeTaskMappings(for: taskIdentifier)
                return
            }
        }

        do {
            let attributes = try fileManager.attributesOfItem(atPath: destination.path)
            let fileSize = (attributes[.size] as? NSNumber)?.int64Value ?? 0
            log("Archivo guardado \(tutorialId): \(destination.lastPathComponent) size=\(fileSize) bytes")
        } catch {
            log("No se pudieron leer atributos del archivo \(tutorialId): \(error.localizedDescription)")
        }

        storedDownloads[tutorialId] = StoredDownload(
            fileName: destination.lastPathComponent,
            sourceURL: sourceURL.absoluteString,
            downloadedAt: Date()
        )
        saveManifest()
        statuses[tutorialId] = .downloaded(destination)
        log("Descarga completada \(tutorialId) ✅")

        sourceURLByTutorialId[tutorialId] = nil
        removeTaskMappings(for: taskIdentifier)
    }

    private func handleDownloadProgress(taskIdentifier: Int, progress: Double) {
        guard let tutorialId = tutorialIdByTaskIdentifier[taskIdentifier] else { return }
        statuses[tutorialId] = .downloading(progress)
        if progress >= 1.0 {
            log("Progreso 100% task=\(taskIdentifier) tutorial=\(tutorialId), esperando guardado...")
        }
    }

    private func handleDownloadCompletion(taskIdentifier: Int, error: Error?) {
        guard let tutorialId = tutorialIdByTaskIdentifier[taskIdentifier] else { return }
        defer {
            sourceURLByTutorialId[tutorialId] = nil
            removeTaskMappings(for: taskIdentifier)
        }

        guard let error = error else {
            log("didComplete sin error task=\(taskIdentifier) tutorial=\(tutorialId)")
            return
        }

        if let stored = storedDownloads[tutorialId] {
            statuses[tutorialId] = .downloaded(localURL(from: stored))
            log("didComplete con error pero archivo existe \(tutorialId): \(error.localizedDescription)")
        } else {
            statuses[tutorialId] = .failed(error.localizedDescription)
            log("didComplete error \(tutorialId): \(error.localizedDescription)")
        }
    }

    private func handleStagingFailure(taskIdentifier: Int, reason: String) {
        guard let tutorialId = tutorialIdByTaskIdentifier[taskIdentifier] else { return }
        statuses[tutorialId] = .failed(reason)
        sourceURLByTutorialId[tutorialId] = nil
        removeTaskMappings(for: taskIdentifier)
        log("Fallo en staging para \(tutorialId): \(reason)")
    }

    private func log(_ message: String) {
        print("\(logPrefix) \(message)")
    }
}

extension TutorialDownloadManager: URLSessionDownloadDelegate {
    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        if progress >= 1.0 {
            print("📥 TutorialDownload delegate progress task=\(downloadTask.taskIdentifier) 100%")
        }
        Task { @MainActor [weak self] in
            self?.handleDownloadProgress(taskIdentifier: downloadTask.taskIdentifier, progress: progress)
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        print("📥 TutorialDownload delegate didFinish task=\(downloadTask.taskIdentifier) temp=\(location.lastPathComponent)")

        // El archivo `location` puede desaparecer justo al salir de este callback,
        // por eso lo copiamos/movemos inmediatamente a una ruta de staging estable.
        let stagingURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("tutorial-stage-\(downloadTask.taskIdentifier)-\(UUID().uuidString).tmp")

        do {
            try FileManager.default.moveItem(at: location, to: stagingURL)
            print("📥 TutorialDownload staged temp -> \(stagingURL.lastPathComponent)")
        } catch {
            do {
                try FileManager.default.copyItem(at: location, to: stagingURL)
                print("📥 TutorialDownload staged by copy -> \(stagingURL.lastPathComponent)")
            } catch {
                print("📥 TutorialDownload staging FAILED task=\(downloadTask.taskIdentifier) error=\(error.localizedDescription)")
                Task { @MainActor [weak self] in
                    self?.handleStagingFailure(
                        taskIdentifier: downloadTask.taskIdentifier,
                        reason: "No se pudo preparar el archivo temporal: \(error.localizedDescription)"
                    )
                }
                return
            }
        }

        Task { @MainActor [weak self] in
            self?.handleDownloadFinished(taskIdentifier: downloadTask.taskIdentifier, temporaryFileURL: stagingURL)
        }
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            print("📥 TutorialDownload delegate didCompleteWithError task=\(task.taskIdentifier) error=\(error.localizedDescription)")
        } else {
            print("📥 TutorialDownload delegate didComplete task=\(task.taskIdentifier)")
            return
        }
        Task { @MainActor [weak self] in
            self?.handleDownloadCompletion(taskIdentifier: task.taskIdentifier, error: error)
        }
    }
}
