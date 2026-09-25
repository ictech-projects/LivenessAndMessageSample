//
//  Moya+defaultProvider.swift
//  HJK
//
//  Created by Ewide Dev 5 on 11/09/25.
//

import Foundation
import Moya

extension MoyaProvider {
    static func defaultProvider() -> MoyaProvider {
        
        let accessTokenPlugin = AccessTokenPlugin(tokenClosure: { _ in
			let keychain = KeychainHelper.shared
			
			return keychain.getString(for: KeychainKey.accessToken.key).orEmpty()
        })
		
#if DEBUG
        return MoyaProvider(plugins: [NetworkLoggerPlugin(), accessTokenPlugin])
#else
		return MoyaProvider(plugins: [accessTokenPlugin])
#endif
    }
}
