import ChatToys
import SwiftUI

struct ContactDevView: View {
    var programId: String

    @Environment(\.windowActionHandler) var onControlAction

    var body: some View {
        Color.clear
            .overlay {
                WithSnapshot(store: AppStore.shared, snapshot: { $0.programs[programId] }) { prog in
                    if let prog = prog ?? nil {
                        Window95(title: "Contact Developer for \(prog.title)", onControlAction: onControlAction) {
                            ContactDevViewInner(program: prog)
                        }
                    }
                }
            }
            .frame(idealWidth: 400, idealHeight: 500)
    }
}

struct ContactDevViewInner: View {
    var program: Program
    @StateObject var thread = ContactDevThread()

    @State private var message = ""

    var body: some View {
        VStack(spacing: 10) {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEachUnidentifiable(items: thread.displayableMessages) { message in
                        DevMessageView(message: message)
                    }
                    if thread.typing {
                        Text("Developer is typing...")
                            .opacity(0.5)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.white)
            .recessed95Effect()

            HStack {
                TextField("Message...", text: $message)
                    .onSubmit {
                        submit()
                    }
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 8)
                    .frame(height: 30)
                    .background(Color.white)
                    .recessed95Effect()

                Button(action: submit, label: {
                    Text("Send")
                })
            }
        }
        .padding()
        .onAppear {
            thread.program = self.program
            thread.sendInitialMessages()
        }
        .onChange(of: program, perform: { thread.program = $0 })
    }

    private func submit() {
        guard message != "" else { return }
        let message = self.message
        thread.send(message: message)
        self.message = ""
    }
}

private struct DevMessageView: View {
    var message: ContactDevThread.Message

    var body: some View {
        let labelWidth: CGFloat = 80
        Group {
            switch message {
            case .system, .hiddenUserMessage: EmptyView()
            case .user(let string):
                HStack(alignment: .firstTextBaseline, content: {
                    Text("You:")
                        .frame(width: labelWidth)
                        .foregroundStyle(Color.red)

                    Text(string)
                })
            case .textReply(let string):
                HStack(alignment: .firstTextBaseline, content: {
                    Text("Developer:")
                        .frame(width: labelWidth)
                        .foregroundStyle(Color.blue95)

                    Text(string)
                })
            case .editProgram:
                HStack(alignment: .firstTextBaseline, content: {
                    Text("Developer:")
                        .frame(width: labelWidth)
                        .foregroundStyle(Color.blue95)

                    Text("*type type type*")
                })
            case .editProgramConfirmation:
                EmptyView()
            case .error(let str):
                HStack(alignment: .firstTextBaseline, content: {
                    Text("Error:")
                        .frame(width: labelWidth)
                        .foregroundStyle(Color.orange)

                    Text("\(str)")
                })

            }
        }
        .multilineTextAlignment(.leading)
        .lineLimit(nil)
    }
}

class ContactDevThread: ObservableObject {
    init() {
        Self.all.append(.init(value: self))
    }

    deinit {
        Self.all.removeAll(where: { $0.value === self })
    }

    var program: Program?

    struct EditProgramParams: Equatable, Codable {
        var html: String?
        var css: String?
        var js: String?
        var title: String?
        var icon: String?
    }

    enum Message: Equatable, Codable {
        case system(String)
        case user(String)
        case hiddenUserMessage(String)
        case textReply(String)
        case editProgram(EditProgramParams)
        case error(String)
        case editProgramConfirmation

        var asEditProgramParams: EditProgramParams? {
            if case .editProgram(let editProgramParams) = self {
                return editProgramParams
            }
            return nil
        }
    }

    @Published var messages = [Message]()
    @Published var typing = false

    var displayableMessages: [Message] {
        var messages = self.messages
        // Remove hidden initial messages
        if let f = messages.first, case .system = f {
            messages.removeFirst()
        }
        if let f = messages.first, case .editProgram = f {
            messages.removeFirst()
        }
        if let f = messages.first, case .editProgramConfirmation = f {
            messages.removeFirst()
        }
        return messages
    }

    private var task: Task<Void, Never>?

