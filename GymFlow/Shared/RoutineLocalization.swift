//
//  RoutineLocalization.swift
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

import SwiftUI
import GymFlowCore

@ViewBuilder
func routineTitleText(_ routine: Routine) -> some View {
    if routine.isBuiltIn, let slug = routine.slug {
        switch slug {
        case "push": Text("routine.push")
        case "pull": Text("routine.pull")
        case "legs": Text("routine.legs")
        default: Text(verbatim: routine.name)
        }
    } else {
        Text(verbatim: routine.name)
    }
}

func routineTitleString(_ routine: Routine, locale: Locale) -> String {
    if routine.isBuiltIn, let slug = routine.slug {
        switch slug {
        case "push": return String(localized: "routine.push", locale: locale)
        case "pull": return String(localized: "routine.pull", locale: locale)
        case "legs": return String(localized: "routine.legs", locale: locale)
        default: return routine.name
        }
    }
    return routine.name
}
