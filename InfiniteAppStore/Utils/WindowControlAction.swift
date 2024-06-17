import SwiftUI

enum WindowControlAction: Equatable {
    case minimize
    case maximize
    case close
}

// Define environment key
struct WindowActionHandlerKey: EnvironmentKey {
    static var defaultValue: (WindowControlAction) -> Void = { _ in }
}

// Define environment value
extension EnvironmentValues {
    var windowActionHandler: (WindowControlAction) -> Void {
        get { self[WindowActionHandlerKey.self] }
        set { self[WindowActionHandlerKey.self] = newValue }
    }
}
