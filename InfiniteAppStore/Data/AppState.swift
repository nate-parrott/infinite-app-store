import Foundation

struct Program: Equatable, Codable, Identifiable {
    var id: String

    var js = ""
    var css = ""
    var html = ""
    var title: String = ""
    var subtitle: String = ""
    var colorHex: String = "0000ff"
    var installProgress: Double?
    var iconName: String = "executable"
}

struct AppState: Equatable, Codable {
    var programs = [String: Program]()

    mutating func modifyProgram(id: String, _ block: (inout Program) -> Void) {
        var program = programs[id] ?? .init(id: id)
        block(&program)
        programs[id] = program
    }
}

class AppStore: DataStore<AppState> {
    static let shared = AppStore(persistenceKey: "InfiniteAppStoreStore", defaultModel: .init(), queue: .main)
}

extension Program {
    static func stubsForMenu() -> [Program] {
        // Define 3 stub apps. Leave js, css, html blank
        [
            Program(id: "1", title: "App 1", subtitle: "App 1 subtitle", colorHex: "ff0000"),
            Program(id: "2", title: "App 2", subtitle: "App 2 subtitle", colorHex: "00ff00"),
            Program(id: "3", title: "App 3", subtitle: "App 3 subtitle", colorHex: "0000ff")
        ]
    }
}
