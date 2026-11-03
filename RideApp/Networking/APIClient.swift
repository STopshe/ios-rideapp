import Foundation

enum APIError: Error {
    case invalidURL
    case noResponse
    case decodingError(Error)
    case serverError(Int)
    case unauthorized
}

class APIClient {
    static let shared = APIClient()
    private let session: URLSession
    private let baseURL: URL
    private let tokenKey = "auth_token"

    init(session: URLSession = .shared,
         baseURL: URL = URL(string: "https://api.rideapp.example.com/v1")!) {
        self.session = session
        self.baseURL = baseURL
    }

    private var authToken: String? {
        KeychainWrapper.shared.string(forKey: tokenKey)
    }

    func request<T: Decodable>(_ endpoint: Endpoint,
                               method: HTTPMethod = .get,
                               body: Data? = nil,
                               completion: @escaping (Result<T, APIError>) -> Void) {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        ) else {
            completion(.failure(.invalidURL))
            return
        }
        components.queryItems = endpoint.queryItems
        guard let url = components.url else {
            completion(.failure(.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body { request.httpBody = body }
        let task = session.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.noResponse))
                return
            }
            if httpResponse.statusCode == 401 {
                completion(.failure(.unauthorized))
                return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(.serverError(httpResponse.statusCode)))
                return
            }
            guard let data = data else {
                completion(.failure(.noResponse))
                return
            }
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }
        task.resume()
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum Endpoint {
    case login(email: String, password: String)
    case getRides(page: Int)
    case getDriver(id: String)
    case trackRide(id: String)
    case requestRide(pickup: Location, dropoff: Location)

    var path: String {
        switch self {
        case .login: return "/auth/login"
        case .getRides: return "/rides"
        case .getDriver(let id): return "/drivers/\(id)"
        case .trackRide(let id): return "/rides/\(id)/track"
        case .requestRide: return "/rides"
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .getRides(let page):
            return [URLQueryItem(name: "page", value: String(page)),
                    URLQueryItem(name: "per_page", value: "20")]
        default: return nil
        }
    }
}
