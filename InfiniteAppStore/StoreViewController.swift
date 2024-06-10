import SwiftUI
import AppKit

class StoreViewController: AppViewController {
//    let vc = NSHostingController(rootView: StoreView())
//
    override func viewDidLoad() {
        super.viewDidLoad()
        self.id = "Store"
    }
//
//    override func viewDidLayout() {
//        super.viewDidLoad()
//        vc.view.frame = view.bounds
//    }
}

struct StoreView: View {
    var body: some View {
        Color.gray.overlay {
            Text("Hello")
        }
    }
}
