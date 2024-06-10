import Foundation

struct Program: Equatable, Codable {
    var id: String

    var js = ""
    var css = ""
    var html = ""
    var title: String = ""
    var subtitle: String = ""
    var iconSymbol: String = ""
    var colorHex: String = "0000ff"
    var generating = true
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

