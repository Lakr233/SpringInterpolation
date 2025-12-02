//
//  main.swift
//  SpringTimingFunction
//
//  Created by qaq on 2/12/2025.
//

import AppKit

MainActor.assumeIsolated {
    let delegate = AppDelegate()
    NSApplication.shared.delegate = delegate
    _ = NSApplicationMain(
        CommandLine.argc,
        CommandLine.unsafeArgv,
    )
}
