//
//  WeightFormatter.swift
//  Kintore (internal module name: GymFlow)
//
//  Copyright © 2026 Keihong.
//
//  Licensed under the MIT License. See LICENSE in the project root.
//

import Foundation

public struct WeightFormatter: Sendable {
    public let unit: WeightUnit
    public let locale: Locale

    public init(unit: WeightUnit, locale: Locale = .current) {
        self.unit = unit
        self.locale = locale
    }

    public func format(kg: Double) -> String {
        let value = unit.fromKg(kg)
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        let number = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(number) \(unit.rawValue)"
    }
}
