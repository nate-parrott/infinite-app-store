import Foundation

enum Icons {
    static let iconNames: [String] = [
        "plug",
        "address_book",
        "battery",
        "calendar",
        "camera",
        "audio",
        "certificate",
        "channels",
        "character_map",
        "chart",
        "clean_drive",
        "connected_world",
        "desktop",
        "fonts",
        "directx",
        "doctor",
        "globe",
        "hardware",
        "help_book",
        "help",
        "internet_wizard",
        "joystick",
        "keyboard",
        "keys",
        "mailbox",
        "minesweeper",
        "modem",
        "mouse",
        "mouse_trails",
        "agent",
        "agent_file",
        "error",
        "executable",
        "information",
        "warning",
        "multimedia",
        "arrow",
        "televisions",
        "newspaper",
        "note",
        "paint",
        "recycle_bin",
        "restrict",
        "scandisk",
        "scanner",
        "search",
        "sound",
        "spider",
        "standby",
        "themes",
        "time_date",
        "tools",
        "tree",
        "calendar_user",
        "users",
        "image_check",
        "windows",
        "magnifying_glass",
        "file",
        "world_star",
        "write_file",
        "write_yellow"
      ]

    static func iconWithName(_ name: String) -> UINSImage? {
        let url = Bundle.main.url(forResource: "StaticWebFiles", withExtension: "")!
            .appendingPathComponent("Icons")
            .appendingPathComponent(name)
            .appendingPathExtension("png")
        return UINSImage(contentsOfFile: url.path)
    }
}
