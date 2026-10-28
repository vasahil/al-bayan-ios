import Foundation
import os.log

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

/// Thread-safe singleton manager for Firebase lifecycle and services.
/// Prevents race conditions during initialization by synchronizing configuration
/// and ensuring FirebaseApp.configure() is invoked strictly once on the MainActor.
@MainActor
public final class FirebaseManager {
    
    // MARK: - Singleton
    public static let shared = FirebaseManager()
    
    // MARK: - State
    private(set) var isConfigured: Bool = false
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AlBayan", category: "FirebaseManager")
    
    private init() {
        // Private initializer prevents multiple instances
    }
    
    // MARK: - Initialization Method
    
    /// Safely initializes Firebase.
    /// Can be called multiple times without risk of race condition or multiple config crash.
    public func configure() {
        guard !isConfigured else {
            logger.info("Firebase already configured. Skipping redundant call.")
            return
        }
        
        #if canImport(FirebaseCore)
        // Verify GoogleService-Info.plist is bundled
        if let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            logger.info("Found GoogleService-Info.plist at: \(plistPath)")
            
            // FirebaseApp.configure() must be called once
            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
                isConfigured = true
                logger.info("Firebase successfully configured!")
            } else {
                isConfigured = true
                logger.info("FirebaseApp was already initialized by system.")
            }
        } else {
            logger.warning("""
            ⚠️ GoogleService-Info.plist is missing from the Xcode target bundle!
            Please download it from Firebase Console and add it to your Xcode project.
            """)
        }
        #else
        logger.warning("""
        ℹ️ Firebase SDK is not linked yet.
        To link: File -> Add Package Dependencies -> URL: https://github.com/firebase/firebase-ios-sdk
        """)
        #endif
    }
    
    // MARK: - Helper Methods
    
    /// Example method for logging events safely
    public func logEvent(name: String, parameters: [String: Any]? = nil) {
        #if canImport(FirebaseAnalytics)
        guard isConfigured else { return }
        Analytics.logEvent(name, parameters: parameters)
        #else
        logger.debug("Analytics event [\(name)] simulated (FirebaseAnalytics not imported)")
        #endif
    }
}
