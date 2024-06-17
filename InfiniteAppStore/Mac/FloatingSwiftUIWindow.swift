import SwiftUI
import AppKit

// NSWindow subclass that displays a SwiftUI view and provides it with an environment key to perform window control actions
// The swiftUI view should be borderless and shadowless, without a title bar. You need to override canBecomeKey
// Use a NSHostingController as the contentViewController

class BorderlessSwiftUIWindow<V: View>: NSWindow {

    init(resizable: Bool = true, dialog: Bool = false, _ view: () -> V) {
        let currentMainWindowCenter: CGPoint? = NSApplication.shared.mainWindow?.frame.center

        var styleMask: NSWindow.StyleMask = [.fullSizeContentView]
        if resizable {
            styleMask.insert(.resizable)
        }
        super.init(contentRect: .zero, styleMask: styleMask, backing: .buffered, defer: true)
        rootVC = NSHostingController(rootView: RootView(content: view(), handleWindowAction: handleWindowAction(_:)))
        self.contentViewController = rootVC
        self.isMovableByWindowBackground = true
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.backgroundColor = .clear
        self.isOpaque = false
        self.isReleasedWhenClosed = false
        self.hasShadow = false
        self.level = dialog ? .floating : .normal
        // Size to fit the swiftui view
        let size = rootVC.view.intrinsicContentSize
        self.setContentSize(size)

        if dialog, let currentMainWindowCenter = currentMainWindowCenter {
            // Set center to currentMainWindowCenter
            self.setFrameOrigin(CGPoint(x: currentMainWindowCenter.x - size.width / 2, y: currentMainWindowCenter.y - size.height / 2))
        } else {
            self.center()
        }
    }

    var rootView: V {
        get { rootVC.rootView.content }
        set { rootVC.rootView.content = newValue }
    }

    private var rootVC: NSHostingController<RootView>!

    private struct RootView: View {
        var content: V
        var handleWindowAction: (WindowControlAction) -> Void

        var body: some View {
            content
                .environment(\.windowActionHandler, self.handleWindowAction)
        }
    }

    var closeOnResignMain = false
    override func resignMain() {
        super.resignMain()
        if closeOnResignMain {
            self.close()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool { true }

    func handleWindowAction(_ action: WindowControlAction) {
        switch action {
        case .minimize:
            self.miniaturize(self)
        case .maximize:
            self.zoom(self)
        case .close:
            self.close()
        }
    }
}

extension CGRect {
    var center: CGPoint {
        CGPoint(x: self.midX, y: self.midY)
    }
}
