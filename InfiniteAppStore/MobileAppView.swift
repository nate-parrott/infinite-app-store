import SwiftUI

struct MobileAppView: View {
    var id: String

    @State private var program: Program?
    @State private var errors = [String]()
    @State private var showingContactDevView: Bool = false
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        Window95(title: program?.title.nilIfEmpty ?? "App", onControlAction: handleControlAction, additionalAccessoryIcon: AnyView(contactDevButton)) {
            AppViewRepresentable(id: id, onError: { errors.append($0) })
            .overlay(alignment: .bottomTrailing) {
                if errors.count > 0 {
                    ErrorView(errors: errors, id: id, onDismiss: { self.errors.removeAll() })
                        .padding()
                }
            }
            .overlay {
                if let program, let progress = program.installProgress {
                    InstallShield(name: program.title, progress: progress)
                        .onDisappear {
                            self.errors.removeAll()
                        }
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onReceive(AppStore.shared.publisher.map { $0.programs[id] }, perform: { self.program = $0 })
        .sheet(isPresented: $showingContactDevView) {
            ContactDevView(programId: id)
        }
    }

    func handleControlAction(_ action: WindowControlAction) {
        if action == .close {
            presentationMode.wrappedValue.dismiss()
        }
    }

    @ViewBuilder var contactDevButton: some View {
        Button(action: { contactDev() }) {
            Text("?").bold()
                .foregroundStyle(Color.black)
        }
        .help("Contact Developer")
    }

    private func contactDev() {
        #if os(macOS)
        contactDevForProgram(id: id)
        #else
        showingContactDevView = true
        #endif
    }
}
