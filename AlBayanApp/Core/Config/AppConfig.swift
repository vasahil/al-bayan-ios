import Foundation

/// Centralized configuration for the application.
/// Single source of truth for app settings and remote configurations.
public enum AppConfig {
    
    // MARK: - Firebase Realtime Database
    
    /// Reads database URL dynamically from GoogleService-Info.plist with fallback.
    public static var firebaseDatabaseURL: URL {
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let dbUrlString = dict["DATABASE_URL"] as? String,
           let url = URL(string: dbUrlString) {
            return url
        }
        return URL(string: "https://rahzaan-vpn-default-rtdb.firebaseio.com")!
    }
    
    /// Realtime Database path for the website configuration.
    public static let remoteConfigPath = "config/main_web_url.json"
    
    /// Full URL endpoint to fetch the webview URL.
    public static var remoteConfigEndpoint: URL {
        return firebaseDatabaseURL.appendingPathComponent(remoteConfigPath)
    }
    
    /// Key used to store last successfully fetched URL in UserDefaults for offline fallback.
    public static let cachedWebURLKey = "cached_main_web_url"
    
    // MARK: - WebView Behavior Settings
    public static let allowsBackForwardNavigationGestures: Bool = true
    public static let enablePullToRefresh: Bool = true
    public static let allowsInlineMediaPlayback: Bool = true
    
    // MARK: - App Metadata
    public static let appName = "Al-Bayan"
}
