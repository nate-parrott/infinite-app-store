import AppKit
import SwiftUI

extension Color {
    static let gray95 = Color(hex: 0xBFBFBF)
    static let blue95 = Color(hex: 0x01027C)
    static let lightBlue95 = Color(hex: 0x1186D3)
}

#if os(macOS)

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

    static var body95: Font = Font.custom(Self.font95Name, size: 15)
    static var boldBody95: Font = Font.custom(Self.boldFont95Name, size: 15)
}

#endif

struct Demo95OuterStyles: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body95)
            .background(Color.gray95)
            .colorScheme(.light)
            .buttonStyle(ButtonStyle95())
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
                        .stroke(bottomRightColor, lineWidth: offset)
                        .offset(x: -offset, y: -offset)

                    Rectangle()
                        .stroke(topLeftColor, lineWidth: offset)
                        .offset(x: offset, y: offset)
                }
            }
            .clipShape(.rect)
    }
}

struct Window95<V: View>: View {
    var title: String
    var onControlAction: (WindowControlAction) -> Void
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
        .modifier(Demo95OuterStyles())
    }

    @ViewBuilder var titleBar: some View {
        HStack {
            Text(title)
                .withBoldFont95()
                .foregroundStyle(.white)
                .padding(.leading, 5)

            Spacer()
            HStack(spacing: 0) {
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
            .buttonStyle(ButtonStyle95(height: 26, width: 28, outerBorder: false))
            .padding(.trailing, -1)
        }
        .padding(4)
        .background {
            LinearGradient(colors: [Color.blue95, Color.lightBlue95], startPoint: .leading, endPoint: .trailing)
        }
    }
}

struct ButtonStyle95: ButtonStyle {
    var height: CGFloat = 30
    var width: CGFloat? = nil
    var outerBorder: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        let offset: CGFloat = configuration.isPressed ? 1.5 : 0
        configuration
            .label
            .offset(x: offset, y: offset)
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
        Window95(title: "Hello World", onControlAction: {_ in ()}) {
            Button(action: {}) {
                Text("Hi there!")
                    .withFont95()
            }
            .padding()
        }
        .padding()
        .frame(width: 400)
        .background(Color.green)
    }
}

#Preview {
    Demo95()
}
