//
//  UInt+orZero.swift
//  HJK
//
//  Created by Ewide Dev 5 on 11/09/25.
//

import Foundation

extension Optional where Wrapped == UInt {
    func orZero() -> UInt {
        self ?? 0
    }
}
