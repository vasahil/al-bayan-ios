import SwiftUI

/// Main Home View of the Application.
/// Dynamically fetches the website URL from Firebase Realtime Database.
/// Features robust loading states, network error handling, offline retry, and zero race conditions.
public struct HomeView: View {
    
    // MARK: - Remote Loading State
    public enum ViewState: Equatable {
        case loading(String)
        case loaded(URL)
        case failed(String)
    }
    
    // MARK: - State Properties
    @State private var viewState: ViewState = .loading("Connecting to Al-Bayan...")
    @StateObject private var webViewModel = WebViewModel()
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .top) {
            switch viewState {
            case .loading(let message):
                // 1. Initial State: Fetching remote URL from Firebase
                FullScreenLoadingView(message: message)
                    .transition(.opacity)
                
            case .loaded(let targetURL):
                // 2. Success State: Fullscreen Reusable WebView with remote URL
                ReusableWebView(
                    url: targetURL,
                    viewModel: webViewModel,
                    allowsBackForwardGestures: AppConfig.allowsBackForwardNavigationGestures,
                    enablePullToRefresh: AppConfig.enablePullToRefresh,
                    onPageFinished: { finishedURL in
                        if let urlString = finishedURL?.absoluteString {
                            FirebaseManager.shared.logEvent(
                                name: "page_view",
                                parameters: ["url": urlString]
                            )
                        }
                    }
                )
                .ignoresSafeArea(edges: .bottom)
                
                // Linear Progress bar at top while web page loads
                LoadingProgressView(
                    progress: webViewModel.estimatedProgress,
                    isVisible: webViewModel.isLoading
                )
                
                // Web Page Loading Error Overlay (e.g. server outage while browsing)
                if let webError = webViewModel.errorMessage {
                    WebErrorView(message: webError) {
                        webViewModel.reload()
                    }
                    .transition(.opacity)
                }
                
            case .failed(let errorMessage):
                // 3. Error State: Network failure or remote URL not found
                WebErrorView(message: errorMessage) {
                    fetchRemoteURL()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewState)
        .onAppear {
            fetchRemoteURL()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Asynchronously fetches the web URL from Firebase Realtime Database.
    /// Thread-safe via @MainActor updates.
    private func fetchRemoteURL() {
        withAnimation(.easeInOut(duration: 0.2)) {
            viewState = .loading("Connecting to Al-Bayan...")
            webViewModel.errorMessage = nil
        }
        
        Task { @MainActor in
            do {
                let url = try await FirebaseConfigService.shared.fetchWebURL()
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewState = .loaded(url)
                }
            } catch {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewState = .failed(error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
