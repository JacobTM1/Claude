import SwiftUI
import UIKit
import WebKit

/// Hosts the bundled `index.html` weather map in a full-screen WKWebView.
///
/// WKWebView does not expose `navigator.geolocation` to app-bundled content,
/// so a small JS shim (injected at document start) forwards geolocation calls
/// to `GeolocationBridge`, which answers them with Core Location.
struct WeatherWebView: UIViewRepresentable {

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.addUserScript(
            WKUserScript(source: Self.geolocationShim,
                         injectionTime: .atDocumentStart,
                         forMainFrameOnly: true)
        )

        let config = WKWebViewConfiguration()
        config.userContentController = controller
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = pagePrefs

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.02, green: 0.027, blue: 0.05, alpha: 1)
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.isScrollEnabled = false   // MapLibre handles all gestures
        webView.allowsBackForwardNavigationGestures = false
        if #available(iOS 16.4, *) { webView.isInspectable = true }

        // Bridge must outlive makeUIView; the coordinator keeps the strong ref.
        let bridge = GeolocationBridge(webView: webView)
        context.coordinator.bridge = bridge
        controller.add(bridge, name: "geo")

        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Web")
            ?? Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    final class Coordinator {
        var bridge: GeolocationBridge?
    }

    /// Replaces `navigator.geolocation` with a shim that round-trips through the
    /// native bridge. Resolved/rejected from Swift via `__geoResolve`/`__geoReject`.
    static let geolocationShim = """
    (function () {
      if (!window.webkit || !window.webkit.messageHandlers || !window.webkit.messageHandlers.geo) return;
      var post = function (m) { window.webkit.messageHandlers.geo.postMessage(m); };
      var nextId = 1;
      var oneShot = {};
      var watches = {};

      window.__geoResolve = function (id, pos) {
        var cb = oneShot[id] || watches[id];
        if (!cb) return;
        try { if (cb.success) cb.success(pos); } catch (e) {}
        if (oneShot[id]) delete oneShot[id];
      };
      window.__geoReject = function (id, code, message) {
        var err = { code: code, message: message, PERMISSION_DENIED: 1, POSITION_UNAVAILABLE: 2, TIMEOUT: 3 };
        var cb = oneShot[id] || watches[id];
        if (!cb) return;
        try { if (cb.error) cb.error(err); } catch (e) {}
        if (oneShot[id]) delete oneShot[id];
      };

      var geo = {
        getCurrentPosition: function (success, error, options) {
          var id = nextId++;
          oneShot[id] = { success: success, error: error };
          post({ type: 'getCurrentPosition', id: id });
        },
        watchPosition: function (success, error, options) {
          var id = nextId++;
          watches[id] = { success: success, error: error };
          post({ type: 'watchPosition', id: id });
          return id;
        },
        clearWatch: function (id) {
          delete watches[id];
          post({ type: 'clearWatch', id: id });
        }
      };

      try {
        Object.defineProperty(navigator, 'geolocation', { value: geo, configurable: true });
      } catch (e) {
        try { navigator.geolocation = geo; } catch (e2) {}
      }
    })();
    """
}
