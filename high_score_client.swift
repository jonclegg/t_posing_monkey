import Foundation

class HighScoreManager {
    private let apiBaseUrl = "https://sywv2zkbma.execute-api.us-east-1.amazonaws.com/prod"
    
    // Score model
    struct Score: Codable {
        let playerName: String
        let score: Int
        let id: String?
        let timestamp: String?
    }
    
    // Get scores response
    struct ScoresResponse: Codable {
        let scores: [Score]
    }
    
    // Save score response
    struct SaveScoreResponse: Codable {
        let message: String
        let scoreId: String
    }
    
    // Submit a new score
    func submitScore(playerName: String, score: Int, completion: @escaping (Result<SaveScoreResponse, Error>) -> Void) {
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
        
        let scoreData = Score(playerName: playerName, score: score, id: nil, timestamp: nil)
        
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
                    let response = try JSONDecoder().decode(SaveScoreResponse.self, from: data)
                    completion(.success(response))
                } catch {
                    completion(.failure(error))
                }
            }.resume()
        } catch {
            completion(.failure(error))
        }
    }
    
    // Get high scores
    func getHighScores(limit: Int = 10, completion: @escaping (Result<[Score], Error>) -> Void) {
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
                let response = try JSONDecoder().decode(ScoresResponse.self, from: data)
                completion(.success(response.scores))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
} 