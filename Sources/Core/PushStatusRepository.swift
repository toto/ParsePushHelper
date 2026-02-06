//
//  PushStatusRepository.swift
//  ParsePush
//
//  Created by Thomas Kollbach on 06.02.26.
//

import Foundation

public struct PushStatusEntry: Identifiable, Hashable {
    public let id: String
    public let createdAt: String?
    public let updatedAt: String?
    public let status: String?
    public let rawJSON: String

    public init(id: String, createdAt: String?, updatedAt: String?, status: String?, rawJSON: String) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.status = status
        self.rawJSON = rawJSON
    }
}

public struct PushStatusRepository {
    public enum RepositoryError: LocalizedError, Equatable {
        case invalidResponse
        case httpStatus(Int)
        case decodeFailed

        public var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "The server response was invalid."
            case .httpStatus(let status):
                return "The server returned HTTP status \(status)."
            case .decodeFailed:
                return "The response could not be decoded."
            }
        }
    }

    public init() {}

    public func fetchStatuses(
        configuration: ParseServerConfiguration,
        apiKey: String?
    ) async throws -> [PushStatusEntry] {
        var url = configuration.serverURL
        url.appendPathComponent("classes")
        url.appendPathComponent("_PushStatus")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(configuration.appID, forHTTPHeaderField: "X-Parse-Application-Id")
        if let apiKey, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            request.setValue(apiKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RepositoryError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw RepositoryError.httpStatus(httpResponse.statusCode)
        }

        return try Self.decodeStatuses(from: data)
    }

    static func decodeStatuses(from data: Data) throws -> [PushStatusEntry] {
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let results = root["results"] as? [[String: Any]]
        else {
            throw RepositoryError.decodeFailed
        }

        return results.map { entry in
            let objectId = entry["objectId"] as? String ?? UUID().uuidString
            let createdAt = entry["createdAt"] as? String
            let updatedAt = entry["updatedAt"] as? String
            let status = (entry["status"] as? String) ?? (entry["pushStatus"] as? String)
            let rawJSON = Self.prettyPrintedJSON(from: entry)

            return PushStatusEntry(
                id: objectId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                status: status,
                rawJSON: rawJSON
            )
        }
    }

    private static func prettyPrintedJSON(from object: [String: Any]) -> String {
        do {
            let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
            return String(decoding: data, as: UTF8.self)
        } catch {
            return String(describing: object)
        }
    }
}
