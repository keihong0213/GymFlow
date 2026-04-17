import SwiftUI
import GymFlowCore

func categoryTitle(_ category: ExerciseCategory) -> LocalizedStringKey {
    switch category {
    case .barbell: "category.barbell"
    case .dumbbell: "category.dumbbell"
    case .machine: "category.machine"
    case .bodyweight: "category.bodyweight"
    case .cardio: "category.cardio"
    case .other: "category.other"
    }
}
