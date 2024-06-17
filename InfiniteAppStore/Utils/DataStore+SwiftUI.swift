import SwiftUI

struct WithSnapshot<S: Equatable & Codable, V: View, Snapshot: Equatable>: View {
    var store: DataStore<S>
    var snapshot: (S) -> Snapshot
    @ViewBuilder var main: (Snapshot?) -> V

    @State private var val: Snapshot? = nil


    var body: some View {
        ZStack {
            main(val)
        }
        .onReceive(store.publisher.map(snapshot).removeDuplicates(), perform: { self.val = $0 })
    }
}
