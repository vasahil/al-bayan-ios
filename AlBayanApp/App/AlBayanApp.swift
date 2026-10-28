import SwiftUI

// MARK: - AppDelegate for Firebase Lifecycle Handling

/// Custom AppDelegate adaptor conforming to standard Firebase iOS architecture.
/// This guarantees Firebase is initialized strictly once before any UI renders,
/// preventing race conditions when UI components try to access Firebase services.
final class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Safe, centralized initialization
        Task { @MainActor in
            FirebaseManager.shared.configure()
        }
        return true
    }
}

// MARK: - App Main Entry Point

@main
struct AlBayanApp: App {
    
    // Connects our custom AppDelegate into SwiftUI lifecycle
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Controls the 1-second splash screen presentation
    @State private var isShowingSplash: Bool = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                HomeView()
                
                if isShowingSplash {
                    SplashScreenView(isShowing: $isShowingSplash)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
        }
    }
}
