import Foundation
import Testing
@testable import UltimateMenu

// The shape `rtm needs --json` prints (rtm/src/needs.rs).
private let json = """
{"host":"workbookpro","total":3,"hubs":[
 {"host":"workbookpro","project":".dotfiles","url":"http://127.0.0.1:4749","count":2,"inbox":[
  {"key":"message:5","kind":"question","title":"Pick a name","detail":"Which name?","at":50},
  {"key":"inbox-items:1","kind":"action","title":"Check toasts","detail":null,"at":200}]},
 {"host":"workbookpro","project":"swifties","url":"http://127.0.0.1:4747","count":0,"inbox":[]},
 {"host":"megabookpro","project":".dotfiles","url":"https://megabookpro.ts.net:4749","count":1,"inbox":[
  {"key":"message:9","kind":"question","title":"Ship it?","detail":null,"at":10}]},
 {"host":"megabookpro","project":"x","url":"https://megabookpro.ts.net:4750","count":null,
  "error":"timeout: global","inbox":[]}]}
"""

@Test func decodesRtmNeedsAndGroupsByHostInOrder() throws {
    let needs = try Needs.decode(Data(json.utf8))
    #expect(needs.total == 3)
    #expect(needs.groups.map(\.host) == ["workbookpro", "megabookpro"])
    #expect(needs.groups[0].hubs.map(\.project) == [".dotfiles", "swifties"])
    #expect(needs.hubs[0].inbox[0].detail == "Which name?")
}

@Test func anUnreachableHubIsNeverZero() throws {
    let needs = try Needs.decode(Data(json.utf8))
    let hub = needs.hubs[3]
    #expect(hub.count == nil)
    #expect(hub.label == "x  unreachable")
    #expect(needs.unreachable == 1)
    #expect(needs.title == "3?", "the total stays, and ? says a hub is missing from it")
}

@Test func titleIsTheCountOrNothing() {
    let clear = Needs(host: "h", total: 0, hubs: [])
    #expect(clear.title == "")
    let some = Needs(host: "h", total: 21, hubs: [])
    #expect(some.title == "21")
}

@Test func linksOpenTheItemOrTheOldestInTheHubsInbox() throws {
    let needs = try Needs.decode(Data(json.utf8))
    #expect(needs.hubs[0].link()?.absoluteString == "http://127.0.0.1:4749/?inbox=message:5")
    #expect(needs.hubs[0].link("inbox-items:1")?.absoluteString == "http://127.0.0.1:4749/?inbox=inbox-items:1")
    #expect(needs.hubs[2].link()?.absoluteString == "https://megabookpro.ts.net:4749/?inbox=message:9")
    #expect(needs.hubs[0].label == ".dotfiles  2")
}
