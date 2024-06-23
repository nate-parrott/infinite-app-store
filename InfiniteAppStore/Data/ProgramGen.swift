import Foundation
import ChatToys

enum Prompts {
    private static var mobileTheming: String {
        #if os(iOS)
        return "This app should visually look like Windows 98 and use vintage design patterns, BUT be responsive to fit on a mobile device."
        #else
        return ""
        #endif
    }

    static let llmApiDoc = """
    // use llmStream to stream results from a large-language AI model
    // `result` contains the full string up to this point; when done is true, result will be the full answer.
    function llmStream(prompt: string, callback: (result: string, done: bool) => void): void
    """

    static let appleScriptApiDoc = """
    // use appleScript to execute standard applescript to control a user's computer
    async function appleScript(prompt: string) => string | null
    """

    static func generationPrompt(title: String, subtitle: String, llmEnabled: Bool, appleScriptEnabled: Bool) -> String {
        let apis: [String?] = [
            llmEnabled ? llmApiDoc : nil,
            appleScriptEnabled ? appleScriptApiDoc : nil,
        ]
        let apiStr = apis.compactMap { $0 }.joined(separator: "\n\n")
        return """
    You're a skilled software engineer developing simple local apps using HTML, CSS and JS.
    Your apps run within a webview with CORS disabled.

    I'll give you a prompt, and you'll write HTML, CSS and Javascript to make the app.
    Only call JS APIs that are available in a webview, or the special APIs described below.
    Store app state in localStorage and use utilities like prompt(), alert(), etc for convenience.

    You can call external APIs via AJAX if they don't need an API key.

    Write a complete program -- do not omit parts or leave things the user needs to fill in.
    There are no local resources provided on the domain.

    # Extra APIs
    \(apiStr.nilIfEmpty ?? "None")

    # Theming
    Make your app look like a retro Windows 98 ap.
    A base stylesheet has been applied that makes programs look like Windows 98.
    Use ordinary HTML elements (input, textarea, select, button, overflow: scroll, etc), and they'll automatically get this styling.
    Do not reference external assets.
    You don't need to draw the window title bar; it will be drawn for you.
    \(mobileTheming)

    Here's an excerpt from the stylesheet, which is automatically included:
    <style>
    \(CSS.baseCSS)
    </style>

    # Icons
    There are a few built-in icons you can use. You should pick one for the app itself. You can also reference them in your code like this: `/icons/address_book.png`.
    Use only these icon identifiers:
    ```
    \(Icons.iconNames.joined(separator: ", "))
    ```

    # App Prompt
    Here is the prompt:
    App Name: '\(title)'
    App Description: '\(subtitle)'

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
}

enum ProgramGenError: Error {
    case noOutput
}

extension AppStore {
    func generateProgram(id: String, params: NewProgramParams) async throws {
        let prompt = Prompts.generationPrompt(title: params.title, subtitle: params.subtitle, llmEnabled: params.llmEnabled, appleScriptEnabled: params.applescript)

        struct Output: Codable {
            let icon: String?
            let html: String?
            let css: String?
            let js: String?
        }

        AppStore.shared.modify { $0.modifyProgram(id: id, { 
            $0.installProgress = 0
            $0.title = params.title
            $0.subtitle = params.subtitle
            $0.applescriptEnabled = params.applescript
            $0.llmEnabled = params.llmEnabled
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
                    program.title = params.title
                    program.subtitle = params.subtitle
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
