//
//  EditingSetItem.swift
//  Kintore (internal module name: GymFlow)
//
//  Copyright © 2026 Keihong.
//
//  Licensed under the MIT License. See LICENSE in the project root.
//

import Foundation
import GymFlowCore

struct EditingSetItem: Identifiable {
    let entry: SetEntry
    let exercise: Exercise
    var id: UUID { entry.id }
}
