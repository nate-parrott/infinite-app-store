import ChatToys
import WebKit
import ObjectiveC

#if os(macOS)
import AppKit
#else
import UIKit
#endif

class InfiniteWebView: WKWebView {
    var onError: ((String) -> Void)?

    var applescriptEnabled = false
    var llmEnabled = false // allow app to call LLM

    init() {
        let config = WKWebViewConfiguration()
        let prefs = WKPreferences()
        // Use undocumented api to enable devtools:
        prefs.setValue(true, forKey: "developerExtrasEnabled")
        // Disable CORS
        WDBSetWebSecurityEnabled(prefs, false); // yikes!
        config.preferences = prefs

        // Inject these into the webview
        let userScript = """
        // Redirect all window error and console.error to the bridge
        window.onerror = function(message, source, lineno, colno, error) {
            const fullErrString = error ? error.stack : message;
            window.webkit.messageHandlers.reportError.postMessage(Array.from(arguments).join(' '));
        };

        const oldError = console.error;
        console.error = function() {
            window.webkit.messageHandlers.reportError.postMessage(Array.from(arguments).join(' '));
            oldError.apply(this, arguments);
        };

        // Set up multi-callback bridge
        (function() {
            window.__bridge_callbacks = {};
            let lastBridgeCallbackId = 0;

            function assignCallbackId() {
                const i = lastBridgeCallbackId++;
                return i.toString();
            }

            // (name: string, params: Any, callback: (result: Any, done: Bool) => void)
            window.__call_multi_callback_function = function(name, params, callback) {
                const callbackId = assignCallbackId();
                window.__bridge_callbacks[callbackId] = (result, done) => {
                    if (done) {
                        delete window.__bridge_callbacks[callbackId];
                    }
                    callback(result, done);
                }
                window.webkit.messageHandlers[name].postMessage([callbackId, params]);
            };
        })();

        // Set up streaming bridge
        // (prompt: string, callback: (result: string, done: bool) => void)
        function llmStream(prompt, callback) {
            window.__call_multi_callback_function('llmStream', prompt, callback);
        }

        async function appleScript(script) {
            const result = await window.webkit.messageHandlers.appleScript.postMessage(script);
            return result;
        }
        """
        let script = WKUserScript(source: userScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        config.userContentController.addUserScript(script)

        super.init(frame: .zero, configuration: config)
        self.uiDelegate = self
        self.navigationDelegate = self

        config.userContentController.bridgeFunction(name: "reportError", paramType: String.self) { [weak self] message, callback in
            print("[Webview Error] \(message)")
            self?.onError?(message)
            callback(.success("OK"))
        }

        config.userContentController.bridgeFunction(name: "appleScript", paramType: String.self) { [weak self] code, callback in
            enum ScriptError: Error {
                case deallocated
                case blocked
                case scriptError(String)
            }
            guard let self else {
                callback(.failure(ScriptError.deallocated))
                return
            }
            guard self.applescriptEnabled else {
                callback(.failure(ScriptError.blocked))
                return
            }
            Task {
                print("[Applescript] Running: \n`\(code)\n`")
                do {
                    let result = try await Scripting.runAppleScript(script: code)
                    print("[Applescript] Result: \n`\(result ?? "")\n`")
                    callback(.success(result ?? NSNull()))
                } catch {
                    print("[Applescript] Error: \n`\(error)\n`")
                    self.onError?("\(error)")
                    callback(.failure(ScriptError.scriptError("\(error)")))
                }
            }
        }

        // Param 1: prompt; param 2: name of calback function
        config.userContentController.bridgeMultiCallbackFunction(name: "llmStream", paramType: String.self, webview: self) { [weak self] prompt, emit, done in
            guard let self, self.llmEnabled else { return }
            Task {
                do {
                    print("[LLMStream]: Prompting:\n\(prompt)")
                    let llm = try await ChatGPT(credentials: .getOrPromptForCreds(), options: .init(model: .gpt35_turbo))
                    var last: String?
                    for try await partial in llm.completeStreaming(prompt: [LLMMessage(role: .user, content: prompt)]) {
                        emit(partial.content)
                        last = partial.content
                    }
                    if let last {
                        print("[LLMStream]: Result:\n\(last)")
                    }
                    done()
                } catch {
                    done()
                }
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private enum MultiCallbackFnError: Error {
    case wrongParams
}

extension WKUserContentController {
    func bridgeFunction<Params>(name: String, paramType: Params.Type, _ handler: @escaping BridgedFunction<Params>.Handler) {
        addScriptMessageHandler(BridgedFunction(handler: handler), contentWorld: .page, name: name)
    }

    // Async functions are bridged by replying immediately, then calling a named function, __bridge_callbacks[id](done: bool, result: Any) until done
    func bridgeMultiCallbackFunction<Params>(
        name: String,
        paramType: Params.Type,
        webview: WKWebView,
        _ handler: @escaping (Params, @escaping (Any) -> Void /* Emit result */, @escaping () -> Void /* Call when done */) -> Void
    ) {
        bridgeFunction(name: name, paramType: [Any].self) { [weak webview] params, callback in
            guard params.count == 2, let callbackId = params[0] as? String, let paramToPass = params[1] as? Params else {
                callback(.failure(MultiCallbackFnError.wrongParams))
                return
            }
            callback(.success("OK"))

            func sendEvent(result: Any, done: Bool) {
                DispatchQueue.main.async {
                    guard let resultJsonData = try? JSONSerialization.data(withJSONObject: result, options: [.fragmentsAllowed]),
                          let resultJsonStr = String(data: resultJsonData, encoding: .utf8)
                    else { return }
                    let doneStr = done ? "true" : "false"
                    webview?.evaluateJavaScript("__bridge_callbacks[\(callbackId)](\(resultJsonStr), \(doneStr))")
                }
            }

            var lastResult: Any?
            func emit(result: Any) {
                lastResult = result
                sendEvent(result: result, done: false)
            }
            func done() {
                sendEvent(result: lastResult ?? NSNull(), done: true)
            }
            handler(paramToPass, emit, done)
        }
    }
}

class BridgedFunction<Params>: NSObject, WKScriptMessageHandlerWithReply {
    typealias Handler = (Params, @escaping Callback) -> Void
    typealias Callback = (Result<Any, Error>) -> Void

    private let handler: Handler
    init(handler: @escaping Handler) {
        self.handler = handler
        super.init()
    }

    // MARK: WKScriptMessageHandlerWithReply
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        if let obj = message.body as? Params {
            handler(obj) { result in
                switch result {
                case .success(let value):
                    replyHandler(value, nil)
                case .failure(let error):
                    replyHandler(nil, error.localizedDescription)
                }
            }
        } else {
            replyHandler(nil, "Invalid parameters")
        }
    }
}

extension InfiniteWebView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if !(navigationAction.targetFrame?.isMainFrame ?? false) {
            decisionHandler(.allow)
            return
        }

        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        if url.host != "localhost" {
            CrossPlatform.open(url: url)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }

    #if os(macOS)
    // WKNavigationDelegate method to handle download
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }
    #endif
}

#if os(macOS)
extension InfiniteWebView: WKDownloadDelegate {
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = suggestedFilename
        savePanel.beginSheetModal(for: self.window!) { response in
            if response == .OK {
                completionHandler(savePanel.url)
            } else {
                completionHandler(nil)
            }
        }
    }
}
#endif


extension InfiniteWebView: WKUIDelegate {
    // Implement prompt, alert, etc
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
#if os(iOS)

Task {
    let (_, _) = await UIApplication.shared.prompt(title: "App", message: message, showTextField: false, placeholder: nil)
    completionHandler()
}

#else

