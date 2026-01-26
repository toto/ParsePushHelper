//
//  KeychainStore.swift
//  ParsePush
//
//  Created by Thomas Kollbach on 26.01.26.
//

import Foundation
import Security

public final class KeychainStore {
    private let service: String

    public init(service: String = "com.parsepushhelper.apikey") {
        self.service = service
    }

    @discardableResult
    public func save(_ value: String, for key: String) -> Bool {
        delete(for: key)
        guard let data = value.data(using: .utf8) else {
            return false
        }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecValueData: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    public func read(for key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    public func delete(for key: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
