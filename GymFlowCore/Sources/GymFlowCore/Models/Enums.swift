//
//  Enums.swift
//  Kintore (internal module name: GymFlow)
//
//  Copyright © 2026 Keihong.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import Foundation

public enum ExerciseCategory: String, Codable, CaseIterable, Sendable {
    case barbell
    case dumbbell
    case machine
    case bodyweight
    case cardio
    case other
}

public enum WeightUnit: String, Codable, CaseIterable, Sendable {
    case kg
    case lb

    public static let kgToLb: Double = 2.2046226218

    public func fromKg(_ kg: Double) -> Double {
        switch self {
        case .kg: return kg
        case .lb: return kg * Self.kgToLb
        }
    }

    public func toKg(_ value: Double) -> Double {
        switch self {
        case .kg: return value
        case .lb: return value / Self.kgToLb
        }
    }

    public var step: Double {
        switch self {
        case .kg: return 2.5
        case .lb: return 5
        }
    }
}

public enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case system
    case zhHant = "zh-Hant"
    case zhHans = "zh-Hans"
    case en
    case ja
    case ko

    public static let supported: [AppLanguage] = [.zhHant, .zhHans, .en, .ja, .ko]

    public var localeIdentifier: String? {
        switch self {
        case .system: return nil
        default: return rawValue
        }
    }
}

public enum Appearance: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark
}

public enum PRType: String, Codable, CaseIterable, Sendable {
    case weight
    case e1rm
}
