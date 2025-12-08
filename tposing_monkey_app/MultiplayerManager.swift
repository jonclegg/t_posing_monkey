import Foundation

class MultiplayerManager {
    static let shared = MultiplayerManager()
    
    private let apiBaseUrl = "https://sywv2zkbma.execute-api.us-east-1.amazonaws.com/prod"
    
    struct RoomPlayer: Codable {
        let name: String
        let x: Double
        let y: Double
        let connected: Bool
    }
    
    struct RoomMonkey: Codable {
        let x: Double
        let y: Double
    }
    
    struct RoomLarry: Codable {
        let visible: Bool
        let x: Double
        let y: Double
        let frozen: Bool
    }
    
    struct RoomState: Codable {
        let roomCode: String
        let mapType: String?
        let hostPlayerId: String?
        let monkeyPlayerId: String?
        let player1: RoomPlayer?
        let player2: RoomPlayer?
        let monkey: RoomMonkey?
        let larry: RoomLarry?
        let gameState: String?
        let score: Int?
    }
    
    struct CreateRoomResponse: Codable {
        let roomCode: String
        let playerId: String
    }
    
    struct JoinRoomResponse: Codable {
        let roomCode: String
        let playerId: String
        let mapType: String?
    }
    
    struct ErrorResponse: Codable {
        let error: String
    }
    
    struct StartGameResponse: Codable {
        let status: String
        let monkeyPlayerId: String
    }

    private init() {}

    func createRoom(playerName: String, mapType: String, completion: @escaping (Result<CreateRoomResponse, Error>) -> Void) {
        guard let url = URL(string: "\(apiBaseUrl)/rooms") else {
            completion(.failure(NSError(domain: "MultiplayerError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["playerName": playerName, "mapType": mapType]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "MultiplayerError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(CreateRoomResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func joinRoom(roomCode: String, playerName: String, completion: @escaping (Result<JoinRoomResponse, Error>) -> Void) {
        guard let url = URL(string: "\(apiBaseUrl)/rooms/\(roomCode)") else {
            completion(.failure(NSError(domain: "MultiplayerError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["action": "join", "playerName": playerName]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "MultiplayerError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                completion(.failure(NSError(domain: "MultiplayerError", code: 3, userInfo: [NSLocalizedDescriptionKey: errorResponse.error])))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(JoinRoomResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func getRoomState(roomCode: String, completion: @escaping (Result<RoomState, Error>) -> Void) {
        guard let url = URL(string: "\(apiBaseUrl)/rooms/\(roomCode)") else {
            completion(.failure(NSError(domain: "MultiplayerError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "MultiplayerError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                completion(.failure(NSError(domain: "MultiplayerError", code: 3, userInfo: [NSLocalizedDescriptionKey: errorResponse.error])))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(RoomState.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func updateRoomState(roomCode: String, playerId: String, myPosition: CGPoint, monkey: CGPoint? = nil, larry: (visible: Bool, x: Double, y: Double, frozen: Bool)? = nil, score: Int? = nil, gameState: String? = nil, completion: @escaping (Result<RoomState, Error>) -> Void) {
        guard let url = URL(string: "\(apiBaseUrl)/rooms/\(roomCode)") else {
            completion(.failure(NSError(domain: "MultiplayerError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "playerId": playerId,
            "myPosition": ["x": myPosition.x, "y": myPosition.y]
        ]
        
        if let monkey = monkey {
            body["monkey"] = ["x": monkey.x, "y": monkey.y]
        }
        
        if let larry = larry {
            body["larry"] = ["visible": larry.visible, "x": larry.x, "y": larry.y, "frozen": larry.frozen]
        }
        
        if let score = score {
            body["score"] = score
        }
        
        if let gameState = gameState {
            body["gameState"] = gameState
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "MultiplayerError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(RoomState.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func startGame(roomCode: String, completion: @escaping (Result<StartGameResponse, Error>) -> Void) {
        guard let url = URL(string: "\(apiBaseUrl)/rooms/\(roomCode)") else {
            completion(.failure(NSError(domain: "MultiplayerError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["action": "start"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "MultiplayerError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(StartGameResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func restartGame(roomCode: String, completion: @escaping (Result<StartGameResponse, Error>) -> Void) {
        guard let url = URL(string: "\(apiBaseUrl)/rooms/\(roomCode)") else {
            completion(.failure(NSError(domain: "MultiplayerError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["action": "restart"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "MultiplayerError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(StartGameResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func deleteRoom(roomCode: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(apiBaseUrl)/rooms/\(roomCode)") else {
            completion(.failure(NSError(domain: "MultiplayerError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }.resume()
    }
}

