//
// RichPostContent.swift
// RichmediaEditor
//
// Root model for rich media posts with text overlays
// Compatible with Loxation's richmedia format
//

import Foundation

public struct RichPostContent: Codable, Equatable {
    public var version: Int
    public var blocks: [RichPostBlock]

    public static let contentType = "application/vnd.loxation.richmedia+json"

    public init(version: Int = 1, blocks: [RichPostBlock] = []) {
        self.version = version
        self.blocks = blocks
    }

    /// Convert to JSON string for API submission
    public func toJSONString() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(self),
              let jsonString = String(data: data, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }

    /// Parse from JSON string
    public static func fromJSONString(_ jsonString: String) -> RichPostContent? {
        guard let data = jsonString.data(using: .utf8),
              let content = try? JSONDecoder().decode(RichPostContent.self, from: data) else {
            return nil
        }
        return content
    }
}

public struct RichPostBlock: Codable, Identifiable, Equatable {
    public let id: UUID

    // Media fields (existing Loxation format)
    public var image: String?
    public var video: String?
    public var url: String?
    public var caption: String?

    // Text overlay layers (NEW for animated posts)
    public var textLayers: [TextLayer]?

    // Animation metadata
    public var animationVersion: Int?

    public init(
        id: UUID = UUID(),
        image: String? = nil,
        video: String? = nil,
        url: String? = nil,
        caption: String? = nil,
        textLayers: [TextLayer]? = nil,
        animationVersion: Int? = nil
    ) {
        self.id = id
        self.image = image
        self.video = video
        self.url = url
        self.caption = caption
        self.textLayers = textLayers
        self.animationVersion = animationVersion
    }

    /// Block type for rendering logic
    public var blockType: BlockType {
        if video != nil {
            return .video
        } else if image != nil {
            return .image
        } else {
            return .text
        }
    }
}

public enum BlockType {
    case text
    case image
    case video
}
