import Foundation
import AppKit
import SwiftUI

class StatusMenuManager: NSObject {
    static let shared = StatusMenuManager()

    let statusItem: NSStatusItem
    private var window: BorderlessSwiftUIWindow<BaseStatusMenuView>?

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.setAccessibilityLabel("Infinite App Store Apps")
            button.image = NSImage(named: "icon95") // NSImage(systemSymbolName: "app.gift.fill", accessibilityDescription: "Infinite App Store Apps")
            button.imageScaling = .scaleProportionallyDown
        }
        super.init()

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(toggleMenu(sender:))
        }
    }

    func showMenu() {
        if !isVisible {
            toggleMenu(sender: nil)
        }
    }

    var isVisible: Bool {
        window?.isVisible ?? false
    }

    @objc private func toggleMenu(sender: Any?) {
        let visibleWindow = window?.isVisible ?? false ? window : nil
        if visibleWindow == nil {
            let window = BorderlessSwiftUIWindow(resizable: false, dialog: false) {
                BaseStatusMenuView()
            }
            window.level = .popUpMenu
            window.makeKeyAndOrderFront(nil)

            // TODO: is there a better way to do this?
            window.makeMain()
            NSApp.activate()
            window.closeOnResignMain = true

            // Position menu to beneath the status item (aligned to the right side of the status item button)
            let buttonRect = statusItem.button!.convert(statusItem.button!.bounds, to: nil)
            let screenRect = statusItem.button!.window!.convertToScreen(buttonRect)
            let windowRect = window.frame
            window.setFrameOrigin(NSPoint(x: screenRect.maxX - windowRect.width, y: screenRect.minY - windowRect.height))

            self.window = window
        } else {
            visibleWindow?.close()
            window = nil
        }
    }
}

extension NSApplication {
    @MainActor
    func openOrFocusProgram(id: String) {
        //             view.window?.frameAutosaveName
        if let win = windows.first(where: { ($0.contentViewController as? AppViewController)?.programID == id }) {
            win.makeKeyAndOrderFront(nil)
        } else {
            let windowController = NSStoryboard.main!.instantiateController(withIdentifier: "AppWindowController") as! NSWindowController
            let vc = windowController.window!.contentViewController!  as! AppViewController
            vc.programID = id
            windowController.window?.setFrameUsingName("Program:\(id)", force: false)
            windowController.window?.makeKeyAndOrderFront(nil)
            windowController.window?.setFrameAutosaveName("Program:\(id)")
        }
    }
}

struct BaseStatusMenuView: View {
    var body: some View {
        WithSnapshot(store: AppStore.shared, snapshot: { $0.programs.values.sorted(by: { $0.title < $1.title }) }) { programs in
            StatusMenuView(programs: programs ?? [])
        }
    }
}

struct StatusMenuView: View {
    var programs: [Program]

    @State private var hovered: Program.ID? = nil

    var body: some View {
        VStack(spacing: 0) {
            StatusMenuItem(idForHover: "new", hoveredId: $hovered, onTap: newProgram) {
                RetroIconView(name: "installer")
                Text("New App...")
            }

            if programs.count > 0 {
                HorizontalDivider95()
            }
            ForEach(programs) {
                cell(program: $0)
            }
        }
        .padding(1)
        .onHover {
            if !$0 { self.hovered = nil }
        }
        .background(Color.gray95)
        .with95DepthEffect(pushed: false)
        .frame(width: 250)
        .modifier(Demo95OuterStyles())
    }

    private func newProgram() {
        Task {
            guard let title = await prompt(question: "Choose a name for your app:", title: "Create App (1/2)"),
                  let subtitle = await prompt(question: "Describe your app briefly:", title: "Create App (2/2)")
            else {
                return
            }
            let id = UUID().uuidString
            open(programId: id)
            try await AppStore.shared.generateProgram(id: id, title: title, subtitle: subtitle)
        }
    }

    private func open(programId: String) {
        DispatchQueue.main.async {
            NSApp.openOrFocusProgram(id: programId)
        }
    }

    @ViewBuilder func cell(program: Program) -> some View {
        StatusMenuItem(idForHover: "program:\(program.id)", hoveredId: $hovered, onTap: {
            open(programId: program.id)
        }, label: {
            RetroIconView(name: program.iconName)

            Text(program.title)
        })
    }
}

struct StatusMenuItem<L: View>: View {
    var idForHover: String
    @Binding var hoveredId: String?
    var onTap: () -> Void
    @ViewBuilder var label: () -> L

    var body: some View {
        let hovered = idForHover == hoveredId

        HStack {
            label()
        }
        .padding(.horizontal, 6)
        .frame(height: 34)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(hovered ? Color.white : Color.black)
        .background {
            if hovered {
                Color.blue95
            }
        }
        .contentShape(.rect)
        .onHover {
            if $0 { self.hoveredId = idForHover }
        }
        .onTapGesture(perform: onTap)
    }
}

struct RetroIconView: View {
    var name: String

    var body: some View {
        Image(nsImage: Icons.iconWithName(name) ?? Icons.iconWithName("executable")!)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 20, height: 20)
    }
}

#Preview {
    StatusMenuView(programs: Program.stubsForMenu())
        .frame(width: 300)
}

//private class CustomMenuItemView: NSView {
//    private let titleLabel: NSTextField
//
//    init(title: String) {
//        titleLabel = NSTextField(labelWithString: title)
//        super.init(frame: NSRect(x: 0, y: 0, width: 200, height: 22))
//
//        addSubview(titleLabel)
//        titleLabel.translatesAutoresizingMaskIntoConstraints = false
//        titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
//        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
//
//        // Customize the selection color
//        wantsLayer = true
//        layer!.backgroundColor = NSColor.blue.cgColor
//
//        let trackingArea = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil)
//        addTrackingArea(trackingArea)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
////    override func draw(_ dirtyRect: NSRect) {
////        super.draw(dirtyRect)
////
////        if isHighlighted {
////            layer?.backgroundColor = NSColor.red.cgColor
////        } else {
////            layer?.backgroundColor = NSColor.clear.cgColor
////        }
////    }
//
//    var isHighlighted: Bool = false {
//        didSet {
//            layer!.backgroundColor = isHighlighted ? NSColor.red.cgColor : NSColor.blue.cgColor
//        }
//    }
//
//    override func mouseEntered(with event: NSEvent) {
//        isHighlighted = true
//    }
//
//    override func mouseExited(with event: NSEvent) {
//        isHighlighted = false
//    }
//}
