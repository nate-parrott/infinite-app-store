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
        Window95(title: program?.title.nilIfEmpty ?? "App", onControlAction: onAction ?? { _ in () }, additionalAccessoryIcon: AnyView(contactDevButton)) {
            AppViewRepresentable(id: id, onError: { errors.append($0) })
            .overlay(alignment: .bottomTrailing) {
                if errors.count > 0 {
                    ErrorView(errors: errors, id: id, onDismiss: { self.errors.removeAll() })
                        .padding()
                }
            }
            .overlay {
                if let program, let progress = program.installProgress {
                    InstallShield(name: program.title, progress: progress)
                        .onDisappear {
                            self.errors.removeAll()
                        }
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onReceive(AppStore.shared.publisher.map { $0.programs[id] }, perform: { self.program = $0 })
    }

    @ViewBuilder var contactDevButton: some View {
        Button(action: { contactDevForProgram(id: id) }) {
            Text("?").bold()
                .foregroundStyle(Color.black)
        }
        .help("Contact Developer")
    }
}

class AppViewController: NSViewController {
    var programID: String? {
        didSet {
            if programID == oldValue { return }
            guard let programID else { return }
            mainView = NSHostingView(rootView: AppWindowContentView(id: programID))
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

    @IBAction func deleteApp(_ sender: Any?) {
        guard let id = programID else { return }
        Task {
            let prompt = PromptDialogModel(title: "Uninstall this program?", message: "Can't be undone!", cancellable: true, hasTextField: false)
            let result = await prompt.run()
            if !result.cancelled {
                DispatchQueue.main.async {
                    self.view.window?.close()
                    AppStore.shared.model.programs.removeValue(forKey: id)
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
        guard let programID else { return }
        Task {
            do {
                guard let title = await prompt(question: "title:"),
                      let subtitle = await prompt(question: "description")
                else {
                    return
                }
                try await AppStore.shared.generateProgram(id: programID, params: .init(title: title, subtitle: subtitle))
//                try await AppStore.shared.generateProgram(id: programID, title: title, subtitle: subtitle)
            } catch {
                print("[Program gen] Error: \(error)")
            }
        }

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.programID = "test"
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
