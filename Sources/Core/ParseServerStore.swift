//
//  ParseServerStore.swift
//  ParsePush
//
//  Created by Thomas Kollbach on 26.01.26.
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
public final class ParseServerStore {
    private let userDefaults: UserDefaults
    private let keychain: KeychainStore
    private let storageKey = "parseServerConfigurations"

    public private(set) var configurations: [ParseServerConfiguration] = []

    public init(userDefaults: UserDefaults = .standard, keychain: KeychainStore) {
        self.userDefaults = userDefaults
        self.keychain = keychain
        loadConfigurations()
    }

    public func add(_ configuration: ParseServerConfiguration, apiKey: String) {
        configurations.append(configuration)
        keychain.save(apiKey, for: configuration.id.uuidString)
        saveConfigurations()
    }

    public func update(_ configuration: ParseServerConfiguration, apiKey: String) {
        if let index = configurations.firstIndex(where: { $0.id == configuration.id }) {
            configurations[index] = configuration
        } else {
            configurations.append(configuration)
        }
        keychain.save(apiKey, for: configuration.id.uuidString)
        saveConfigurations()
    }

    public func apiKey(for configuration: ParseServerConfiguration) -> String? {
        keychain.read(for: configuration.id.uuidString)
    }

    public func delete(ids: [ParseServerConfiguration.ID]) {
        guard !ids.isEmpty else {
            return
        }
        configurations.removeAll { ids.contains($0.id) }
        ids.forEach { keychain.delete(for: $0.uuidString) }
        saveConfigurations()
    }

    public func move(from source: IndexSet, to destination: Int) {
        configurations.move(fromOffsets: source, toOffset: destination)
        saveConfigurations()
    }

    private func loadConfigurations() {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return
        }

        do {
            configurations = try JSONDecoder().decode([ParseServerConfiguration].self, from: data)
        } catch {
            configurations = []
        }
    }

    private func saveConfigurations() {
        do {
            let data = try JSONEncoder().encode(configurations)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            return
        }
    }
}
