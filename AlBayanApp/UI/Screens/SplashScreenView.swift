import SwiftUI

/// Elegant, modern Splash Screen that displays the Al-Bayan logo for 1 second.
/// Smoothly transitions to the main home screen with no race conditions or thread lag.
public struct SplashScreenView: View {
    
    @Binding var isShowing: Bool
    @State private var logoScale: CGFloat = 0.85
    @State private var logoOpacity: Double = 0.0
    
    // Al-Bayan deep emerald green background
    private let backgroundColor = Color(red: 0.03, green: 0.22, blue: 0.14)
    
    public init(isShowing: Binding<Bool>) {
        self._isShowing = isShowing
    }
    
    public var body: some View {
        ZStack {
            // Background
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Al-Bayan Golden Logo
                if let logoImage = loadLogoImage() {
                    Image(uiImage: logoImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 170, height: 170)
                        .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
                        .shadow(color: Color.black.opacity(0.4), radius: 18, x: 0, y: 10)
                } else {
                    // Fallback elegant Arabic & English typography if image is missing
                    VStack(spacing: 8) {
                        Text("البيان")
                            .font(.system(size: 46, weight: .bold))
                            .foregroundColor(Color(red: 0.88, green: 0.74, blue: 0.38))
                        
                        Text("Al-Bayan")
                            .font(.system(size: 22, weight: .semibold, design: .serif))
                            .foregroundColor(.white)
                    }
                }
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
        }
        .onAppear {
            // 1. Subtle, smooth logo entrance animation
            withAnimation(.easeOut(duration: 0.35)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            // 2. Display logo for exactly 1.0 second, then smoothly dismiss
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                withAnimation(.easeInOut(duration: 0.4)) {
                    isShowing = false
                }
            }
        }
    }
    
    /// Thread-safe image loader that checks asset catalog and bundle resources
    private func loadLogoImage() -> UIImage? {
        if let image = UIImage(named: "AppIcon") {
            return image
        }
        if let path = Bundle.main.path(forResource: "AppIcon", ofType: "png"),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        return nil
    }
}

#Preview {
    SplashScreenView(isShowing: .constant(true))
}
