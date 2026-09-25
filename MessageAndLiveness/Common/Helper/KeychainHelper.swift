//
//  KeychainManager.swift
//  RecipeBuddy
//
//  Created by Ewide Dev 5 on 20/10/25.
//

import Foundation
import Security

nonisolated final class KeychainHelper {
	static let shared = KeychainHelper()
	
	private init() {}
	
	func save(_ value: String, for key: String) {
		guard let data = value.data(using: .utf8) else { return }
		
		delete(for: key)
		
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: key,
			kSecValueData as String: data,
			kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
		]
		
		SecItemAdd(query as CFDictionary, nil)
	}
	
	func save(_ value: Bool, for key: String) {
		let bytes: [UInt8] = value ? [1] : [0]
		let data = Data(bytes)
		
		delete(for: key)
		
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: key,
			kSecValueData as String: data,
			kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
		]
		
		SecItemAdd(query as CFDictionary, nil)
	}
	
	func save(_ value: Int, for key: String) {
		guard let data = String(value).data(using: .utf8) else { return }
		
		delete(for: key)
		
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: key,
			kSecValueData as String: data,
			kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
		]
		
		SecItemAdd(query as CFDictionary, nil)
	}
	
	func getString(for key: String) -> String? {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: key,
			kSecReturnData as String: true,
			kSecMatchLimit as String: kSecMatchLimitOne
		]
		
		var dataRef: AnyObject?
		let status = SecItemCopyMatching(query as CFDictionary, &dataRef)
		
		guard status == errSecSuccess, let data = dataRef as? Data, !String(decoding: data, as: UTF8.self).isEmpty else {
			return nil
		}
		
		return String(decoding: data, as: UTF8.self)
	}
	
	func getBool(for key: String) -> Bool? {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: key,
			kSecReturnData as String: true,
			kSecMatchLimit as String: kSecMatchLimitOne
		]
		
		var dataRef: AnyObject?
		let status = SecItemCopyMatching(query as CFDictionary, &dataRef)
		
		guard status == errSecSuccess, let data = dataRef as? Data, let firstBit = data.first else {
			return nil
		}
		
		return firstBit == 1
	}
	
	func getInt(for key: String) -> Int? {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: key,
			kSecReturnData as String: true,
			kSecMatchLimit as String: kSecMatchLimitOne
		]
		
		var dataRef: AnyObject?
		let status = SecItemCopyMatching(query as CFDictionary, &dataRef)
		
		guard status == errSecSuccess, let data = dataRef as? Data, !String(decoding: data, as: UTF8.self).isEmpty else {
			return nil
		}
		
		return Int(String(decoding: data, as: UTF8.self))
	}
	
	func delete(for key: String) {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: key
		]
		SecItemDelete(query as CFDictionary)
	}
}
