import Foundation
import MetricKit

final class MetricsLogger: NSObject, MXMetricManagerSubscriber {
    private let directory: URL

    override init() {
        let fm = FileManager.default
        let caches = (try? fm.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.directory = caches.appendingPathComponent("Metrics", isDirectory: true)
        try? fm.createDirectory(at: self.directory, withIntermediateDirectories: true)
        super.init()
    }

    func didReceive(_ payloads: [MXMetricPayload]) {
        write(payloads: payloads.map { $0.jsonRepresentation() }, prefix: "metric")
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        write(payloads: payloads.map { $0.jsonRepresentation() }, prefix: "diagnostic")
    }

    private func write(payloads: [Data], prefix: String) {
        guard !payloads.isEmpty else { return }
        let stamp = MetricsLogger.timestamp()
        for (index, payload) in payloads.enumerated() {
            let url = directory.appendingPathComponent("\(prefix)-\(stamp)-\(index).json")
            try? payload.write(to: url, options: .atomic)
        }
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: Date())
    }
}
