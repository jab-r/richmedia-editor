//
// TextLayer.swift
// RichmediaEditor
//
// Text overlay layer model with position, style, and animation
//

import Foundation
import CoreGraphics

public struct TextLayer: Codable, Identifiable, Equatable {
    public let id: UUID
    public var text: String
    public var position: LayerPosition
    public var style: TextLayerStyle
    public var animation: TextAnimation?
    public var path: AnimationPath?
    public var visible: Bool
    public var zIndex: Int

    public init(
        id: UUID = UUID(),
        text: String,
        position: LayerPosition = LayerPosition(),
        style: TextLayerStyle = TextLayerStyle(),
        animation: TextAnimation? = nil,
        path: AnimationPath? = nil,
        visible: Bool = true,
        zIndex: Int = 0
    ) {
        self.id = id
        self.text = text
        self.position = position
        self.style = style
        self.animation = animation
        self.path = path
        self.visible = visible
        self.zIndex = zIndex
    }
}
