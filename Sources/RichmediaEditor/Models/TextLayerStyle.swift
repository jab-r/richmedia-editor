//
// TextLayerStyle.swift
// RichmediaEditor
//
// Text styling properties (font, color, effects)
//

import Foundation
import CoreGraphics

public struct TextLayerStyle: Codable, Equatable {
    public var font: String
    public var size: CGFloat
    public var color: String
    public var backgroundColor: String?
    public var bold: Bool
    public var italic: Bool
    public var underline: Bool
    public var strikethrough: Bool
    public var align: TextAlignment
    public var shadow: TextShadow?
    public var outline: TextOutline?

    public init(
        font: String = "System",
        size: CGFloat = 32,
        color: String = "#FFFFFF",
        backgroundColor: String? = nil,
        bold: Bool = false,
        italic: Bool = false,
        underline: Bool = false,
        strikethrough: Bool = false,
        align: TextAlignment = .center,
        shadow: TextShadow? = nil,
        outline: TextOutline? = nil
    ) {
        self.font = font
        self.size = size
        self.color = color
        self.backgroundColor = backgroundColor
        self.bold = bold
        self.italic = italic
        self.underline = underline
        self.strikethrough = strikethrough
        self.align = align
        self.shadow = shadow
        self.outline = outline
    }
}

public enum TextAlignment: String, Codable, Equatable {
    case left
    case center
    case right
}

public struct TextShadow: Codable, Equatable {
    public var color: String
    public var opacity: CGFloat
    public var radius: CGFloat
    public var offset: CGSize

    public init(
        color: String = "#000000",
        opacity: CGFloat = 0.5,
        radius: CGFloat = 4,
        offset: CGSize = CGSize(width: 0, height: 2)
    ) {
        self.color = color
        self.opacity = opacity
        self.radius = radius
        self.offset = offset
    }
}

public struct TextOutline: Codable, Equatable {
    public var color: String
    public var width: CGFloat

    public init(
        color: String = "#000000",
        width: CGFloat = 2
    ) {
        self.color = color
        self.width = width
    }
}
