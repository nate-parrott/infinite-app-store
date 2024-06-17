import Foundation
import SwiftUI

#if os(macOS)
import AppKit
typealias UINSImage = NSImage
#else
import UIKit
typealias UINSImage = UIImage
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
