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
    case image(UIImage)
    case video(URL)

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
}
#endif
