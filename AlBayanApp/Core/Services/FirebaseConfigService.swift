import Foundation
import os.log

/// Result of fetching remote configuration from Firebase.
public enum ConfigFetchError: LocalizedError {
    case invalidEndpoint
    case networkError(String)
    case invalidData(String)
    case urlNotFound
    
    public var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            return "Configuration endpoint is invalid."
        case .networkError(let message):
            return "Network connection issue: \(message). Please check your internet connection."
        case .invalidData(let detail):
            return "Received invalid configuration data: \(detail)"
        case .urlNotFound:
            return "Web address not found in remote configuration."
        }
    }
}

/// Service to fetch remote web URL dynamically from Firebase Realtime Database.
/// Fully thread-safe, resilient, with offline caching support.
public final class FirebaseConfigService: Sendable {
    
    public static let shared = FirebaseConfigService()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AlBayan", category: "FirebaseConfigService")
    
    private init() {}
    
    /// Fetches the web URL from Firebase Realtime Database.
    /// Returns the remote URL, or falls back to last cached URL if offline.
    public func fetchWebURL() async throws -> URL {
        let endpoint = AppConfig.remoteConfigEndpoint
        logger.info("Fetching remote URL from: \(endpoint.absoluteString)")
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12.0
        config.timeoutIntervalForResource = 15.0
        let session = URLSession(configuration: config)
        
        do {
            let (data, response) = try await session.data(from: endpoint)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ConfigFetchError.networkError("Invalid server response")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw ConfigFetchError.networkError("Server responded with code \(httpResponse.statusCode)")
            }
            
            // Firebase RTDB REST returns raw JSON string or object
            // e.g. "http://206.72.202.150/frontend_al-bayan/"
            let rawString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            // Strip outer quotes if JSON string
            var cleanURLString = rawString
            if cleanURLString.hasPrefix("\"") && cleanURLString.hasSuffix("\"") && cleanURLString.count >= 2 {
                cleanURLString = String(cleanURLString.dropFirst().dropLast())
            }
            
            // Or try parsing as JSON dictionary if stored as object {"main_web_url": "..."}
            if cleanURLString.isEmpty || cleanURLString == "null" {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let parsed = json["main_web_url"] as? String {
                    cleanURLString = parsed
                } else {
                    throw ConfigFetchError.urlNotFound
                }
            }
            
            cleanURLString = cleanURLString.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !cleanURLString.isEmpty,
                  let validURL = URL(string: cleanURLString),
                  validURL.scheme != nil else {
                throw ConfigFetchError.invalidData(cleanURLString)
            }
            
            // Cache successfully fetched URL for offline support
            UserDefaults.standard.set(cleanURLString, forKey: AppConfig.cachedWebURLKey)
            logger.info("Successfully fetched remote URL: \(validURL.absoluteString)")
            return validURL
            
        } catch let error as ConfigFetchError {
            // Check for cached URL before rethrowing
            if let cached = getCachedURL() {
                logger.warning("Network issue, falling back to cached URL: \(cached.absoluteString)")
                return cached
            }
            throw error
        } catch {
            // Check for cached URL before rethrowing
            if let cached = getCachedURL() {
                logger.warning("Fetch failed, falling back to cached URL: \(cached.absoluteString)")
                return cached
            }
            throw ConfigFetchError.networkError(error.localizedDescription)
        }
    }
    
    /// Returns the previously cached URL from UserDefaults if available.
    public func getCachedURL() -> URL? {
        if let cachedString = UserDefaults.standard.string(forKey: AppConfig.cachedWebURLKey),
           let url = URL(string: cachedString),
           url.scheme != nil {
            return url
        }
        return nil
    }
}
