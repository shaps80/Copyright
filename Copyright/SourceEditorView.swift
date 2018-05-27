//
//  SourceEditorView.swift
//  Copyright
//
//  Created by Shaps Benkau on 24/05/2018.
//  Copyright © 2018 152percent Ltd. All rights reserved.
//

import AppKit
import CopyLib

public final class SourceEditorView: NSTextView {

    // </token/>
    private lazy var tokenRegex: NSRegularExpression = {
        // swiftlint:disable force_try
        return try! NSRegularExpression(pattern: "</.+?/>", options: [])
    }()

    public override var string: String {
        didSet { invalidateText() }
    }

    public override func awakeFromNib() {
        super.awakeFromNib()

        textStorage?.delegate = self
        layoutManager?.delegate = self

        usesRuler = true
        usesFindBar = true
        lnv_setUpLineNumberView()
        invalidateText()

        enclosingScrollView?.hasVerticalRuler = UserDefaults.standard[.showLineNumbers]
    }

    public func toggleLineNumbers() {
        enclosingScrollView?.hasVerticalRuler = UserDefaults.standard[.showLineNumbers]
    }

    public func invalidateText() {
        let size: CGFloat = UserDefaults.standard[.fontSize]
        font = NSFont.userFixedPitchFont(ofSize: size)
            ?? NSFont.systemFont(ofSize: size)

        textColor = NSColor.secondaryLabelColor
        typingAttributes = [.font: font!, .foregroundColor: textColor!]
        insertionPointColor = NSColor.systemBlue
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

extension SourceEditorView: NSLayoutManagerDelegate {

    public func layoutManager(_ layoutManager: NSLayoutManager, shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<NSRect>, lineFragmentUsedRect: UnsafeMutablePointer<NSRect>, baselineOffset: UnsafeMutablePointer<CGFloat>, in textContainer: NSTextContainer, forGlyphRange glyphRange: NSRange) -> Bool {

        let size: CGFloat = UserDefaults.standard[.fontSize]
        let font = NSFont.userFixedPitchFont(ofSize: size) ?? NSFont.systemFont(ofSize: size)
        let lineHeightMultiple: CGFloat = 1.6
        let fontLineHeight = layoutManager.defaultLineHeight(for: font)
        let lineHeight = fontLineHeight * lineHeightMultiple
        let baselineNudge = (lineHeight - fontLineHeight)
            // The following factor is a result of experimentation:
            * 0.6

        var rect = lineFragmentRect.pointee
        rect.size.height = lineHeight

        var usedRect = lineFragmentUsedRect.pointee
        usedRect.size.height = max(lineHeight, usedRect.size.height) // keep emoji sizes

        lineFragmentRect.pointee = rect
        lineFragmentUsedRect.pointee = usedRect
        baselineOffset.pointee += baselineNudge

        return true
    }

}

extension SourceEditorView: NSTextStorageDelegate {

    public func textStorage(_ textStorage: NSTextStorage, willProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        let string = textStorage.string as NSString
        let lineRange = string.lineRange(for: editedRange)
        let line = string.substring(with: lineRange)
        let matches = tokenRegex.matches(in: line, options: [], range: NSRange(location: 0, length: line.count))

        let tokens = matches
            .map { $0.range }
            .map { line[Range($0, in: line)!] }
            .map { $0.dropFirst(2) }
            .map { $0.dropLast(2) }

        let cells = tokens
            .map { String($0) }
            .map { TokenCell(textCell: $0) }

        let attachments = cells.map { cell -> NSTextAttachment in
            let attachment = NSTextAttachment()
            attachment.attachmentCell = cell
            return attachment
        }

        let tokenStrings = attachments
            .map { NSAttributedString(attachment: $0) }

        for (match, string) in zip(matches, tokenStrings).reversed() {
            textStorage.replaceCharacters(in: match.range, with: string)
        }
    }

}
