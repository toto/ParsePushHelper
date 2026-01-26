//
//  ParseServerStoreTests.swift
//  ParsePush
//
//  Created by Thomas Kollbach on 26.01.26.
//

import XCTest
@testable import ParsePush

@MainActor
final class ParseServerStoreTests: XCTestCase {
    func testMovePersistsOrder() {
        let suiteName = "ParseServerStoreTests.move.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create UserDefaults suite.")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)
        let keychain = KeychainStore(service: suiteName)

        guard
            let urlA = URL(string: "https://a.example.com/parse"),
            let urlB = URL(string: "https://b.example.com/parse"),
            let urlC = URL(string: "https://c.example.com/parse")
        else {
            XCTFail("Failed to create test URLs.")
            return
        }

        let store = ParseServerStore(userDefaults: defaults, keychain: keychain)
        store.add(
            ParseServerConfiguration(name: "A", serverURL: urlA, appID: "A1"),
            apiKey: "key-a"
        )
        store.add(
            ParseServerConfiguration(name: "B", serverURL: urlB, appID: "B1"),
            apiKey: "key-b"
        )
        store.add(
            ParseServerConfiguration(name: "C", serverURL: urlC, appID: "C1"),
            apiKey: "key-c"
        )

        store.move(from: IndexSet(integer: 0), to: 3)

        let reloadedStore = ParseServerStore(userDefaults: defaults, keychain: keychain)
        let names = reloadedStore.configurations.map(\.name)
        XCTAssertEqual(names, ["B", "C", "A"])
    }
}
