//
//  PushComposeTypes.swift
//  ParsePush
//
//  Created by Thomas Kollbach on 26.01.26.
//

import Foundation

// MARK: - PushTarget

public enum PushTarget: String, CaseIterable, Identifiable, Codable {
    case allDevices
    case testDevices
    case segment

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .allDevices:
            return "All Devices"
        case .testDevices:
            return "Test Devices"
        case .segment:
            return "Segment"
        }
    }
}

// MARK: - PushLanguage

public enum PushLanguage: String, CaseIterable, Identifiable, Codable {
    case all
    case de
    case en

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .all:
            return "All Languages"
        case .de:
            return "DE"
        case .en:
            return "EN"
        }
    }
}

// MARK: - PushMessageTemplate

public struct PushMessageTemplate: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var title: String
    public var bodyText: String
    public var target: PushTarget
    public var isSoundEnabled: Bool
    public var isBadgeEnabled: Bool
    public var badgeCount: Int
    public var isTimeSensitive: Bool
    public var language: PushLanguage
    public var urlString: String

    public init(
        id: UUID = UUID(),
        name: String,
        title: String = "",
        bodyText: String = "",
        target: PushTarget = .allDevices,
        isSoundEnabled: Bool = true,
        isBadgeEnabled: Bool = false,
        badgeCount: Int = 1,
        isTimeSensitive: Bool = false,
        language: PushLanguage = .all,
        urlString: String = ""
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.bodyText = bodyText
        self.target = target
        self.isSoundEnabled = isSoundEnabled
        self.isBadgeEnabled = isBadgeEnabled
        self.badgeCount = badgeCount
        self.isTimeSensitive = isTimeSensitive
        self.language = language
        self.urlString = urlString
    }
}
