import SwiftUI
import WebKit

// MARK: - WebViewModel (State Manager)

/// Observable state holder for the WebView.
/// Marked with `@MainActor` to prevent race conditions during UI updates.
@MainActor
public final class WebViewModel: ObservableObject {
    @Published public var isLoading: Bool = false
    @Published public var estimatedProgress: Double = 0.0
    @Published public var pageTitle: String = ""
    @Published public var canGoBack: Bool = false
    @Published public var canGoForward: Bool = false
    @Published public var errorMessage: String? = nil
    
    // Command triggers for navigation
    fileprivate var actionHandler: ((WebViewAction) -> Void)?
    
    public enum WebViewAction {
        case reload
        case goBack
        case goForward
        case load(URL)
    }
    
    public init() {}
    
    public func reload() {
        actionHandler?(.reload)
    }
    
    public func goBack() {
        actionHandler?(.goBack)
    }
    
    public func goForward() {
        actionHandler?(.goForward)
    }
    
    public func load(url: URL) {
        actionHandler?(.load(url))
    }
}

// MARK: - ReusableWebView (UIViewRepresentable)

/// A fully reusable, thread-safe SwiftUI wrapper around Apple's WebKit WKWebView.
/// Eliminates code duplication and prevents race conditions via MainActor synchronization.
public struct ReusableWebView: UIViewRepresentable {
    
    public let url: URL
    @ObservedObject public var viewModel: WebViewModel
    
    // Optional configuration closures
    public var allowsBackForwardGestures: Bool = true
    public var enablePullToRefresh: Bool = true
    public var onPageFinished: ((URL?) -> Void)? = nil
    
