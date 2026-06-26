// Unix-domain socket server: line-delimited JSON.
//
// - Every connected client receives broadcast event lines (push to Hammerspoon
//   via hs.socket).
// - A client may send a command line: {"cmd":"get"} -> current presence line,
//   {"cmd":"focus"} -> focus the current meeting; reply {"ok":true}.
import Foundation

final class SocketServer {
    private let path: String
    private var listenFD: Int32 = -1
    private var acceptSource: DispatchSourceRead?
    private let q = DispatchQueue(label: "media-presenced.socket")
    private var clients: [Int32: DispatchSourceRead] = [:]
    private var buffers: [Int32: Data] = [:]

    var onCommand: ((_ cmd: String, _ reply: @escaping (String) -> Void) -> Void)?

    init(path: String) { self.path = path }

    func start() throws {
        let dir = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        unlink(path)

        listenFD = socket(AF_UNIX, SOCK_STREAM, 0)
        guard listenFD >= 0 else { throw POSIXError(.init(rawValue: errno) ?? .EIO) }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let cap = MemoryLayout.size(ofValue: addr.sun_path)
        let bytes = Array(path.utf8)
        guard bytes.count < cap else { throw POSIXError(.ENAMETOOLONG) }
        withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: cap) { dst in
                for i in 0..<bytes.count { dst[i] = CChar(bitPattern: bytes[i]) }
                dst[bytes.count] = 0
            }
        }
        let len = socklen_t(MemoryLayout<sockaddr_un>.size)
        let bound = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(listenFD, $0, len) }
        }
        guard bound == 0 else { throw POSIXError(.init(rawValue: errno) ?? .EIO) }
        guard listen(listenFD, 16) == 0 else { throw POSIXError(.init(rawValue: errno) ?? .EIO) }

        let src = DispatchSource.makeReadSource(fileDescriptor: listenFD, queue: q)
        src.setEventHandler { [weak self] in self?.accept() }
        src.resume()
        acceptSource = src
    }

    private func accept() {
        let fd = Foundation.accept(listenFD, nil, nil)
        guard fd >= 0 else { return }
        let src = DispatchSource.makeReadSource(fileDescriptor: fd, queue: q)
        src.setEventHandler { [weak self] in self?.read(fd) }
        src.setCancelHandler { close(fd) }
        clients[fd] = src
        buffers[fd] = Data()
        src.resume()
    }

    private func read(_ fd: Int32) {
        var tmp = [UInt8](repeating: 0, count: 4096)
        let n = Foundation.read(fd, &tmp, tmp.count)
        if n <= 0 { drop(fd); return }
        buffers[fd, default: Data()].append(contentsOf: tmp[0..<n])
        while let idx = buffers[fd]?.firstIndex(of: 0x0A) {
            let line = buffers[fd]!.subdata(in: buffers[fd]!.startIndex..<idx)
            buffers[fd]!.removeSubrange(buffers[fd]!.startIndex...idx)
            if let cmd = String(data: line, encoding: .utf8)?.trimmingCharacters(in: .whitespaces), !cmd.isEmpty {
                onCommand?(cmd) { [weak self] reply in self?.q.async { self?.write(fd, reply) } }
            }
        }
    }

    private func write(_ fd: Int32, _ s: String) {
        var data = Array(s.utf8)
        if data.last != 0x0A { data.append(0x0A) }
        _ = data.withUnsafeBytes { Foundation.write(fd, $0.baseAddress, data.count) }
    }

    private func drop(_ fd: Int32) {
        clients[fd]?.cancel()
        clients.removeValue(forKey: fd)
        buffers.removeValue(forKey: fd)
    }

    func broadcast(_ line: String) {
        q.async { [weak self] in
            guard let self else { return }
            for fd in self.clients.keys { self.write(fd, line) }
        }
    }
}
