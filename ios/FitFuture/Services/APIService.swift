import Foundation
import Combine

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int, String)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .networkError(let e): return e.localizedDescription
        case .decodingError(let e): return e.localizedDescription
        case .serverError(let code, let msg): return "Server error \(code): \(msg)"
        case .unauthorized: return "Session expired. Please sign in again."
        }
    }
}

final class APIService {
    static let shared = APIService()
    private let baseURL: String
    private var authToken: String?

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.tlsMinimumSupportedProtocolVersion = .TLSv13
        return URLSession(configuration: config)
    }()

    private init() {
        baseURL = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
            ?? "https://api.fitfuture.app"
    }

    func setAuthToken(_ token: String) {
        self.authToken = token
    }

    // MARK: - Auth

    func signInWithApple(identityToken: String) async throws -> AuthResponse {
        try await post("/api/auth/apple", body: ["identityToken": identityToken])
    }

    func register(email: String, password: String, displayName: String?) async throws -> AuthResponse {
        var body: [String: Any] = ["email": email, "password": password]
        if let name = displayName { body["displayName"] = name }
        return try await post("/api/auth/register", body: body)
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        try await post("/api/auth/login", body: ["email": email, "password": password])
    }

    #if DEBUG
    func devSignIn() async throws -> AuthResponse {
        try await post("/api/auth/dev", body: [:])
    }
    #endif

    // MARK: - Photos

    func uploadBaselinePhoto(userId: String, imageData: Data) async throws -> Photo {
        try await uploadMultipart("/api/users/\(userId)/photo/baseline", imageData: imageData)
    }

    // MARK: - AI Jobs

    func createAIJob(userId: String, baselinePhotoId: String, goalType: String,
                     goalMonths: Int, trainingDays: Int) async throws -> AIJob {
        try await post("/api/jobs", body: [
            "userId": userId,
            "baselinePhotoId": baselinePhotoId,
            "goalType": goalType,
            "goalMonths": goalMonths,
            "trainingDaysPerWeek": trainingDays
        ])
    }

    func pollAIJob(jobId: String) async throws -> AIJob {
        try await get("/api/jobs/\(jobId)")
    }

    // MARK: - Check-ins

    func createCheckIn(userId: String, imageData: Data, weightKg: Double?) async throws -> CheckIn {
        var fields: [String: Any] = ["userId": userId]
        if let w = weightKg { fields["weightKg"] = w }
        return try await uploadMultipart("/api/check-ins", imageData: imageData, fields: fields)
    }

    func fetchCheckIns(userId: String) async throws -> [CheckIn] {
        try await get("/api/check-ins/\(userId)")
    }

    // MARK: - Private helpers

    private func request<T: Decodable>(_ urlRequest: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }
        if http.statusCode == 401 { throw APIError.unauthorized }
        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(http.statusCode, msg)
        }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        if let token = authToken { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        return try await request(req)
    }

    private func post<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await request(req)
    }

    private func uploadMultipart<T: Decodable>(_ path: String, imageData: Data,
                                               fields: [String: Any] = [:]) async throws -> T {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        let boundary = UUID().uuidString
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token = authToken { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

        var body = Data()
        for (key, value) in fields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        return try await request(req)
    }
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}
