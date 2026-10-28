import SwiftUI

/// A modern, reusable loading progress bar.
public struct LoadingProgressView: View {
    let progress: Double
    let isVisible: Bool
    
    public init(progress: Double, isVisible: Bool) {
        self.progress = progress
        self.isVisible = isVisible
    }
    
    public var body: some View {
        VStack {
            if isVisible && progress < 1.0 {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 0.85, green: 0.72, blue: 0.35)))
                    .frame(height: 3)
                    .animation(.easeInOut(duration: 0.2), value: progress)
            }
            Spacer()
        }
    }
}

/// Full screen loading state when connecting to Firebase and fetching URL.
public struct FullScreenLoadingView: View {
    let message: String
    
    public init(message: String = "Connecting to Al-Bayan...") {
        self.message = message
    }
    
    public var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.03, green: 0.35, blue: 0.22)))
                    .scaleEffect(1.6)
                
                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// A clean, reusable Error and Retry view when network or URL fetch fails.
public struct WebErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    public init(message: String, onRetry: @escaping () -> Void) {
        self.message = message
        self.onRetry = onRetry
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.orange)
            
            Text("Connection Error")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(Color(red: 0.03, green: 0.35, blue: 0.22))
                .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}