        let model = PromptDialogModel(title: "Alert", message: message, cancellable: false, hasTextField: false)
        Task { @MainActor in
            let result = await model.run()
            completionHandler()
        }
        #endif
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        #if os(iOS)

        Task {
            let (ok, _) = await UIApplication.shared.prompt(title: "App", message: message, showTextField: false, placeholder: nil)
            completionHandler(ok)
        }

        #else
        let model = PromptDialogModel(title: "Alert", message: message, cancellable: true, hasTextField: false)
        Task { @MainActor in
            let result = await model.run()
            completionHandler(!result.cancelled)
        }
        #endif
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
#if os(iOS)

Task {
    let (ok, text) = await UIApplication.shared.prompt(title: "App", message: prompt, showTextField: true, placeholder: nil)
    completionHandler(ok ? text : nil)
}

#else

        let model = PromptDialogModel(title: "Alert", message: prompt, cancellable: true, hasTextField: true, defaultText: defaultText ?? "")
        Task { @MainActor in
            let result = await model.run()
            completionHandler(result.cancelled ? nil : result.text)
        }
        #endif
    }

    // Implement file upload
    #if os(macOS)
    func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = parameters.allowsMultipleSelection
        //        openPanel.canChooseFiles = parameters.file
        openPanel.canChooseDirectories = parameters.allowsDirectories
        openPanel.beginSheetModal(for: self.window!) { response in
            if response == .OK {
                completionHandler(openPanel.urls)
            } else {
                completionHandler(nil)
            }
        }
    }
    #endif
}
