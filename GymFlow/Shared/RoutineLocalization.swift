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
