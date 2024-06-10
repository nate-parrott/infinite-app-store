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

//import SwiftUI
//import Combine
//
//private class SnapshotObserver<StoreType: Equatable & Codable, SnapshotType: Equatable>: ObservableObject {
//    @Published var latest: SnapshotType? {
//        didSet {
//            assert(Thread.isMainThread)
//        }
//    }
//
//    private var subscriptions = Set<AnyCancellable>()
//    var data: (DataStore<StoreType>, (StoreType) -> SnapshotType)? {
//        didSet {
//            subscriptions.removeAll()
//
//            if let (store, selector) = data {
//                if store.queue.isCurrent {
//                    self.latest = selector(store.model)
//                }
//                let storeObservable = store.queue.id == Queue.main.id ? store.uiObservable : store.observable
//                observer.observe(storeObservable.map(selector).ifChanged.onQueue(.main)) { [weak self] (value) in
//                    guard let self = self else { return }
//                    if self.latest != value {
//                        self.latest = value
//                    }
//                }
//            }
//        }
//    }
//}
//
//public struct WithSnapshot<StoreType, SnapshotType, Content>: View where Content: View, StoreType: Codable & Equatable, SnapshotType: Equatable {
//    @ObservedObject private var observer = SnapshotObserver<StoreType, SnapshotType>()
//    private let content: (SnapshotType) -> Content
//
//    public init(store: DataStore<StoreType>, selector: @escaping (StoreType) -> SnapshotType, @ViewBuilder content: @escaping (SnapshotType) -> Content) {
//        self.content = content
//        observer.data = (store, selector)
//    }
//
//    public var body: some View {
//        content(observer.latest!)
//    }
//}
//
///// Use this for observing stores that are not on the main queue
//public struct WithSnapshotAsync<StoreType, SnapshotType, Content>: View where Content: View, StoreType: Codable & Equatable, SnapshotType: Equatable {
//    @ObservedObject private var observer = SnapshotObserver<StoreType, SnapshotType>()
//    private let content: (SnapshotType) -> Content
//    private let defaultSnapshot: SnapshotType
//
//    public init(store: DataStore<StoreType>, defaultSnapshot: SnapshotType, selector: @escaping (StoreType) -> SnapshotType, @ViewBuilder content: @escaping (SnapshotType) -> Content) {
//        self.content = content
//        self.defaultSnapshot = defaultSnapshot
//        observer.data = (store, selector)
//    }
//
//    public var body: some View {
//        content(observer.latest ?? defaultSnapshot)
//    }
//}
