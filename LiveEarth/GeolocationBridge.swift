import Foundation
import CoreLocation
import WebKit

/// Answers the web app's geolocation requests using Core Location.
///
/// One-shot (`getCurrentPosition`) and continuous (`watchPosition`) requests are
/// tracked by the id the JS shim assigns. A single `CLLocationManager` feeds all
/// of them: each fix resolves every pending one-shot plus all active watches.
final class GeolocationBridge: NSObject, WKScriptMessageHandler, CLLocationManagerDelegate {

    private let manager = CLLocationManager()
    private weak var webView: WKWebView?

    private var pendingOneShot: [Int] = []
    private var watchIds: Set<Int> = []
    private var awaitingAuth = false

    init(webView: WKWebView) {
        super.init()
        self.webView = webView
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    // MARK: - Messages from JS

    func userContentController(_ userContentController: WKUserContentController,
                              didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let type = body["type"] as? String else { return }
        let id = (body["id"] as? Int) ?? (body["id"] as? NSNumber)?.intValue

        switch type {
        case "getCurrentPosition":
            if let id { pendingOneShot.append(id); ensureAuthorization() }
        case "watchPosition":
            if let id { watchIds.insert(id); ensureAuthorization() }
        case "clearWatch":
            if let id { watchIds.remove(id); stopIfIdle() }
        default:
            break
        }
    }

    // MARK: - Authorization

    private func ensureAuthorization() {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            beginUpdatesIfNeeded()
        case .notDetermined:
            if !awaitingAuth {
                awaitingAuth = true
                manager.requestWhenInUseAuthorization()
            }
        default:
            rejectAll(code: 1, message: "Location permission denied")
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        awaitingAuth = false
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            beginUpdatesIfNeeded()
        case .denied, .restricted:
            rejectAll(code: 1, message: "Location permission denied")
        default:
            break
        }
    }

    private func beginUpdatesIfNeeded() {
        if !pendingOneShot.isEmpty || !watchIds.isEmpty {
            manager.startUpdatingLocation()
        }
    }

    private func stopIfIdle() {
        if pendingOneShot.isEmpty && watchIds.isEmpty {
            manager.stopUpdatingLocation()
        }
    }

    // MARK: - Location delegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        let payload = Self.positionLiteral(from: loc)

        let oneShots = pendingOneShot
        pendingOneShot.removeAll()
        for id in oneShots { resolve(id: id, positionLiteral: payload) }
        for id in watchIds { resolve(id: id, positionLiteral: payload) }

        stopIfIdle()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // One-shots fail; watches keep waiting for a later fix.
        let oneShots = pendingOneShot
        pendingOneShot.removeAll()
        for id in oneShots { reject(id: id, code: 2, message: "Position unavailable") }
        stopIfIdle()
    }

    // MARK: - JS callbacks

    private func resolve(id: Int, positionLiteral: String) {
        webView?.evaluateJavaScript("window.__geoResolve(\(id), \(positionLiteral));", completionHandler: nil)
    }

    private func reject(id: Int, code: Int, message: String) {
        let escaped = message.replacingOccurrences(of: "\"", with: "\\\"")
        webView?.evaluateJavaScript("window.__geoReject(\(id), \(code), \"\(escaped)\");", completionHandler: nil)
    }

    private func rejectAll(code: Int, message: String) {
        let oneShots = pendingOneShot
        let watches = watchIds
        pendingOneShot.removeAll()
        watchIds.removeAll()
        for id in oneShots { reject(id: id, code: code, message: message) }
        for id in watches { reject(id: id, code: code, message: message) }
        manager.stopUpdatingLocation()
    }

    /// Builds a JS object literal matching the W3C GeolocationPosition shape.
    private static func positionLiteral(from loc: CLLocation) -> String {
        func num(_ v: Double) -> String { v.isFinite ? String(v) : "null" }
        let heading = loc.course >= 0 ? num(loc.course) : "null"
        let speed = loc.speed >= 0 ? num(loc.speed) : "null"
        let altAcc = loc.verticalAccuracy >= 0 ? num(loc.verticalAccuracy) : "null"
        let ts = loc.timestamp.timeIntervalSince1970 * 1000.0
        return """
        {coords:{latitude:\(num(loc.coordinate.latitude)),longitude:\(num(loc.coordinate.longitude)),\
        accuracy:\(num(max(loc.horizontalAccuracy, 0))),altitude:\(num(loc.altitude)),\
        altitudeAccuracy:\(altAcc),heading:\(heading),speed:\(speed)},timestamp:\(num(ts))}
        """
    }
}
