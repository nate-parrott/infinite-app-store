#if os(iOS)
import UIKit
#endif

import Foundation
import ChatToys

enum DefaultsKeys: String {
    case openAIKey
    case anthropicKey

    var stringValue: String? {
        get {
            return UserDefaults.standard.string(forKey: self.rawValue)
        }
        nonmutating set {
            UserDefaults.standard.set(newValue, forKey: self.rawValue)
        }
    }

    var boolValue: Bool {
        get {
            return UserDefaults.standard.bool(forKey: self.rawValue)
        }
        nonmutating set {
            UserDefaults.standard.set(newValue, forKey: self.rawValue)
        }
    }
}

enum Credentials {
    case anthropic(AnthropicCredentials)
    case openai(OpenAICredentials)

    var jsonLLM: any ChatLLM {
        switch self {
        case .anthropic(let anthropicCredentials):
            return Claude(credentials: anthropicCredentials, options: .init(model: .claude3_5Sonnet, responsePrefix: "```\n{"))
        case .openai(let openAICredentials):
            return ChatGPT(credentials: openAICredentials, options: .init(temp: 0.5, model: .gpt4_omni, jsonMode: true))
        }
    }

    var chatWithDevLLM: any FunctionCallingLLM {
        switch self {
        case .anthropic(let anthropicCredentials):
            return Claude(credentials: anthropicCredentials, options: .init(model: .claude3_5Sonnet))
        case .openai(let openAICredentials):
            return ChatGPT(credentials: openAICredentials, options: .init(temp: 0.5, model: .gpt4_omni))
        }
    }

    var smallLLM: any ChatLLM {
        switch self {
        case .anthropic(let anthropicCredentials):
            return Claude(credentials: anthropicCredentials, options: .init(model: .claude3Haiku))
        case .openai(let openAICredentials):
            return ChatGPT(credentials: openAICredentials, options: .init(temp: 0.5, model: .gpt35_turbo))
        }

    }
}

extension Credentials {
    static func getOrPromptForCreds() async throws -> Credentials {
        enum Errors: Error {
            case noKey
        }

        if let key = DefaultsKeys.openAIKey.stringValue, !key.isEmpty {
            return .openai(OpenAICredentials(apiKey: key))
        }
        if let key = DefaultsKeys.anthropicKey.stringValue, !key.isEmpty {
            return .anthropic(.init(apiKey: key))
        }
        #if os(macOS)
        await showSettingsView()
        throw Errors.noKey
        #else
        let (_, key) = await UIApplication.shared.prompt(title: "No API Key", message: "Add an API key:", showTextField: true, placeholder: "sk-??????")
        guard let key = key, !key.isEmpty else {
            throw Errors.noKey
        }
        DefaultsKeys.openAIKey.stringValue = key
        return .openai(.init(apiKey: key))
        #endif
    }
}
