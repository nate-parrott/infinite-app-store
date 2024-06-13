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

    # Icons
    There are a few built-in icons you can use. You should pick one for the app itself. You can also reference them in your code like this: `/static/Icons/address_book.png`.
    Use only these icon identifiers:
    ```
    \(Icons.iconNames.joined(separator: ", "))
    ```

    # App Prompt
    Here is the prompt:
    App Name: '[name]'
    App Description: '[description]'

    Below, define the program as a JSON object containing the HTML/CSS/JS, and other app attributes:

    ```
    interface App {
        icon: string // Use only icons from the list above. Name only (not path) like 'address_book'
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
            let icon: String?
            let html: String?
            let css: String?
            let js: String?
        }

        AppStore.shared.modify { $0.modifyProgram(id: id, { 
            $0.installProgress = 0
            $0.title = title
            $0.subtitle = subtitle
        }) }

        let llm = try await ChatGPT(credentials: .getOrPromptForCreds(), options: .init(model: .gpt4_omni, jsonMode: true))
        var last: Output?
        for try await partial in llm.completeStreamingWithJSONObject(prompt: [LLMMessage(role: .system, content: prompt)], type: Output.self) {
            last = partial
            AppStore.shared.modify { state in
                state.modifyProgram(id: id) { program in
                    program.iconName = partial.icon ?? "executable"
                    program.html = partial.html ?? ""
                    program.css = partial.css ?? ""
                    program.js = ""
                    program.title = title
                    program.subtitle = subtitle
                    program.computeEstimatedInstallProgress(jsLen: partial.js?.count ?? 0)
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
                print("HTML: \(program.html.count); JS: \(program.js.count); CSS: \(program.css.count)")
                program.installProgress = nil
            }
        }
    }
}

extension Program {
    mutating func computeEstimatedInstallProgress(jsLen: Int) {
        let expectedHtmlLen: Int = 700
        let expectedCSSLen: Int = 700
        let expectedJSLen: Int = 700

        let finalHtmlLen: Int? = css.count > 0 ? html.count : nil
        let finalCSSLen: Int? = jsLen > 0 ? css.count : nil

        let totalLen = html.count + css.count + jsLen
        let expectedLen = (finalHtmlLen ?? expectedHtmlLen) + (finalCSSLen ?? expectedCSSLen) + max(expectedJSLen, jsLen)
        installProgress = 0.1 + Double(totalLen) / Double(expectedLen) * 0.9
    }
}
