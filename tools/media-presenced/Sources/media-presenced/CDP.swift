// CDP layer: event-driven Google Meet detection via Chrome DevTools Protocol.
//
// Connects to a Chromium browser's browser-level websocket (Helium on 9223),
// discovers meet.google.com page targets, and classifies each via a debounced
// Runtime.evaluate of the Meet DOM (lobby vs joined, in-app mic/cam, presenting,
// participants). No screen-recording APIs, no window-title reads, no osascript —
// so it never trips TCC prompts.
//
// Concurrency: all `known` access is confined to `q`. `pending`/`nextID` are
// guarded by `lock` so send() is safe to call from any thread (including `q`).
//
// Pure Foundation (URLSession + URLSessionWebSocketTask), zero dependencies.
import Foundation

struct MeetDOM: Equatable, Codable {
    var state: String = "unknown"      // lobby | joined | unknown
    var presenting: Bool = false
    var micSelf: String = "?"          // on | muted | ?
    var camSelf: String = "?"          // on | off | ?
    var participants: [String] = []
}

struct MeetState: Equatable {
    var present: Bool = false
    var targetId: String = ""
    var url: String = ""
    var title: String = ""
    var dom: MeetDOM = MeetDOM()
}

private struct TargetEntry {
    var sig: String
    var dom: MeetDOM
    var timer: DispatchSourceTimer?
}

final class CDPClient: NSObject, URLSessionWebSocketDelegate {
    let host: String
    let port: Int
    var onMeet: ((_ event: String, _ state: MeetState) -> Void)?

    private var session: URLSession!
    private var ws: URLSessionWebSocketTask?

    private let lock = NSLock()
    private var nextID = 0
    private var pending: [Int: (Any?) -> Void] = [:]

    private let q = DispatchQueue(label: "media-presenced.cdp")  // owns `known`
    private var known: [String: TargetEntry] = [:]
    private var reconnectWork: DispatchWorkItem?

    private static let classifyExpr = """
    (()=>{
      const txt=(document.body&&document.body.innerText)||'';
      const leave=document.querySelector('button[aria-label*="Leave call" i]');
      const join=/\\bJoin now\\b/i.test(txt)||/\\bAsk to join\\b/i.test(txt);
      const aria=s=>[...document.querySelectorAll(s)].map(e=>e.getAttribute('aria-label')).filter(Boolean);
      const mic=aria('button[aria-label*="microphone" i]');
      const cam=aria('button[aria-label*="camera" i]');
      const btns=aria('button');
      const presenting=/You're presenting|You are presenting|Stop presenting|Stop sharing/i.test(txt)
        || btns.some(l=>/stop presenting|stop sharing/i.test(l));
      const names=mic.filter(l=>/^Mute /.test(l)).map(l=>l.replace(/^Mute /,'').replace(/'s microphone$/,''));
      return {
        state: leave?'joined':(join?'lobby':'unknown'),
        presenting,
        micSelf: mic.some(l=>/turn on microphone/i.test(l))?'muted':(mic.some(l=>/turn off microphone/i.test(l))?'on':'?'),
        camSelf: cam.some(l=>/turn on camera/i.test(l))?'off':(cam.some(l=>/turn off camera/i.test(l))?'on':'?'),
        participants: names
      };
    })()
    """

