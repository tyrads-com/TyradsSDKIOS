import UIKit
import WebKit

final class TyradsWebViewController: UIViewController, WKScriptMessageHandler {
    private var url: URL
    private var hasLoaded = false
    private var edgePanGesture: UIScreenEdgePanGestureRecognizer?

    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.userContentController.add(self, name: "tyradsLog")
        config.userContentController.add(self, name: "tyradsClose")
        let debugScript = WKUserScript(
            source: """
            (function() {
                function send(level, args) {
                    try {
                        var msg = Array.prototype.map.call(args, function(a) {
                            try { return typeof a === 'object' ? JSON.stringify(a) : String(a); } catch(e) { return String(a); }
                        }).join(' ');
                        window.webkit.messageHandlers.tyradsLog.postMessage(level + ': ' + msg);
                    } catch(e) {}
                }
                var origLog = console.log;
                console.log = function() { send('LOG', arguments); origLog && origLog.apply(console, arguments); };
                var origError = console.error;
                console.error = function() { send('ERROR', arguments); origError && origError.apply(console, arguments); };
                var origWarn = console.warn;
                console.warn = function() { send('WARN', arguments); origWarn && origWarn.apply(console, arguments); };
                window.onerror = function(msg, src, line, col, err) {
                    send('ONERROR', [msg, src, line]);
                };
                window.addEventListener('unhandledrejection', function(e) {
                    send('REJECTION', [String(e.reason)]);
                });
                // Intercept history navigation
                var origBack = history.back.bind(history);
                history.back = function() { send('HISTORY', ['back']); origBack(); };
                var origGo = history.go.bind(history);
                history.go = function(n) { send('HISTORY', ['go', n]); origGo(n); };
                var origPush = history.pushState.bind(history);
                history.pushState = function(s,t,u) { send('HISTORY', ['pushState', u]); origPush(s,t,u); };
                var origReplace = history.replaceState.bind(history);
                history.replaceState = function(s,t,u) { send('HISTORY', ['replaceState', u]); origReplace(s,t,u); };
                window.addEventListener('popstate', function(e) { send('HISTORY', ['popstate', location.pathname]); });
                // Intercept window.postMessage
                var origPostMsg = window.postMessage.bind(window);
                window.postMessage = function(data, origin) { send('POSTMSG', [JSON.stringify(data), origin]); origPostMsg(data, origin); };
                window.addEventListener('message', function(e) {
                    send('MSG_RECV', [JSON.stringify(e.data), e.origin]);
                    try {
                        var data = typeof e.data === 'string' ? JSON.parse(e.data) : e.data;
                        if (data && data.action === 'closeWebView') {
                            window.webkit.messageHandlers.tyradsClose.postMessage(null);
                        }
                    } catch(err) {}
                });
                // Proxy webkit messageHandlers
                try {
                    var realHandlers = window.webkit.messageHandlers;
                    window.webkit.messageHandlers = new Proxy(realHandlers, {
                        get: function(target, name) {
                            if (name === 'tyradsLog' || name === 'tyradsClose') return target[name];
                            return {
                                postMessage: function(data) {
                                    send('HANDLER', [name, JSON.stringify(data)]);
                                    if (target[name]) target[name].postMessage(data);
                                }
                            };
                        }
                    });
                } catch(e) {}
            })();
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(debugScript)
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = self
        wv.uiDelegate = self
        wv.translatesAutoresizingMaskIntoConstraints = false
        return wv
    }()

    private lazy var progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .bar)
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.tintColor = Tyrads.instance.colorMain ?? TyradsSDKConfig.secondaryColor
        return pv
    }()

    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(webView)
        view.addSubview(progressView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        // Add to nav controller's view so it sits above WKWebView in hit-test chain
        if edgePanGesture == nil, let navView = navigationController?.view {
            let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgePan(_:)))
            gesture.edges = .left
            navView.addGestureRecognizer(gesture)
            edgePanGesture = gesture
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        if let gesture = edgePanGesture {
            navigationController?.view.removeGestureRecognizer(gesture)
            edgePanGesture = nil
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasLoaded else { return }
        hasLoaded = true
        progressView.isHidden = false
        progressView.setProgress(0.1, animated: false)
        webView.load(URLRequest(url: url))
    }

    func navigate(to newURL: URL) {
        url = newURL
        webView.load(URLRequest(url: newURL))
    }

    @objc private func handleEdgePan(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state == .recognized { closeWebView() }
    }

    private func closeWebView() {
        Tyrads.instance.track(TyradsActivity.closed)
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

}

extension TyradsWebViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }
}

extension TyradsWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        if url.scheme == "tyrads" {
            if url.host == "close" { closeWebView() }
            decisionHandler(.cancel)
            return
        }
        if url.scheme != "https" && url.scheme != "http" {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressView.isHidden = false
        progressView.setProgress(0.2, animated: true)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressView.setProgress(1.0, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.progressView.isHidden = true
            self?.progressView.setProgress(0, animated: false)
        }
        webView.evaluateJavaScript("document.title") { result, _ in
            if let title = result as? String { print("[TyradsSDK] WebView loaded: \(title)") }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        progressView.isHidden = true
        print("[TyradsSDK] WebView didFail: \(error)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        progressView.isHidden = true
        print("[TyradsSDK] WebView didFailProvisional: \(error)")
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }
}

extension TyradsWebViewController {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "tyradsClose":
            DispatchQueue.main.async { self.closeWebView() }
        case "tyradsLog":
            if let body = message.body as? String { print("[TyradsWeb] \(body)") }
        default:
            break
        }
    }
}
