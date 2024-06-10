import Cocoa
import WebKit
import Combine
import SwiftUI

struct AppWindowContentView: View {
    var id: String
    var onAction: ((WindowControlAction) -> Void)?

    @State private var program: Program?
    @State private var errors = [String]()

    var body: some View {
        Window95(title: program?.title.nilIfEmpty ?? "App", onControlAction: onAction ?? { _ in () }) {
            AppViewRepresentable(id: id, onError: { errors.append($0) })
            .overlay(alignment: .bottomTrailing) {
                if errors.count > 0 {
                    ErrorView(errors: errors, id: id, onDismiss: { self.errors.removeAll() })
                        .padding()
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

private struct ErrorView: View {
    var errors: [String]
    var id: String
    var onDismiss: () -> Void

    var body: some View {
        VStack {
            Text("Encountered error :(")
            HStack {
                Button(action: {}) {
                    Text("Report to Developer")
                }
                Button(action: onDismiss) {
                    Text("Ignore")
                }
            }
        }
        .padding()
        .with95DepthEffect(pushed: false)
        .background {
            Color.black.opacity(0.2)
                .offset(x: 3, y: 3)
        }
    }
}

class AppViewController: NSViewController {
    var id: String? {
        didSet {
            if id == oldValue { return }
            guard let id else { return }
            mainView = NSHostingView(rootView: AppWindowContentView(id: id))
            mainView?.sizingOptions = []
            mainView?.rootView.onAction = { [weak self] action in
                guard let self, let window = self.view.window else { return }
                switch action {
                case .minimize:
                    window.miniaturize(nil)
                case .maximize:
                    window.zoom(nil)
                case .close:
                    window.close()
                }
            }
        }
    }

    private var mainView: NSHostingView<AppWindowContentView>? {
        didSet {
            oldValue?.removeFromSuperview()
            if let mainView = mainView {
                view.addSubview(mainView)
                mainView.frame = view.bounds
            }
        }
    }

    @IBAction func regenerate(_ sender: Any?) {
        guard let id else { return }
        Task {
            do {
                guard let title = await prompt(question: "title:"),
                      let subtitle = await prompt(question: "description")
                else {
                    return
                }
                try await AppStore.shared.generateProgram(id: id, title: title, subtitle: subtitle)
            } catch {
                print("[Program gen] Error: \(error)")
            }
        }

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.id = "test"
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        let buttons: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
        for btn in buttons {
            self.view.window?.standardWindowButton(btn)?.isHidden = true
        }
        self.view.window?.isMovableByWindowBackground = true
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        mainView?.frame = view.bounds
    }
}

private struct AppViewRepresentable: NSViewRepresentable {
    var id: String
    var onError: ((String) -> Void)?

    func makeNSView(context: Context) -> AppView {
        AppView(id: id)
    }

    func updateNSView(_ nsView: AppView, context: Context) {
        nsView.webView.onError = onError
        // Can't update id
    }
}

private class AppView: NSView {
    let webView = InfiniteWebView()
    private var subscriptions = Set<AnyCancellable>()
    let id: String

    init(id: String) {
        self.id = id
        super.init(frame: .zero)

        AppStore.shared.publisher.map { $0.programs[id] }
            .removeDuplicates()
            .sink { [weak self] program in
                self?.program = program
            }
            .store(in: &subscriptions)

        AppStore.shared.publisher.map { $0.programs[id]?.fullCode ?? "" }
            .removeDuplicates()
            .sink { [weak self] code in
                self?.code = code
            }
            .store(in: &subscriptions)

        addSubview(webView)
    }

    override func layout() {
        super.layout()
        webView.frame = bounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var program: Program? {
        didSet {
            // no op
            self.window?.title = program?.title ?? "App"
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.window?.title = program?.title ?? "App"
    }

    private var code: String? {
        didSet {
            if code != oldValue, let code {
                webView.loadHTMLString(code, baseURL: URL(string: "http://localhost:50082")!)
            }
        }
    }
}

extension Program {
    var fullCode: String {
        let lines = [
            html,
            "<style>",
            CSS.baseCSS,
            "</style>",
            "<style>",
            css,
            "</style>",
            "<script>",
            js,
            "</script>",
        ]
        return lines.joined(separator: "\n")
    }
}
