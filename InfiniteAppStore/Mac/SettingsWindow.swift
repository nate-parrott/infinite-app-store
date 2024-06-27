import SwiftUI

@MainActor
func showSettingsView() {
    if let existing = NSApp.windows.first(where: { $0 as? BorderlessSwiftUIWindow<SettingsView> != nil }) {
        existing.makeKeyAndOrderFront(nil)
        return
    }

    let win = BorderlessSwiftUIWindow {
        SettingsView(onClose: nil)
    }
    win.rootView.onClose = { [weak win] in
        win?.close()
    }
    win.makeKeyAndOrderFront(nil)
}

struct SettingsView: View {
    var onClose: (() -> Void)?

    @AppStorage(DefaultsKeys.anthropicKey.rawValue) private var anthropicKey = ""
    @AppStorage(DefaultsKeys.openAIKey.rawValue) private var openAIKey = ""

    var body: some View {
        Window95(title: "Control Panel", onControlAction: {
            if $0 == .close {
                onClose?()
            }
        }) {
            HStack(alignment: .top, spacing: 16) {
                Image(uinsImage: Icons.iconWithName("channels")!)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Add an OpenAI or Anthropic API key to generate new programs. We'll use GPT 4o or Claude 3.5 Sonnet.")
                        .font(.boldBody95)

                    VStack(alignment: .leading) {
                        Text("OpenAI Key (recommended):")

                        TextField("Name", text: $openAIKey)
                            .frame(width: 250)
                    }

                    VStack(alignment: .leading) {
                        Text("Anthropic Key:")

                        TextField("Name", text: $anthropicKey)
                            .frame(width: 250)
                    }

                    Text("After entering a key, try creating a program again.")
                        .bold().foregroundStyle(.red)

                    Button(action: { onClose?() }) {
                        Text("Done")
                    }
                }
            }
            .padding()
            .frame(width: 450)
        }
    }
}
