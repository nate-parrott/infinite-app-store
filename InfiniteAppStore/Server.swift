import Foundation
import Swifter

class Server {
    static let shared = Server()

//    let queue = DispatchQueue(label: "Server", qos: .default)

    let server = HttpServer()

    init() {
//        queue.async {
            self.start()
//        }
    }

    func start() {
        server["/static/:path"] = shareFilesFromDirectory(Bundle.main.url(forResource: "StaticWebFiles", withExtension: nil)!.path)
        server["/icons/:path"] = shareFilesFromDirectory(Bundle.main.url(forResource: "StaticWebFiles", withExtension: nil)!.appendingPathComponent("Icons").path)

//        server["/"] = { request in
//            return HttpResponse.ok(.text("<h1>heeeyyy</h1>"))
//        }
//        server["/siteName"] = { request in
//            let title: String? = blockingAsync {
//                try? await siteTitle(url: URL(string: "https://nytimes.com")!)
//            } ?? nil
//            return HttpResponse.ok(.text("\(title ?? "none")"))
//        }
//        server["/batch_summary"] = { request in
//            do {
//                let urls = request.requestedURLsForSummary
//                let summaries = blockingAsync {
//                    await siteSummaries(urls: urls.map(\.absoluteString))
//                }
//                let json = try JSONSerialization.jsonObject(with: try! JSONEncoder().encode([summaries]))
//                return HttpResponse.ok(.json(json))
//            } catch {
//                print("Error: \(error)")
//                return .internalServerError
//            }
//        }
        let port: in_port_t = 50082
        print("📦 Will start server on port \(port)")
        try! server.start(port, forceIPv4: true)
    }
}

//extension Server {
//    static let cache = NSCache<NSURL, NSData>()
//
//    func serveLocalResource(path: String, resourceURL: URL, mimeType) {
//        self[path] = { request in
//            if let cached = Self.cache.object(forKey: resourceURL as NSURL) {
//                return HttpResponse.ok(.data(cached as Data, contentType: mimeType))
//            }
//        }
//    }
//}

private extension HttpRequest {
    func params(name: String) -> String? {
        for param in queryParams {
            if param.0 == name {
                return param.1.removingPercentEncoding
            }
        }
        return nil
    }
}

private class Box<T> {
    init() {}
    var t: T?
}

private func blockingAsync<T>(block: @escaping () async -> T) -> T {
    // Block until this async block is done
    let result = Box<T>()
    let g = DispatchGroup()
    g.enter()
    Task {
        result.t = await block()
        g.leave()
    }
    g.wait()
    return result.t!
}

