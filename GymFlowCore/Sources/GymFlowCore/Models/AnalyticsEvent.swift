import Foundation
import GRDB

public struct AnalyticsEvent: Codable, Equatable, Identifiable, Sendable,
    FetchableRecord, PersistableRecord {
    public var id: UUID
    public var occurredAt: Date
    public var eventType: String
    public var payloadJson: String?
    public var syncedAt: Date?

    public init(
        id: UUID = UUID(),
        occurredAt: Date = Date(),
        eventType: String,
        payload: [String: String] = [:],
        syncedAt: Date? = nil
    ) {
        self.id = id
        self.occurredAt = occurredAt
        self.eventType = eventType
        self.payloadJson = Self.encode(payload: payload)
        self.syncedAt = syncedAt
    }

    public var payload: [String: String] {
        guard let payloadJson,
              let data = payloadJson.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return decoded
    }

    public static let databaseTableName = "analytics_event"
    public static let databaseUUIDEncodingStrategy = DatabaseUUIDEncodingStrategy.uppercaseString

    enum CodingKeys: String, CodingKey {
        case id
        case occurredAt = "occurred_at"
        case eventType = "event_type"
        case payloadJson = "payload_json"
        case syncedAt = "synced_at"
    }

    private static func encode(payload: [String: String]) -> String? {
        guard !payload.isEmpty else { return nil }
        let data = try? JSONEncoder().encode(payload)
        return data.flatMap { String(data: $0, encoding: .utf8) }
    }
}
