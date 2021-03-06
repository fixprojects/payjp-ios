//
//  CardNumber.swift
//  PAYJP
//
//  Created by Tadashi Wakayanagi on 2019/07/30.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

import Foundation

struct CardNumber {
    let value: String
    let formatted: String
    let brand: CardBrand
    let display: String
    let mask: String
}
