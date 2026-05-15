import Foundation

struct AppDependencies {
    let settings: SettingsProviding
    let eventStore: EventStoreProtocol
    let timeTools: TimeStringTools
}
