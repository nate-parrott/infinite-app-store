import Foundation
import ChatToys

enum Prompts {
    static let generate = """
    You're a skilled software engineer developing simple local apps using HTML, CSS and JS.
    Your apps run within a webview with CORS disabled.

    I'll give you a prompt, and you'll write HTML, CSS and Javascript to make the app.
    Only call JS APIs that are available in a webview, or the special APIs described below.
    Store app state in localStorage and use utilities like prompt(), alert(), etc for convenience.

    You can call external APIs via AJAX if they don't need an API key.

    Write a complete program -- do not omit parts or leave things the user needs to fill in.
    There are no local resources provided on the domain.

    # Extra APIs
    // use this to stream results from a large-language AI model
    // `result` contains the full string up to this point; when done is true, result will be the full answer.
    function llmStream(prompt: string, callback: (result: string, done: bool) => void): void

    # Theming
    Make your app look like a retro Windows 98 ap.
    A base stylesheet has been applied that makes programs look like Windows 98.
    Use ordinary HTML elements (input, textarea, select, button, overflow: scroll, etc), and they'll automatically get this styling.
    Do not reference external assets.
    You don't need to draw the window title bar; it will be drawn for you.

    Here's an excerpt from the stylesheet, which is automatically included:
    <style>
    \(CSS.baseCSS)
    </style>

    # App Prompt
    Here is the prompt:
    App Name: '[name]'
    App Description: '[description]'

    Below, define the program as a JSON object containing the HTML/CSS/JS, and other app attributes:

    ```
    interface App {
        html: string // Include <body> only, no <head>. You don't need to link the CSS or JS files.
        css: string
        js: string
    }
    ```

    Write your app below:
    """
}

enum ProgramGenError: Error {
    case noOutput
}

extension AppStore {
    func generateProgram(id: String, title: String, subtitle: String) async throws {
        let prompt = Prompts.generate
        .replacingOccurrences(of: "[name]", with: title)
        .replacingOccurrences(of: "[description]", with: subtitle)

        struct Output: Codable {
            let html: String?
            let css: String?
            let js: String?
        }

        let llm = try await ChatGPT(credentials: .getOrPromptForCreds(), options: .init(model: .gpt4_omni, jsonMode: true))
        var last: Output?
        for try await partial in llm.completeStreamingWithJSONObject(prompt: [LLMMessage(role: .system, content: prompt)], type: Output.self) {
            last = partial
            AppStore.shared.modify { state in
                state.modifyProgram(id: id) { program in
                    program.html = partial.html ?? ""
                    program.css = partial.css ?? ""
                    program.js = ""
                    program.title = title
                    program.subtitle = subtitle
                    program.generating = true
                }
            }
        }
        guard let output = last else {
            throw ProgramGenError.noOutput
        }
        await AppStore.shared.modifyAsync { state in
            state.modifyProgram(id: id) { program in
                program.html = output.html ?? ""
                program.css = output.css ?? ""
                program.js = output.js ?? ""
                program.generating = false
            }
        }
    }
}
