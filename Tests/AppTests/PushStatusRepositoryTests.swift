//
//  PushStatusRepositoryTests.swift
//  ParsePush
//
//  Created by Thomas Kollbach on 06.02.26.
//

import XCTest
@testable import ParsePush

final class PushStatusRepositoryTests: XCTestCase {
    func testDecodeStatusesReturnsEntries() throws {
        let json = """
        {
            "results": [
                {
                    "objectId": "abc123",
                    "createdAt": "2026-02-06T10:00:00.000Z",
                    "updatedAt": "2026-02-06T11:00:00.000Z",
                    "status": "sent",
                    "numSent": 5,
                    "payload": {
                        "alert": "Hello",
                        "badge": 1,
                        "nested": {
                            "key": "value"
                        }
                    }
                },
                {
                    "objectId": "def456",
                    "createdAt": "2026-02-06T12:00:00.000Z",
                    "pushStatus": "failed"
                }
            ]
        }
        """

        let data = Data(json.utf8)
        let entries = try PushStatusRepository.decodeStatuses(from: data)

        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].id, "abc123")
        XCTAssertEqual(entries[0].createdAt, "2026-02-06T10:00:00.000Z")
        XCTAssertEqual(entries[0].updatedAt, "2026-02-06T11:00:00.000Z")
        XCTAssertEqual(entries[0].status, "sent")
        XCTAssertEqual(entries[0].numSent, 5)
        XCTAssertEqual(entries[0].payloadItems.map(\.id), ["alert", "badge", "nested"])
        XCTAssertTrue(entries[0].payloadItems.contains(where: { $0.id == "alert" && $0.value == "Hello" }))
        XCTAssertTrue(entries[0].payloadItems.contains(where: { $0.id == "badge" && $0.value == "1" }))
        XCTAssertTrue(entries[0].payloadItems.contains(where: { $0.id == "nested" && $0.value.contains("\"key\":\"value\"") }))

        XCTAssertEqual(entries[1].id, "def456")
        XCTAssertEqual(entries[1].status, "failed")
        XCTAssertTrue(entries[1].payloadItems.isEmpty)
    }

    func testDecodeStatusesThrowsOnInvalidPayload() {
        let json = """
        {
            "count": 0
        }
        """
        let data = Data(json.utf8)

        XCTAssertThrowsError(try PushStatusRepository.decodeStatuses(from: data)) { error in
            guard let repositoryError = error as? PushStatusRepository.RepositoryError else {
                XCTFail("Unexpected error type: \(error)")
                return
            }
            XCTAssertEqual(repositoryError, .decodeFailed)
        }
    }
}
