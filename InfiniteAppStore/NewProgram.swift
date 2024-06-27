import SwiftUI

struct NewProgramParams: Equatable {
    var title: String
    var subtitle: String
    var applescript = false
    var llmEnabled = true
}

func promptForNewProgramDetails() async -> NewProgramParams? {
    // Ensure creds
    do {
        _ = try await Credentials.getOrPromptForCreds()
    } catch {
        return nil
    }

    #if os(iOS)
    guard let title = await prompt(question: "Choose a name for your app:", title: "Create App (1/2)"),
          let subtitle = await prompt(question: "Describe your app briefly:", title: "Create App (2/2)")
    else {
        return nil
    }
    return NewProgramParams(title: title, subtitle: subtitle)
    #else
    return await withCheckedContinuation { continuation in
        DispatchQueue.main.async {
            let win = BorderlessSwiftUIWindow(resizable: false, dialog: true) {
                NewProgramForm { _ in () }
            }
            win.rootView.onDone = { [weak win] params in
                win?.close()
                continuation.resume(returning: params)
            }
            win.makeKeyAndOrderFront(nil)
        }
    }
    #endif
}

struct NewProgramForm: View {
    var onDone: (NewProgramParams?) -> Void

    @State private var params = NewProgramParams(title: "", subtitle: "")

    var body: some View {
        Window95(title: "New Program", onControlAction: {
            if $0 == .close {
                onDone(nil)
            }
        }) {
            HStack(alignment: .top, spacing: 16) {
                Image(uinsImage: Icons.iconWithName("themes")!)

                VStack(alignment: .leading, spacing: 16) {

                    VStack(alignment: .leading) {
                        Text("Program Name:")
                            .font(.boldBody95)

                        TextField("Name", text: $params.title)
                            .frame(width: 300)
                    }

                    VStack(alignment: .leading) {
                        Text("Other details:")
                            .font(.boldBody95)

                        TextField("Details", text: $params.subtitle)
                            .frame(width: 300)
                    }


                    VStack(alignment: .leading) {
                        Toggle(isOn: $params.applescript) {
                            Text("Can use AppleScript to control your computer")
                        }

                        Toggle(isOn: $params.llmEnabled) {
                            Text("Program can use AI language model")
                        }
                    }

                    HStack {
                        Spacer()
                        Button(action: { onDone(nil) }) {
                            Text("Cancel")
                        }
                        Button(action: { if canSubmit { onDone(params) } }) {
                            Text("Done")
                        }.disabled(!canSubmit)
                    }
                }
                .onSubmit {
                    if canSubmit { onDone(params) }
                }
            }
            .padding(16)
        }
    }

    var canSubmit: Bool {
        params.title.nilIfEmpty != nil
    }
}
