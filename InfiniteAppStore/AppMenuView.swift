import SwiftUI

struct AppMenuView: View {
    var body: some View {
        WithSnapshot(store: AppStore.shared, snapshot: { $0.programs.values.sorted(by: { $0.title < $1.title }) }) { programs in
            _AppMenuView(programs: programs ?? [])
        }
    }
}

struct _AppMenuView: View {
    var programs: [Program]

    @State private var hovered: Program.ID? = nil

    var body: some View {
        VStack(spacing: 0) {
            StatusMenuItem(idForHover: "new", hoveredId: $hovered, onTap: newProgram) {
                RetroIconView(name: "installer")
                Text("New App...")
            }

            if programs.count > 0 {
                HorizontalDivider95()
            }
            ForEach(programs) {
                cell(program: $0)
            }
        }
        .padding(1)
        .onHover {
            if !$0 { self.hovered = nil }
        }
        .background(Color.gray95)
        .with95DepthEffect(pushed: false)
        .frame(width: 250)
        .modifier(Demo95OuterStyles())
    }

    private func newProgram() {
        Task {
            guard let title = await prompt(question: "Choose a name for your app:", title: "Create App (1/2)"),
                  let subtitle = await prompt(question: "Describe your app briefly:", title: "Create App (2/2)")
            else {
                return
            }
            let id = UUID().uuidString
            open(programId: id)
            try await AppStore.shared.generateProgram(id: id, title: title, subtitle: subtitle)
        }
    }

    private func open(programId: String) {
        DispatchQueue.main.async {
            NSApp.openOrFocusProgram(id: programId)
        }
    }

    @ViewBuilder func cell(program: Program) -> some View {
        StatusMenuItem(idForHover: "program:\(program.id)", hoveredId: $hovered, onTap: {
            open(programId: program.id)
        }, label: {
            RetroIconView(name: program.iconName)

            Text(program.title)
        })
    }
}

struct StatusMenuItem<L: View>: View {
    var idForHover: String
    @Binding var hoveredId: String?
    var onTap: () -> Void
    @ViewBuilder var label: () -> L

    var body: some View {
        let hovered = idForHover == hoveredId

        HStack {
            label()
        }
        .padding(.horizontal, 6)
        .frame(height: 34)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(hovered ? Color.white : Color.black)
        .background {
            if hovered {
                Color.blue95
            }
        }
        .contentShape(.rect)
        .onHover {
            if $0 { self.hoveredId = idForHover }
        }
        .onTapGesture(perform: onTap)
    }
}

struct RetroIconView: View {
    var name: String

    var body: some View {
        Image(uinsImage: Icons.iconWithName(name) ?? Icons.iconWithName("executable")!)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 20, height: 20)
    }
}

#Preview {
    _AppMenuView(programs: Program.stubsForMenu())
        .frame(width: 300)
}
