//
// MediaInput.swift
// RichmediaEditor
//
// Input media types for the editor
//

import Foundation

#if canImport(UIKit)
import UIKit

public enum MediaInput: Equatable {
    /// Image with optional uploaded URL and media ID
    /// If url/mediaId are nil, consuming app must upload before using editor
    case image(UIImage, url: String? = nil, mediaId: String? = nil)

    /// Video with local or remote URL
    case video(URL, mediaId: String? = nil)

    public var isVideo: Bool {
        if case .video = self {
            return true
        }
        return false
    }

    public var isImage: Bool {
        if case .image = self {
            return true
        }
        return false
    }

    /// Uploaded URL (for images) or video URL
    public var url: String? {
        switch self {
        case .image(_, let url, _):
            return url
        case .video(let videoUrl, _):
            return videoUrl.absoluteString
        }
    }

    /// Media ID for tracking
    public var mediaId: String? {
        switch self {
        case .image(_, _, let id):
            return id
        case .video(_, let id):
            return id
        }
    }
}
#endif
