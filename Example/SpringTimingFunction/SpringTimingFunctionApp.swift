//
//  SpringTimingFunctionApp.swift
//  SpringTimingFunction
//
//  Created by qaq on 2/12/2025.
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        let windowRect = NSRect(x: 0, y: 0, width: 600, height: 700)
        window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false,
        )
        window.title = "Spring Timing Function Demo"
        window.center()
        window.contentView = SpringDemoView(frame: windowRect)
        window.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        true
    }
}
