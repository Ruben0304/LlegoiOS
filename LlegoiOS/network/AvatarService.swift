import Foundation
import UIKit

struct AvatarUploadResponse: Codable {
    let id: String
    let avatar: String
    let avatarUrl: String
    
    enum CodingKeys: String, CodingKey {
        case id, avatar
        case avatarUrl = "avatar_url"
    }
}

@MainActor
class AvatarService {
    static let shared = AvatarService()
    
    private init() {}
    
    func uploadAvatar(image: UIImage) async throws -> AvatarUploadResponse {
        guard let token = AuthManager.shared.getAccessToken() else {
            throw NSError(domain: "AvatarService", code: 401, userInfo: [NSLocalizedDescriptionKey: "No hay sesión activa"])
        }
        
        // Comprimir imagen a JPEG
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "AvatarService", code: 400, userInfo: [NSLocalizedDescriptionKey: "No se pudo procesar la imagen"])
        }
        
        // Crear URL
        guard let url = URL(string: "\(ApolloClientManager.baseURL)/users/avatar") else {
            throw NSError(domain: "AvatarService", code: 400, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])
        }
        
        // Crear request
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Crear boundary para multipart
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Crear body multipart
        var body = Data()
        
        // Agregar imagen
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Ejecutar request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AvatarService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Respuesta inválida del servidor"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Error desconocido"
            throw NSError(domain: "AvatarService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Error al subir avatar: \(errorMessage)"])
        }
        
        // Decodificar respuesta
        let decoder = JSONDecoder()
        let uploadResponse = try decoder.decode(AvatarUploadResponse.self, from: data)
        
        return uploadResponse
    }
}