    public init(
        url: URL,
        viewModel: WebViewModel,
        allowsBackForwardGestures: Bool = true,
        enablePullToRefresh: Bool = true,
        onPageFinished: ((URL?) -> Void)? = nil
    ) {
        self.url = url
        self.viewModel = viewModel
        self.allowsBackForwardGestures = allowsBackForwardGestures
        self.enablePullToRefresh = enablePullToRefresh
        self.onPageFinished = onPageFinished
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    public func makeUIView(context: Context) -> WKWebView {
        // Set up WebKit configuration
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = preferences
        configuration.allowsInlineMediaPlayback = AppConfig.allowsInlineMediaPlayback
        
        // Auto-sanitize unencoded image URLs (e.g. spaces in filename 'Al-Bayan-Logo (1).jpeg')
        let sanitizeScriptSource = """
        (function() {
            function sanitize(url) {
                if (!url || typeof url !== 'string') return url;
                if (url.indexOf(' ') !== -1) {
                    return url.split(' ').join('%20');
                }
                return url;
            }
            
            // Intercept HTMLImageElement.src setter
            try {
                const desc = Object.getOwnPropertyDescriptor(HTMLImageElement.prototype, 'src');
                if (desc && desc.set) {
                    Object.defineProperty(HTMLImageElement.prototype, 'src', {
                        set: function(val) {
                            desc.set.call(this, sanitize(val));
                        },
                        get: function() {
                            return desc.get.call(this);
                        }
                    });
                }
            } catch(e) {}
            
            // Intercept setAttribute('src', ...)
            try {
                const origSetAttr = Element.prototype.setAttribute;
                Element.prototype.setAttribute = function(name, val) {
                    if (name && name.toLowerCase() === 'src' && typeof val === 'string') {
                        val = sanitize(val);
                    }
                    return origSetAttr.call(this, name, val);
                };
            } catch(e) {}

            // MutationObserver to auto-fix dynamically rendered React images
            try {
                const observer = new MutationObserver(function(mutations) {
                    for (let i = 0; i < mutations.length; i++) {
                        const nodes = mutations[i].addedNodes;
                        for (let j = 0; j < nodes.length; j++) {
                            const node = nodes[j];
                            if (node.tagName === 'IMG' && node.src && node.src.indexOf(' ') !== -1) {
                                node.src = sanitize(node.src);
                            } else if (node.querySelectorAll) {
                                const imgs = node.querySelectorAll('img');
                                for (let k = 0; k < imgs.length; k++) {
                                    if (imgs[k].src && imgs[k].src.indexOf(' ') !== -1) {
                                        imgs[k].src = sanitize(imgs[k].src);
                                    }
                                }
                            }
                        }
                    }
                });
                
                if (document.documentElement) {
                    observer.observe(document.documentElement, { childList: true, subtree: true });
                } else {
                    document.addEventListener('DOMContentLoaded', function() {
                        observer.observe(document.documentElement, { childList: true, subtree: true });
                    });
                }
            } catch(e) {}
        })();
        """
        let userScript = WKUserScript(
            source: sanitizeScriptSource,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        configuration.userContentController.addUserScript(userScript)
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = allowsBackForwardGestures
        webView.scrollView.bounces = true
        
        // Standard Safari user-agent so media endpoints serve images without blocking
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
        
        // Add Pull-to-Refresh
        if enablePullToRefresh {
            let refreshControl = UIRefreshControl()
            refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefreshControl(_:)), for: .valueChanged)
            webView.scrollView.refreshControl = refreshControl
        }
        
        // Setup KVO for progress & title
        context.coordinator.setupObservers(for: webView)
        
        // Bind actions safely to avoid retain cycle
        viewModel.actionHandler = { [weak webView] action in
            guard let webView = webView else { return }
            switch action {
            case .reload:
                webView.reload()
            case .goBack:
                if webView.canGoBack { webView.goBack() }
            case .goForward:
                if webView.canGoForward { webView.goForward() }
            case .load(let newURL):
                let request = URLRequest(url: newURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
                webView.load(request)
            }
        }
        
        // Initial request load
        let initialRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        webView.load(initialRequest)
        
        return webView
    }
    
    public func updateUIView(_ uiView: WKWebView, context: Context) {
        // No redundant load triggered here to avoid reload race conditions on state changes
    }
    
    // MARK: - Coordinator
    
    public class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: ReusableWebView
        private var progressObservation: NSKeyValueObservation?
        private var titleObservation: NSKeyValueObservation?
        
        init(parent: ReusableWebView) {
            self.parent = parent
            super.init()
        }
        
        deinit {
            // Clean up observers to prevent dangling reference memory leaks
            progressObservation?.invalidate()
            titleObservation?.invalidate()
        }
        
        func setupObservers(for webView: WKWebView) {
            // Observe loading progress safely
            progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in
                    self?.parent.viewModel.estimatedProgress = webView.estimatedProgress
                }
            }
            
            // Observe web page title safely
            titleObservation = webView.observe(\.title, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor in
                    self?.parent.viewModel.pageTitle = webView.title ?? ""
                }
            }
        }
        
        @objc func handleRefreshControl(_ sender: UIRefreshControl) {
            Task { @MainActor in
                self.parent.viewModel.reload()
                sender.endRefreshing()
            }
        }
        
        // MARK: - WKNavigationDelegate
        
        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            Task { @MainActor in
                self.parent.viewModel.isLoading = true
                self.parent.viewModel.errorMessage = nil
            }
        }
        
        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                self.parent.viewModel.isLoading = false
                self.parent.viewModel.canGoBack = webView.canGoBack
                self.parent.viewModel.canGoForward = webView.canGoForward
                self.parent.onPageFinished?(webView.url)
            }
        }
        
        public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handleError(error)
        }
        
        public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handleError(error)
        }
        
        private func handleError(_ error: Error) {
            let nsError = error as NSError
            // Ignore cancelled errors (code -999) when user navigates fast
            guard nsError.code != NSURLErrorCancelled else { return }
            
            Task { @MainActor in
                self.parent.viewModel.isLoading = false
                self.parent.viewModel.errorMessage = error.localizedDescription
            }
        }
        
        // Handle target="_blank" links opening in same webview safely
        public func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}
