//
//  ParseServerConfiguration.swift
//  ParsePush
//
//  Created by Thomas Kollbach on 26.01.26.
//

import Foundation

public struct ParseServerConfiguration: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var serverURL: URL
    public var appID: String

    public init(id: UUID = UUID(), name: String, serverURL: URL, appID: String) {
        self.id = id
        self.name = name
        self.serverURL = serverURL
        self.appID = appID
    }
}
