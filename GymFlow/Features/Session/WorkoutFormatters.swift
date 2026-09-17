//
//  WorkoutFormatters.swift
//  Kintore (internal module name: GymFlow)
//
//  Copyright © 2026 Keihong.
//
//  Licensed under the MIT License. See LICENSE in the project root.
//

import Foundation

enum WorkoutFormatters {
    static func duration(fromSeconds sec: Int) -> String {
        let h = sec / 3600
        let m = (sec % 3600) / 60
        let s = sec % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }

    static func distance(meters: Double, locale: Locale) -> String {
        let km = meters / 1000
        let nf = NumberFormatter()
        nf.locale = locale
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 2
        let num = nf.string(from: NSNumber(value: km)) ?? "\(km)"
        return "\(num) km"
    }
}
