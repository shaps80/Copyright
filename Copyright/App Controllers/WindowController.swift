//
//  WindowController.swift
//  Copyright
//
//  Created by Shaps Benkau on 23/05/2018.
//  Copyright © 2018 152percent Ltd. All rights reserved.
//

import AppKit

final class WindowController: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()

        window?.titleVisibility = .hidden
        window?.contentView?.wantsLayer = true
        window?.delegate = self
    }

    func windowWillReturnUndoManager(_ window: NSWindow) -> UndoManager? {
        return UndoManager()
    }

    public func window(_ window: NSWindow, willUseFullScreenPresentationOptions proposedOptions: NSApplication.PresentationOptions = []) -> NSApplication.PresentationOptions {
        return [proposedOptions, .autoHideToolbar]
    }

}