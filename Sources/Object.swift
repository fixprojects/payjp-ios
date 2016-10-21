//
//  Object.swift
//  PAYJP
//
//  Created by k@binc.jp on 10/4/16.
//  Copyright © 2016 BASE, Inc. All rights reserved.
//

import Foundation

enum ObjectType: String {
    case token
    case card
}

public class Object: Decodable {
    public static func decode(_ e: Extractor) throws -> Self {
        guard let object = try ObjectType(rawValue: e <| "object") else { return try castOrFail(any: e) }
        switch object {
        case .token:
            return try castOrFail(Token(e))
        case .card:
            return try castOrFail(Card(e))
        }
    }
}