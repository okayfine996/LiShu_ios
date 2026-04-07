import Foundation
import SwiftData

@Observable
class FestivalManagementViewModel {
    var builtinFestivals: [FestivalOccurrence] = []
    var userFestivals: [FestivalOccurrence] = []

    func load(context: ModelContext) {
        let allBuiltins = FestivalService.builtInOccurrences()
        builtinFestivals = allBuiltins.sorted { $0.sortOrder < $1.sortOrder }
        userFestivals = FestivalService.userFestivalOccurrences(context: context)
            .sorted {
                if $0.isExpired == $1.isExpired {
                    if $0.countdownDays == $1.countdownDays {
                        return $0.name.localizedCompare($1.name) == .orderedAscending
                    }
                    return $0.countdownDays < $1.countdownDays
                }
                return !$0.isExpired && $1.isExpired
            }
    }
}
