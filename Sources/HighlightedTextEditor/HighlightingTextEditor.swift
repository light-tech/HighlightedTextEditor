//
//  File.swift
//  
//
//  Created by Kyle Nazario on 8/31/20.
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

public struct TextFormattingRule {
    #if os(macOS)
    public typealias SymbolicTraits = NSFontDescriptor.SymbolicTraits
    #else
    public typealias SymbolicTraits = UIFontDescriptor.SymbolicTraits
    #endif

    let group: Int
    let key: NSAttributedString.Key?
    let value: Any?
    let fontTraits: SymbolicTraits
    
    // ------------------- convenience ------------------------
    
    public init(key: NSAttributedString.Key, value: Any) {
        self.init(group: 0, key: key, value: value, fontTraits: [])
    }
    
    public init(fontTraits: SymbolicTraits) {
        self.init(group: 0, key: nil, value: nil, fontTraits: fontTraits)
    }
    
    // ------------------ most powerful initializer ------------------
    
    public init(group: Int = 0, key: NSAttributedString.Key? = nil, value: Any? = nil, fontTraits: SymbolicTraits = []) {
        self.group = group
        self.key = key
        self.value = value
        self.fontTraits = fontTraits
    }
}

public struct HighlightRule {
    let pattern: NSRegularExpression
    
    let formattingRules: Array<TextFormattingRule>
    
    // ------------------- convenience ------------------------
    
    public init(pattern: NSRegularExpression, formattingRule: TextFormattingRule) {
        self.init(pattern: pattern, formattingRules: [formattingRule])
    }
    
    // ------------------ most powerful initializer ------------------
    
    public init(pattern: NSRegularExpression, formattingRules: Array<TextFormattingRule>) {
        self.pattern = pattern
        self.formattingRules = formattingRules
    }
}

internal protocol HighlightingTextEditor {
    var text: String { get set }
    var highlightRules: [HighlightRule] { get }
}

extension HighlightingTextEditor {
    
    var placeholderFont: SystemColorAlias {
        get { SystemColorAlias() }
    }
    
    #if os(macOS)
    public typealias SystemFontAlias = NSFont
    public typealias SystemColorAlias = NSColor
    #else
    public typealias SystemFontAlias = UIFont
    public typealias SystemColorAlias = UIColor
    #endif
    
    static func getHighlightedText(text: String, highlightRules: [HighlightRule], font: SystemFontAlias?, color: SystemColorAlias?) -> NSMutableAttributedString {
        let highlightedString = NSMutableAttributedString(string: text)
        let all = NSRange(location: 0, length: text.count)
        
        #if os(macOS)
        let editorFont = font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let editorTextColor = color ?? NSColor.labelColor
        #else
        let editorFont = font ?? UIFont.preferredFont(forTextStyle: .body)
        let editorTextColor = color ?? UIColor.label
        #endif
        
        highlightedString.addAttribute(.font, value: editorFont, range: all)
        highlightedString.addAttribute(.foregroundColor, value: editorTextColor, range: all)
        
        highlightRules.forEach { rule in
            let matches = rule.pattern.matches(in: text, options: [], range: all)
            matches.forEach { match in
                rule.formattingRules.forEach { formattingRule in
                    
                    #if os(macOS)
                    var font = NSFont()
                    #else
                    var font = UIFont()
                    #endif
                    var r = match.range(at: formattingRule.group)
                    highlightedString.enumerateAttributes(in: r, options: []) { attributes, range, stop in
                        let fontAttribute = attributes.first { $0.key == .font }!
                        #if os(macOS)
                        let previousFont = fontAttribute.value as! NSFont
                        #else
                        let previousFont = fontAttribute.value as! UIFont
                        #endif
                        font = previousFont.with(formattingRule.fontTraits)
                    }
                    highlightedString.addAttribute(.font, value: font, range: r)
                    
                    guard let key = formattingRule.key, let value = formattingRule.value else { return }
                    highlightedString.addAttribute(key, value: value, range: r)
                }
            }
        }
        
        return highlightedString
    }
}
