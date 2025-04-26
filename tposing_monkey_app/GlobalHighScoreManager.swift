import Foundation

class GlobalHighScoreManager {
    private let apiBaseUrl = "https://sywv2zkbma.execute-api.us-east-1.amazonaws.com/prod"
    
    // API Models
    struct ApiScore: Codable {
        let playerName: String
        let score: Int
        let id: String?
        let timestamp: String?
    }
    
    struct ApiScoresResponse: Codable {
        let scores: [ApiScore]
    }
    
    struct ApiSaveScoreResponse: Codable {
        let message: String
        let scoreId: String
    }
    
    // Convert API score to game's HighScore format
    func convertToHighScore(_ apiScore: ApiScore) -> HighScore {
        return HighScore(
            initials: apiScore.playerName.count <= 3 ? apiScore.playerName : String(apiScore.playerName.prefix(3)),
            score: apiScore.score,
            date: apiScore.timestamp != nil ? ISO8601DateFormatter().date(from: apiScore.timestamp!) ?? Date() : Date()
        )
    }
    
    // Get global high scores
    func getGlobalHighScores(limit: Int = 10, completion: @escaping (Result<[HighScore], Error>) -> Void) {
        guard limit > 0 && limit <= 100 else {
            completion(.failure(NSError(domain: "HighScoreError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Limit must be between 1 and 100"])))
            return
        }
        
        guard let url = URL(string: "\(apiBaseUrl)/scores?limit=\(limit)") else {
            completion(.failure(NSError(domain: "HighScoreError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "HighScoreError", code: 3, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(ApiScoresResponse.self, from: data)
                let highScores = response.scores.map { self.convertToHighScore($0) }
                completion(.success(highScores))
            } catch {
                print("Decoding error: \(error)")
                print("Response: \(String(data: data, encoding: .utf8) ?? "none")")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Submit a global high score
    func submitGlobalScore(playerName: String, score: Int, completion: @escaping (Result<ApiSaveScoreResponse, Error>) -> Void) {
        guard !playerName.isEmpty else { 
            completion(.failure(NSError(domain: "HighScoreError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Player name cannot be empty"])))
            return
        }
        
        guard let url = URL(string: "\(apiBaseUrl)/scores") else {
            completion(.failure(NSError(domain: "HighScoreError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let scoreData = ApiScore(playerName: playerName, score: score, id: nil, timestamp: nil)
        
        do {
            let jsonData = try JSONEncoder().encode(scoreData)
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NSError(domain: "HighScoreError", code: 3, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(ApiSaveScoreResponse.self, from: data)
                    completion(.success(response))
                } catch {
                    print("Decoding error: \(error)")
                    print("Response: \(String(data: data, encoding: .utf8) ?? "none")")
                    completion(.failure(error))
                }
            }.resume()
        } catch {
            completion(.failure(error))
        }
    }
} 