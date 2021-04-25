//
//  extensions.swift
//  app
//
//  Created by Sergey Romanenko on 25.04.2021.
//

import Foundation

extension Bool {
    var int: Int { self ? 1 : 0 }
}

extension Data {
    var hex: String { map{ String(format: "%02x", $0) }.joined() }
}
