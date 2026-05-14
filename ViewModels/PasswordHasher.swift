//
//  PasswordHasher.swift
//  music
//
//  Created by Anel Torić on 25. 4. 2026.
//

import Foundation
import CryptoKit

struct PasswordHasher {

    static func hash(_ password: String) -> String {

        let data = Data(password.utf8)

        let hashed = SHA256.hash(data: data)

        return hashed.compactMap {
            String(format: "%02x", $0)
        }
        .joined()
    }

    static func verify(
        password: String,
        against hash: String
    ) -> Bool {

        self.hash(password) == hash
    }
}
