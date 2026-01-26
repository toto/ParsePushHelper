//
//  ParseServerStoreTests.swift
//  ParsePush
//
//  Created by Thomas Kollbach on 26.01.26.
//

import Core
import XCTest

@MainActor
final class ParseServerStoreTests: XCTestCase {
    func testMovePersistsOrder() {
        let suiteName = "ParseServerStoreTests.move.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create UserDefaults suite.")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)

        guard
            let urlA = URL(string: "https://a.example.com/parse"),
            let urlB = URL(string: "https://b.example.com/parse"),
            let urlC = URL(string: "https://c.example.com/parse")
        else {
            XCTFail("Failed to create test URLs.")
            return
        }

        let store = ParseServerStore(userDefaults: defaults)
        store.add(ParseServerConfiguration(name: "A", serverURL: urlA))
        store.add(ParseServerConfiguration(name: "B", serverURL: urlB))
        store.add(ParseServerConfiguration(name: "C", serverURL: urlC))

        store.move(from: IndexSet(integer: 0), to: 3)

        let reloadedStore = ParseServerStore(userDefaults: defaults)
        let names = reloadedStore.configurations.map(\.name)
        XCTAssertEqual(names, ["B", "C", "A"])
    }
}
