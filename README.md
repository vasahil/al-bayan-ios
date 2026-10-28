# 📱 Al-Bayan iOS - Reusable WebView & Firebase Application

An iOS application built in modern **Swift (SwiftUI)** featuring a full-screen **WebView** on the home screen, connected safely with **Firebase**, designed with clean architecture, high reusability (zero code duplication), and strict protection against race conditions.

This project is fully configured to build and run directly on **Ubuntu / Linux using `xtool`** as well as on **macOS using Xcode**.

---

## 📂 Project Structure

```text
Al-Bayan-ios/
├── Package.swift                    # Swift Package Manager manifest (xtool build configuration)
├── xtool.yml                        # xtool bundle & app config
├── AlBayanApp/
│   ├── App/
│   │   └── AlBayanApp.swift         # Main App Entrypoint & AppDelegateAdaptor
│   ├── Core/
│   │   ├── Config/
│   │   │   └── AppConfig.swift      # Centralized configuration (Hardcoded URL & settings)
│   │   └── Services/
│   │       └── FirebaseManager.swift# Thread-safe Firebase manager (eliminates race conditions)
│   ├── UI/
│   │   ├── Components/
│   │   │   ├── ReusableWebView.swift    # Reusable WKWebView component (SwiftUI wrapper + Coordinator)
│   │   │   └── LoadingOverlayView.swift # Progress bar & offline retry error views
│   │   └── Screens/
│   │       └── HomeView.swift           # Home screen displaying ONLY the WebView
│   └── Resources/
│       ├── Info.plist                   # App configurations & ATS permissions
│       ├── Assets.xcassets/             # App icons and accent colors
│       └── GoogleService-Info.plist.example # Example Firebase configuration template
└── README.md
```

---

## ⚡ How to Build & Run with `xtool` (Directly on Ubuntu / Linux)

Aapke system par `xtool` configured hai. Is project ko compile aur run karne ke liye:

### 1. Build the App
Terminal mein simply run karein:
```bash
cd /home/sahil-vashisht-vpatrol/i-apps/Al-Bayan-ios
xtool dev build
```
Yeh command Swift code ko compile karke `.app` package taiyaar kar degi.

### 2. Run on Connected Physical iPhone
1. Apna iPhone USB cable se is PC se connect karein.
2. iPhone par **"Trust This Computer"** tap karein aur passcode dalein.
3. iPhone Settings mein Developer Mode ON hona chahiye:
   * **Settings** ➔ **Privacy & Security** ➔ **Developer Mode** (Toggle ON).
4. Terminal mein run karein:
   ```bash
   xtool dev run
   ```
   `xtool` code compile karega, app ko sign karega aur direct aapke iPhone screen par launch kar dega!

---

## 🔥 Step-by-Step Guide to Connect Firebase

### Step 1: Create a Project in Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project** (name it `Al-Bayan-App`).
3. Follow the onscreen prompts and click **Create Project**.

### Step 2: Register your iOS App in Firebase
1. On your Firebase Project dashboard, click the **iOS icon** (`</>`).
2. Enter your **Apple bundle ID**:
   * Default bundle ID configured in `xtool.yml` is `com.example.AlBayanApp`.
3. Click **Register app**.

### Step 3: Download `GoogleService-Info.plist`
1. Download `GoogleService-Info.plist` from Firebase.
2. Place it inside the `AlBayanApp/Resources/` folder.

---

## 🛡️ How Race Conditions & Code Duplication Are Prevented

### 1. Eliminating Race Conditions
- **`@MainActor` Synchronization**: WebKit (`WKWebView`) and SwiftUI UI updates must strictly happen on the Main Thread. In `ReusableWebView.swift` and `FirebaseManager.swift`, all updates are routed via `@MainActor` to avoid thread collisions and background UI crashes.
- **Single-Execution Firebase Configuration**: `FirebaseManager.shared.configure()` checks `FirebaseApp.app() == nil` and tracks `isConfigured`. Even if triggered multiple times concurrently, Firebase will only configure once, preventing fatal crashes.
- **Retain Cycle & Memory Leak Prevention**: The `Coordinator` uses `[weak self]` in closures and observers (`NSKeyValueObservation`), properly cleaning up when the view is dismissed.
- **Navigation Safety**: Cancels or ignores `-999` (NSURLErrorCancelled) when a user taps links rapidly, avoiding false error alerts.

### 2. Zero Code Duplication (High Reusability)
- **`ReusableWebView`**: Can be used anywhere in the app (modals, tabs, other screens) simply by calling `ReusableWebView(url: someURL, viewModel: myViewModel)`.
- **`AppConfig`**: Hardcoded URLs and behavior flags exist in one single place. If you ever need to change the website URL, you only edit `AppConfig.swift`.

---

## 🌐 Dynamic URL from Firebase Realtime Database

Website URL ab hardcoded nahi hai. Yeh app launch par dynamically aapke Firebase Realtime Database se fetch hota hai:

* **Database Endpoint:** `https://rahzaan-vpn-default-rtdb.firebaseio.com/`
* **Configuration Path:** `config/main_web_url`
* **Fetched URL:** `http://206.72.202.150/frontend_al-bayan/`

### 🔄 Loading & Error States:
1. **Connecting State:** Jab app remote URL fetch kar rahi hoti hai, tab circular progress spinner ke saath *"Connecting to Al-Bayan..."* screen aati hai.
2. **Loaded State:** Firebase se URL aate hi WebView full-screen render hoti hai aur top par linear progress bar show hota hai.
3. **Error & Offline State:** Agar internet issue ho ya URL na mile, toh clean *"Connection Error"* screen aati hai jisme clear message aur **"Try Again"** button hota hai.
4. **Offline Caching:** Last successfully loaded URL ko `UserDefaults` mein cache kiya jata hai taaki temporary network drop par bhi user ko purana URL mil sake.
5. **App Transport Security (ATS):** `Info.plist` mein `NSAllowsArbitraryLoads = true` enabled hai taaki `http://206.72.202.150/...` bina kisi security block ke smoothly open ho sake.
