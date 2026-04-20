import Foundation
import GymFlowCore

struct EditingSetItem: Identifiable {
    let entry: SetEntry
    let exercise: Exercise
    var id: UUID { entry.id }
}
