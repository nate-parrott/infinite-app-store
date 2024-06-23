import SwiftUI

extension Color {
    static let gray95 = Color(hex: 0xBFBFBF)
    static let blue95 = Color(hex: 0x01027C)
    static let lightBlue95 = Color(hex: 0x1186D3)
}

#if os(macOS)
import AppKit

extension Font {
    static var font95Name: String = {
        let fontURL = Bundle.main.url(forResource: "MS Sans Serif", withExtension: "ttf")!
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        return "MS Sans Serif"
    }()

    static var boldFont95Name: String = {
        let fontURL = Bundle.main.url(forResource: "MS Sans Serif Bold", withExtension: "ttf")!
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        return "MS Sans Serif Bold"
    }()
}
#else
extension Font {
    static var font95Name: String = "MS Sans Serif"
    static var boldFont95Name: String = "MS Sans Serif Bold"
}
#endif

extension Font {
    static var body95: Font = Font.custom(Self.font95Name, size: 15)
    static var boldBody95: Font = Font.custom(Self.boldFont95Name, size: 15)
}

struct Styling95: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body95)
            .background(Color.gray95)
            .colorScheme(.light)
            .buttonStyle(ButtonStyle95())
            .toggleStyle(ToggleStyle95())
            .textFieldStyle(TextFieldStyle95())
    }
}

struct ToggleStyle95: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            ZStack {
                if configuration.isOn {
                    Image("check")
                        .scaleEffect(1.3)
                } else if configuration.isMixed {
                    Text("-")
                }
            }
            .frame(both: 17)
            .background(.white)
            .depthBorder(topLeftColor: Color.black, bottomRightColor: Color(hex: 0xC0C0C0), offset: 1.5)
            .depthBorder(topLeftColor: Color(hex: 0x808080), bottomRightColor: Color.white, offset: 1.5)

            configuration.label
                .font(.body95)
        }
        .onTapGesture {
            configuration.isOn = !configuration.isOn
        }
    }
}

struct HorizontalDivider95: View {
    var body: some View {
        VStack(spacing: 0) {
            Color(hex: 0x8F8F8F)
                .frame(height: 1)
            Color.white
                .frame(height: 1)
        }
        .accessibilityRepresentation { Divider() }
    }
}

extension View {
    func withFont95() -> some View {
        self
            .font(.body95)
//            .kerning(1)
    }

    func withBoldFont95() -> some View {
        self
            .font(.boldBody95)
//            .kerning(1)
    }

    func with95DepthEffect(pushed: Bool, outerBorder: Bool = true) -> some View {
        self
            .overlay {
                ZStack {
                    if pushed {
                        Rectangle().strokeBorder(Color.black.opacity(0.33), lineWidth: 1.5)
                    } else {
                        Rectangle().strokeBorder(Color.white.opacity(0.1), lineWidth: 1.5)
                            .padding(-1.5)
                            .offset(x: 3, y: 3)

                        Rectangle().strokeBorder(Color.white, lineWidth: 1.5)
                            .padding(-1.5)
                            .offset(x: 1.5, y: 1.5)

                        Rectangle().strokeBorder(Color.black.opacity(0.2), lineWidth: 1.5)
                            .padding(-1.5)
                            .offset(x: -3, y: -3)

                        Rectangle().strokeBorder(Color.black, lineWidth: 1.5)
                            .padding(-1.5)
                            .offset(x: -1.5, y: -1.5)
                    }
                }
            }
            .background(Color.gray95)
            .clipShape(.rect)
            .padding(outerBorder ? 1 : 0)
            .background(.black)
            .clipShape(.rect)
    }

    fileprivate func depthBorder(topLeftColor: Color, bottomRightColor: Color, offset: CGFloat) -> some View {
        self
            .clipShape(.rect)
            .padding(offset)
            .overlay {
                ZStack {
                    Rectangle()
                        .strokeBorder(bottomRightColor, lineWidth: offset)
                        .offset(x: -offset, y: -offset)
                        .padding(-offset)

                    Rectangle()
                        .strokeBorder(topLeftColor, lineWidth: offset)
                        .offset(x: offset, y: offset)
                        .padding(-offset)
                }
            }
            .clipShape(.rect)
    }

    func recessed95Effect() -> some View {
        depthBorder(topLeftColor: Color.black.opacity(0.5), bottomRightColor: Color.white, offset: 1.5)
    }
}

struct ProgressBar95: View {
    var progress: Double

    var body: some View {
        let spacing: CGFloat = 3

        PerFrameAnimationView(t: progress, content: { progress in
            let boxWidth: CGFloat = 16
            GeometryReader { geo in
                let totalBoxes = Int(floor(geo.size.width / Double(boxWidth)))
                let actualBoxWidth: CGFloat = geo.size.width / Double(totalBoxes)
                let boxesFilled = Int(floor(Double(totalBoxes) * progress))
                HStack(spacing: 0) {
                    ForEach(Array(0..<boxesFilled), id: \.self) { _ in
                        Color.blue95
                            .padding(spacing / 2)
                            .frame(width: actualBoxWidth)
                    }
                }
            }
        })
        .padding(spacing / 2)
        .frame(height: 26)
        .recessed95Effect()
    }
}

