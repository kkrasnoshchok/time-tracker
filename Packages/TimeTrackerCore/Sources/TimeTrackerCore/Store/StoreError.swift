import Foundation

public enum StoreError: Error, Equatable {
    case emptyName
    case duplicateName
    case categoryHasEntries
    case startInFuture
    case endInFuture
    case missingEnd
    case endBeforeStart
    case overlap([UUID])
    case noRunningTimer
    case notFound
    case saveFailed(String)
}
