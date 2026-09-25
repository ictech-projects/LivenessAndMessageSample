//
//  StreamChatService.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 25/09/26.
//
//  Wraps the GetStream Chat SDK: connects the shared `ChatClient` with the
//  per-user token from `GET /api/stream/token`. The Laravel API only mints the
//  token + channel IDs; message delivery runs entirely through this client.
//

import Combine
import Foundation
import StreamChat

@MainActor
final class StreamChatService: ObservableObject {

	static let shared = StreamChatService()

	private(set) var client: ChatClient?
	@Published private(set) var isConnected = false

	private init() {}

	func connect(_ credentials: StreamCredentials) async {
		let config = ChatClientConfig(apiKeyString: credentials.apiKey)
		let client = ChatClient(config: config)
		self.client = client

		do {
			let token = try Token(rawValue: credentials.token)
			try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
				client.connectUser(
					userInfo: UserInfo(id: credentials.userId, name: credentials.userName),
					token: token
				) { error in
					if let error {
						continuation.resume(throwing: error)
					} else {
						continuation.resume()
					}
				}
			}
			isConnected = true
			#if DEBUG
			print("✅ StreamChat connected as \(credentials.userName) (\(credentials.userId))")
			#endif
		} catch {
			isConnected = false
			#if DEBUG
			print("⚠️ StreamChat connectUser failed: \(error)")
			#endif
		}
	}

	func disconnect() {
		client?.logout { }
		client = nil
		isConnected = false
	}
}
