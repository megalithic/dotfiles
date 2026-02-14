#!/usr/bin/env swift

// Create a macOS Finder alias file ("bookmark" format).
// Unlike symlinks, Finder aliases are indexed by Spotlight and work with Launchpad.
//
// Usage: create-macos-alias /path/to/Source.app /path/to/Alias.app
//
// Based on mhanberg's implementation:
// https://github.com/mhanberg/.dotfiles/blob/main/nix/darwin/link-apps/create-macos-alias.swift

import Foundation

if CommandLine.argc < 3 {
    print("Usage: create-macos-alias <source> <destination>")
    exit(1)
}

let src = CommandLine.arguments[1]
let dest = CommandLine.arguments[2]

let url = URL(fileURLWithPath: src)
let aliasUrl = URL(fileURLWithPath: dest)

do {
    let data = try url.bookmarkData(options: .suitableForBookmarkFile, includingResourceValuesForKeys: nil, relativeTo: nil)
    try URL.writeBookmarkData(data, to: aliasUrl)
} catch {
    print("Error creating alias: \(error)")
    exit(1)
}
