//
//  SourceEditorView.swift
//  Copyright
//
//  Created by Shaps Benkau on 24/05/2018.
//  Copyright © 2018 152percent Ltd. All rights reserved.
//

import AppKit

public final class SourceEditorView: NSTextView {

    public override var string: String {
        didSet { invalidateText() }
    }

    public override func awakeFromNib() {
        super.awakeFromNib()

        usesFindBar = true
        lnv_setUpLineNumberView()
        invalidateText()
    }

    public func invalidateText() {
        let size: CGFloat = UserDefaults.standard[.fontSize]
        font = NSFont.userFixedPitchFont(ofSize: size)
            ?? NSFont.systemFont(ofSize: size)

        textColor = NSColor.secondaryLabelColor

        let style = NSMutableParagraphStyle()
        style.lineSpacing = 7

        defaultParagraphStyle = style
        typingAttributes = [.paragraphStyle: style, .font: font!, .foregroundColor: textColor!]
    }

    public override var font: NSFont? {
        didSet { ruler?.setNeedsDisplay(ruler?.bounds ?? .zero) }
    }

    public var ruler: NSRulerView? {
        willSet {
            if ruler != newValue {
                NotificationCenter.default.removeObserver(self, name: NSView.frameDidChangeNotification, object: self)
                NotificationCenter.default.removeObserver(self, name: NSText.didChangeNotification, object: self)
            }
        }
        didSet {
            guard let scrollView = enclosingScrollView else { return }

            ruler?.clientView = self

            scrollView.verticalRulerView = ruler
            scrollView.hasVerticalRuler = true
            scrollView.rulersVisible = true

            NotificationCenter.default.addObserver(self, selector: #selector(didChange(_:)), name: NSView.frameDidChangeNotification, object: self)
            NotificationCenter.default.addObserver(self, selector: #selector(didChange(_:)), name: NSText.didChangeNotification, object: self)
        }
    }

    public override func pasteAsRichText(_ sender: Any?) {
        pasteAsPlainText(sender)
    }

    public override func paste(_ sender: Any?) {
        pasteAsPlainText(sender)
    }

    @objc private func didChange(_ note: Notification) {
        ruler?.needsDisplay = true
        invalidateText()
    }

}