    @MainActor
    func send(message: String) {
        task?.cancel()
        guard let program = self.program else { return }

        messages.append(.user(message))

        task = Task { @MainActor in
            var program = program
            do {
                self.typing = true
                defer {
                    if !Task.isCancelled {
                        self.typing = false
                    }
                }

                let llm = try await ChatGPT(credentials: .getOrPromptForCreds(), options: .init(model: .gpt4_omni, jsonMode: false))

            mainloop:
                while true {
                    try Task.checkCancellation()
                    let prompt = self.llmMessages(program: program)

                    var latest: Message?
                    for try await partial in llm.completeStreaming(prompt: prompt, functions: self.functions) {
                        try Task.checkCancellation()
                        if latest != nil {
                            self.messages.removeLast()
                        }
                        latest = self.parseResponse(llmMessage: partial)
                        if let latest {
                            self.messages.append(latest)
                        }
                    }

                    guard let latest else { break mainloop } // not expected

                    switch latest {
                    case .system, .user, .hiddenUserMessage, .error, .editProgramConfirmation: break mainloop // not expected
                    case .textReply: break mainloop // handled already
                    case .editProgram(let editProgramParams):
                        program.apply(editProgramParams)
                        try Task.checkCancellation()
                        await AppStore.shared.modifyAsync { state in
                            state.modifyProgram(id: program.id) { program in
                                program.apply(editProgramParams)
                            }
                        }
                        messages.append(.editProgramConfirmation)
                        // continue
                    }
                }
            } catch {
                if !Task.isCancelled {
                    self.messages.append(.error("\(error)"))
                }
            }
        }
    }

    private func parseResponse(llmMessage: LLMMessage) -> Message? {
        if let fn = llmMessage.functionCall {
            if fn.name == "edit_program" {
                if let params = fn.decodeArguments(as: EditProgramParams.self, stream: true) {
                    return .editProgram(params)
                }
                return .editProgram(EditProgramParams())
            } else {
                return nil
            }
        }
        if llmMessage.role == .assistant {
            return .textReply(llmMessage.content)
        }
        return nil
    }

    func sendInitialMessages() {
        assert(program != nil)
        let program = self.program!
        let system = Prompts.generate
            .replacingOccurrences(of: "[name]", with: program.title)
            .replacingOccurrences(of: "[description]", with: program.subtitle)

        let welcomeMsg: String = [
            "What's up?",
            "Ugh, what do you want?",
            "Hi! Thanks so much for reaching out. I'm sorry you're not having a good experience with the app. What can I do for you?",
            "Hi... can I fix the app for you?",
            "Feature request? Bug? What is it?",
        ].randomElement()!

        self.messages = [
            .system(system),
            .editProgram(EditProgramParams(html: program.html, css: program.css, js: program.js, icon: program.iconName)),
            .editProgramConfirmation,
            .hiddenUserMessage("User entered the support chat. They may request edits to your program. Use the edit_program function to do this."),
            .textReply(welcomeMsg),

        ]
    }

    private var functions: [LLMFunction] {
        [
            LLMFunction(name: "edit_program", description: "Update the code of your program. Only update fields you need to change. If, for example, you want to change JS but not HTML, only set the JS field. (This would replace existing JS)", parameters: [
                "js": .string(description: nil),
                "css": .string(description: nil), 
                "html": .string(description: nil),
                "icon": .string(description: nil)
            ])
        ]
    }

    private func llmMessages(program: Program) -> [LLMMessage] {
        var items = messages.map { llmMessage(forMessage: $0) }
        // Elide all but last editProgram call
        if let lastIdx = messages.lastIndex(where: { $0.asEditProgramParams != nil }) {
            for (i, item) in items.enumerated() {
                if item.role == .assistant && item.functionCall?.name == "edit_program" && i != lastIdx {
                    items[i].content = "...Old content omitted..."
                }
            }
            // last editprogram call may be partial, so update it to reflect last full state of program
            items[lastIdx].content = EditProgramParams(html: program.html, css: program.css, js: program.js, icon: program.iconName).jsonString
        }
        return items
    }

    private func llmMessage(forMessage message: Message) -> LLMMessage {
        switch message {
        case .system(let string):
            return LLMMessage(role: .system, content: string)
        case .user(let string):
            return LLMMessage(role: .user, content: string)
        case .hiddenUserMessage(let string):
            return LLMMessage(role: .user, content: string)
        case .textReply(let string):
            return LLMMessage(role: .assistant, content: string)
        case .editProgram(let editProgramParams):
            return LLMMessage(role: .assistant, content: "", functionCall: LLMMessage.FunctionCall(name: "edit_program", arguments: editProgramParams.jsonString))
        case .error(let string):
            return LLMMessage(role: .system, content: "Error: \(string)")
        case .editProgramConfirmation:
            return LLMMessage(role: .function, content: "OK", nameOfFunctionThatProduced: "edit_program")
        }
    }
}

extension ContactDevThread {
    static var all = [WeakRef<ContactDevThread>]()
}

struct WeakRef<Obj: AnyObject> {
    weak var value: Obj?
}

private extension Program {
    mutating func apply(_ edits: ContactDevThread.EditProgramParams) {
        if let js = edits.js {
            self.js = js
        }
        if let html = edits.html {
            self.html = html
        }
        if let css = edits.css {
            self.css = css
        }
        if let icon = edits.icon {
            self.iconName = icon
        }
    }
}