struct InstallShield: View {
    var name: String
    var progress: Double

    var body: some View {
        LinearGradient(colors: [Color(hex: 0x0201F5), Color.black], startPoint: .top, endPoint: .bottom)
            .overlay(alignment: .topLeading) {
                Text(name)
                    .font(.custom("TimesNewRomanPS-BoldItalicMT", size: 36))
                    .foregroundStyle(Color.white)
                    .shadow(color: Color.black, radius: 0, x: 5, y: 5)
                    .padding()
            }
            .overlay(alignment: .bottomTrailing) {
                VStack(alignment: .leading, spacing: 14, content: {
                    Text("Installing Program...")
                    ProgressBar95(progress: progress)
                        .animation(.linear(duration: 0.3), value: progress)
                        .frame(width: 200)
                })
                .padding()
                .background(Color.gray95)
                .with95DepthEffect(pushed: false, outerBorder: false)
                .padding()
            }
    }
}

struct Window95<V: View>: View {
    var title: String
    var onControlAction: (WindowControlAction) -> Void
    var additionalAccessoryIcon: AnyView? = nil
    @ViewBuilder var content: () -> V

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleBar
            content()
        }
        .padding(1.5)
        .background(Color.gray95)
        .depthBorder(topLeftColor: Color.white, bottomRightColor: Color(white: 0.5), offset: 1.5)
        .depthBorder(topLeftColor: Color(hex: 0xDBDBDB), bottomRightColor: Color.black, offset: 1.5)
        .modifier(Styling95())
    }

    @ViewBuilder var titleBar: some View {
        HStack {
            Text(title)
                .withBoldFont95()
                .foregroundStyle(.white)
                .padding(.leading, 5)
                .lineLimit(1)

            Spacer()
            HStack(spacing: 0) {
                if let additionalAccessoryIcon {
                    additionalAccessoryIcon
                    Spacer().frame(width: 2)
                }

                Button(action: { onControlAction(.minimize) }) {
                    Image("minimize")
                }
                Button(action: { onControlAction(.maximize) }) {
                    Image("maximize")
                }
                Spacer().frame(width: 2)
                Button(action: { onControlAction(.close) }) {
                    Image("close")
                }
            }
            .buttonStyle(ButtonStyle95(height: isMac() ? 26 : 44, width: isMac() ? 28 : 44, outerBorder: false))
            .padding(.trailing, -1)
        }
        .padding(4)
        .background {
            LinearGradient(colors: [Color.blue95, Color.lightBlue95], startPoint: .leading, endPoint: .trailing)
        }
    }
}

struct TextFieldStyle95: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textFieldStyle(.plain)
            .padding(.horizontal, 8)
            .frame(minHeight: 30)
            .background(Color.white)
            .recessed95Effect()
    }
}

//TextField("Message...", text: $message)
//    .onSubmit {
//        submit()
//    }
//    .textFieldStyle(.plain)
//    .padding(.horizontal, 8)
//    .frame(height: 30)
//    .background(Color.white)
//    .recessed95Effect()

struct ButtonStyle95: ButtonStyle {
    var height: CGFloat = 30
    var width: CGFloat? = nil
    var outerBorder: Bool = true

    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        let offset: CGFloat = configuration.isPressed ? 1.5 : 0
        configuration
            .label
            .foregroundStyle(enabled ? Color.black : Color.white)
            .offset(x: offset, y: offset)
            .overlay {
                if !enabled {
                    configuration.label
                        .foregroundStyle(Color(hex: 0x808080))
                        .offset(x: -1.5, y: -1.5)
                }
            }
            .withFont95()
            .frame(height: height)
            .padding(.horizontal, width != nil ? 0 : 12)
            .frame(width: width)
            .with95DepthEffect(pushed: configuration.isPressed, outerBorder: outerBorder)
            .background(Color.gray95)
    }
}

struct Demo95: View {
    var body: some View {
        Window95(title: "Installing", onControlAction: {_ in ()}) {
//            InstallShield(name: "Rude Calculator", progress: 0.7)
//                .frame(height: 400)
            VStack(alignment: .leading, spacing: 14) {
                Button(action: {}) {
                    Text("Hi there!")
                        .withFont95()
                }

                Toggle(isOn: .constant(true)) {
                    Text("Enable Discombobulation")
                }
            }
            .padding()

            ProgressBar95(progress: 0.5)
//            ProgressBar95(progress: 1)
        }
        .padding(60)
        .frame(width: 500)
        .background(Color(hex: 0x53A8A8))
    }
}

#Preview {
    Demo95()
}
