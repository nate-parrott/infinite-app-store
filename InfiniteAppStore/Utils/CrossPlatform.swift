import Foundation
import SwiftUI

#if os(macOS)
import AppKit
typealias UINSImage = NSImage
typealias UINSView = NSView
#else
import UIKit
typealias UINSImage = UIImage
typealias UINSView = UIView
#endif

enum CrossPlatform {
    static func open(url: URL) {
        #if os(macOS)
        NSWorkspace.shared.open(url)
        #else
        UIApplication.shared.open(url)
        #endif
    }
}

extension Image {
    init(uinsImage: UINSImage) {
        #if os(macOS)
        self = .init(nsImage: uinsImage)
        #else
        self = .init(uiImage: uinsImage)
        #endif
    }
}

// a UINSView that provides unified lifecycle points
class CrossPlatformView: UINSView {
    func layout_crossplatform() {}

    func didMoveToWindow_crossplatform() {}

    #if os(macOS)
    override func layout() {
        super.layout()
        layout_crossplatform()
    }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        didMoveToWindow_crossplatform()
    }
    #else
    override func layoutSubviews() {
        super.layoutSubviews()
        layout_crossplatform()
    }
    override func didMoveToWindow() {
        super.didMoveToWindow()
        didMoveToWindow_crossplatform()
    }
    #endif
}

func isMac() -> Bool {
    #if os(macOS)
    return true
    #else
    return false
    #endif
}
