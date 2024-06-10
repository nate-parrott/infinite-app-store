import Foundation
import ChatToys

enum DefaultsKeys: String {
    case openAIKey

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

extension OpenAICredentials {
    static func getOrPromptForCreds() async throws -> OpenAICredentials {
        enum Errors: Error {
            case noKey
        }

        if let key = DefaultsKeys.openAIKey.stringValue, !key.isEmpty {
            return OpenAICredentials(apiKey: key)
        }
        let key = await prompt(question: "Enter your OpenAI API key:")
        guard let key = key, !key.isEmpty else {
            throw Errors.noKey
        }
        DefaultsKeys.openAIKey.stringValue = key
        return .init(apiKey: key)
    }
}
