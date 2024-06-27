import Combine
import SwiftUI

#if os(macOS)

struct AppViewRepresentable: NSViewRepresentable {
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

#else

struct AppViewRepresentable: UIViewRepresentable {
    var id: String
    var onError: ((String) -> Void)?

    func makeUIView(context: Context) -> AppView {
        AppView(id: id)
    }

    func updateUIView(_ nsView: AppView, context: Context) {
        nsView.webView.onError = onError
        // Can't update id
    }
}

#endif

class AppView: CrossPlatformView {
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

    override func layout_crossplatform() {
        super.layout_crossplatform()
        webView.frame = bounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var program: Program? {
        didSet {
            webView.llmEnabled = program?.llmEnabled ?? false
            webView.applescriptEnabled = program?.applescriptEnabled ?? false
#if os(macOS)
            self.window?.title = program?.title ?? "App"
            #endif
        }
    }

    override func didMoveToWindow_crossplatform() {
        super.didMoveToWindow_crossplatform()
        #if os(macOS)
        self.window?.title = program?.title ?? "App"
        #endif
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
            "<meta name='viewport' content='width=device-width, initial-scale=1.0'>",
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

struct ErrorView: View {
    var errors: [String]
    var id: String
    var onDismiss: () -> Void

    @State private var contactDevSheet: ContactDevSheetModel?

    struct ContactDevSheetModel: Identifiable {
        var id: String
        var initialMsg: String?
    }

    var body: some View {
        VStack {
            Text("Encountered error :(")
            HStack {
                Button(action: reportErrors) {
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
        .sheet(item: $contactDevSheet, content: { msg in
            ContactDevView(programId: msg.id, initialMessage: msg.initialMsg)
        })
    }

    private func reportErrors() {
        if errors.count == 0 { return }
        var lines = ["I'm seeing errors:"]
        lines += errors.map { "> " + $0 }
        lines.append("Why the errors? Write a few words explaining why, then fix the app.")
        let msg = lines.joined(separator: "\n")

        #if os(iOS)
        self.contactDevSheet = .init(id: id, initialMsg: msg)
        #else
        let win = getOrCreateContactDevWindow(id: id)
        win.makeKeyAndOrderFront(nil)
        // HACK: Avoid race condition where thread isn't init'd before view appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let thread = ContactDevThread.all.compactMap(\.value).first(where: { $0.program?.id == id }) else {
                return
            }
            thread.send(message: msg)
        }
        #endif
    }
}