    init(host: String = "127.0.0.1", port: Int = 9223) {
        self.host = host
        self.port = port
        super.init()
        self.session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: nil)
    }

    func start() { connect() }

    func activateTarget(_ targetId: String) {
        send("Target.activateTarget", ["targetId": targetId])
    }

    // MARK: connection

    private func scheduleReconnect() {
        reconnectWork?.cancel()
        let w = DispatchWorkItem { [weak self] in self?.connect() }
        reconnectWork = w
        q.asyncAfter(deadline: .now() + 3, execute: w)
    }

    private func connect() {
        guard let verURL = URL(string: "http://\(host):\(port)/json/version") else { return }
        var req = URLRequest(url: verURL); req.timeoutInterval = 3
        session.dataTask(with: req) { [weak self] data, _, _ in
            guard let self else { return }
            guard let data,
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let wsURLStr = obj["webSocketDebuggerUrl"] as? String,
                  let wsURL = URL(string: wsURLStr) else {
                self.scheduleReconnect(); return
            }
            let task = self.session.webSocketTask(with: wsURL)
            self.ws = task
            task.resume()
            self.receiveLoop()
            self.send("Target.setDiscoverTargets", ["discover": true])
        }.resume()
    }

    // MARK: send/receive

    @discardableResult
    private func send(_ method: String, _ params: [String: Any] = [:], sessionId: String? = nil,
                      completion: ((Any?) -> Void)? = nil) -> Int {
        lock.lock(); nextID += 1; let id = nextID
        if let c = completion { pending[id] = c }
        lock.unlock()
        var msg: [String: Any] = ["id": id, "method": method, "params": params]
        if let sessionId { msg["sessionId"] = sessionId }
        guard let data = try? JSONSerialization.data(withJSONObject: msg),
              let str = String(data: data, encoding: .utf8) else { return id }
        ws?.send(.string(str)) { _ in }
        return id
    }

    private func receiveLoop() {
        ws?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure:
                self.scheduleReconnect()
            case .success(let message):
                if case let .string(text) = message, let data = text.data(using: .utf8),
                   let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    self.handle(obj)
                }
                self.receiveLoop()
            }
        }
    }

    private func handle(_ obj: [String: Any]) {
        if let id = obj["id"] as? Int {
            lock.lock(); let cb = pending.removeValue(forKey: id); lock.unlock()
            cb?(obj["result"])
            return
        }
        guard let method = obj["method"] as? String else { return }
        let p = obj["params"] as? [String: Any] ?? [:]
        switch method {
        case "Target.targetCreated", "Target.targetInfoChanged":
            guard let info = p["targetInfo"] as? [String: Any],
                  (info["type"] as? String) == "page" else { return }
            let url = (info["url"] as? String) ?? ""
            let tid = (info["targetId"] as? String) ?? ""
            let title = (info["title"] as? String) ?? ""
            let created = method == "Target.targetCreated"
            let isMeet = url.contains("meet.google.com")
            q.async { [weak self] in self?.onTargetQ(tid: tid, url: url, title: title, isMeet: isMeet, created: created) }
        case "Target.targetDestroyed":
            if let tid = p["targetId"] as? String {
                q.async { [weak self] in self?.emitLeftQ(tid, reason: "tab_closed") }
            }
        default:
            break
        }
    }

    // MARK: meet target lifecycle (all on q)

    private func onTargetQ(tid: String, url: String, title: String, isMeet: Bool, created: Bool) {
        if !isMeet {
            if known[tid] != nil { emitLeftQ(tid, reason: "navigated_away") }
            return
        }
        let sig = url.split(separator: "?").first.map(String.init) ?? url
        let isNew = known[tid] == nil
        if created || isNew {
            var st = MeetState(); st.present = true; st.targetId = tid; st.url = sig; st.title = title
            emitMain("meet.appeared", st)
        }
        if known[tid] == nil { known[tid] = TargetEntry(sig: sig, dom: MeetDOM(), timer: nil) }
        known[tid]?.timer?.cancel()
        known[tid]?.sig = sig
        let t = DispatchSource.makeTimerSource(queue: q)
        t.schedule(deadline: .now() + 1.2)
        t.setEventHandler { [weak self] in self?.classify(tid: tid, url: sig, title: title) }
        known[tid]?.timer = t
        t.resume()
    }

    // called on q (timer). send() is lock-guarded so safe here.
    private func classify(tid: String, url: String, title: String) {
        send("Target.attachToTarget", ["targetId": tid, "flatten": true]) { [weak self] result in
            guard let self, let r = result as? [String: Any],
                  let sessionId = r["sessionId"] as? String else { return }
            self.send("Runtime.enable", [:], sessionId: sessionId)
            self.send("Runtime.evaluate", ["expression": CDPClient.classifyExpr, "returnByValue": true],
                      sessionId: sessionId) { [weak self] evalResult in
                guard let self else { return }
                self.send("Target.detachFromTarget", ["sessionId": sessionId], sessionId: sessionId)
                guard let er = evalResult as? [String: Any],
                      let res = er["result"] as? [String: Any],
                      let value = res["value"] as? [String: Any] else { return }
                var dom = MeetDOM()
                dom.state = value["state"] as? String ?? "unknown"
                dom.presenting = value["presenting"] as? Bool ?? false
                dom.micSelf = value["micSelf"] as? String ?? "?"
                dom.camSelf = value["camSelf"] as? String ?? "?"
                dom.participants = value["participants"] as? [String] ?? []
                self.q.async { [weak self] in
                    guard let self, let prev = self.known[tid]?.dom else { return }
                    if prev != dom {
                        self.known[tid]?.dom = dom
                        var st = MeetState(); st.present = true; st.targetId = tid
                        st.url = url; st.title = title; st.dom = dom
                        self.emitMain("meet.state", st)
                    }
                }
            }
        }
    }

    private func emitLeftQ(_ tid: String, reason: String) {
        guard known[tid] != nil else { return }
        known[tid]?.timer?.cancel()
        known.removeValue(forKey: tid)
        var st = MeetState(); st.present = false; st.targetId = tid
        emitMain("meet.left", st)
    }

    private func emitMain(_ event: String, _ st: MeetState) {
        DispatchQueue.main.async { [weak self] in self?.onMeet?(event, st) }
    }

    // URLSessionWebSocketDelegate
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        scheduleReconnect()
    }
}
