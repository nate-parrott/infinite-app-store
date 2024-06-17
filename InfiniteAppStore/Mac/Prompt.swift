import SwiftUI
import Foundation

struct PromptDialogModel: Equatable {
    var title: String
    var message: String
    var cancellable: Bool
    var hasTextField: Bool
    var defaultText = ""
}

struct PromptDialogResult: Equatable {
    var text: String
    var cancelled: Bool
}

struct Prompt95: View {
    var model: PromptDialogModel
    var onResult: (PromptDialogResult) -> Void

    @State private var text: String = ""
    @Environment(\.windowActionHandler) var onControlAction

    var body: some View {
        // Use windows 95 style
        Window95(title: model.title, onControlAction: handleControlAction) {
            VStack(alignment: .leading) {
                Text(model.message)
                    .withFont95()
                if model.hasTextField {
                    AutofocusTextField(placeholder: "Enter text", text: $text)
                        .frame(width: 300)
                        .onSubmit {
                            onResult(PromptDialogResult(text: text, cancelled: false))
                            onControlAction(.close)
                        }
                }
                HStack {
                    Spacer()
                    if model.cancellable {
                        Button("Cancel") {
                            self.cancel()
                        }
                    }
                    Button("OK") {
                        onResult(PromptDialogResult(text: text, cancelled: false))
                        onControlAction(.close)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            self.text = model.defaultText
        }
    }

    private func handleControlAction(_ action: WindowControlAction) {
        if action == .close {
            cancel()
        } else {
            onControlAction(action)
        }
    }

    private func cancel() {
        onResult(PromptDialogResult(text: "", cancelled: true))
        onControlAction(.close)
    }
}

// Use @FocusState
struct AutofocusTextField: View {
    var placeholder: String
    @Binding var text: String

    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .focused($isFocused)
            .onAppear {
                isFocused = true
            }
    }
}

#if os(macOS)
import AppKit

// Use BorderlessSwiftUIWindow and Prompt95
func prompt(question: String, title: String = "Question") async -> String? {
    let result = await withCheckedContinuation { continuation in
        DispatchQueue.main.async {
            let model = PromptDialogModel(title: title, message: question, cancellable: true, hasTextField: true)
            let window = BorderlessSwiftUIWindow(resizable: false, dialog: true) {
                Prompt95(model: model) { result in
                    continuation.resume(returning: result.cancelled ? nil : result.text)
                }
            }
            window.makeKeyAndOrderFront(nil)
        }
    }
    return result
}

extension PromptDialogModel {
    func run() async -> PromptDialogResult {
        let result = await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let window = BorderlessSwiftUIWindow(resizable: false, dialog: true) {
                    Prompt95(model: self) { result in
                        continuation.resume(returning: result)
                    }
                }
                window.makeKeyAndOrderFront(nil)
            }
        }
        return result
    }
}

#else

func prompt(question: String, title: String = "Question") async -> String? {
    let res = await PromptDialogModel(title: title, message: question, cancellable: true, hasTextField: true).run()
    return res.cancelled ? nil : res.text
}

extension PromptDialogModel {
    func run() async -> PromptDialogResult {
        let (ok, text) = await UIApplication.shared.prompt(title: title, message: message, showTextField: hasTextField, placeholder: nil)
        return .init(text: text ?? "", cancelled: !ok)
    }
}

#endif
