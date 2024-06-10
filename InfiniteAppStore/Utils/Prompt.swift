import SwiftUI
import Foundation
import AppKit

/*
 class BorderlessSwiftUIWindow<V: View>: NSWindow {
     init(resizable: Bool = true, dialog: Bool = false, _ view: () -> V)...
 */

/*
 struct Demo95: View {
     var body: some View {
         Window95(title: "Hello World", onControlAction: {_ in ()}) {
             Button(action: {}) {
                 Text("Hi there!")
                     .withFont95()
             }
             .padding()
         }
         .padding()
         .frame(width: 400)
         .background(Color.green)
     }
 }
 */

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

/*
struct WindowActionHandlerKey: EnvironmentKey {
    static var defaultValue: (WindowControlAction) -> Void = { _ in }
}
*/

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


// Use BorderlessSwiftUIWindow and Prompt95
func prompt(question: String) async -> String? {
    let result = await withCheckedContinuation { continuation in
        DispatchQueue.main.async {
            let model = PromptDialogModel(title: "Question", message: question, cancellable: true, hasTextField: true)
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

//// Nil if cancelled
//func prompt(question: String) async -> String? {
//    return await withCheckedContinuation { continuation in
//        DispatchQueue.main.async {
//            let alert = NSAlert()
//            alert.messageText = question
//            alert.addButton(withTitle: "OK")
//            alert.addButton(withTitle: "Cancel")
//            let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
//            alert.accessoryView = textField
//            alert.beginSheetModal(for: NSApp.mainWindow!) { response in
//                if response == .alertFirstButtonReturn {
//                    continuation.resume(returning: textField.stringValue)
//                } else {
//                    continuation.resume(returning: nil)
//                }
//            }
//        }
//    }
//}
