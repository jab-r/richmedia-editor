//
// MusicTrack.swift
// RichmediaEditor
//
// Apple Music track reference for background audio preview
//

import Foundation

public struct MusicTrack: Codable, Equatable, Sendable {
    /// Display name of the track
    public var trackName: String

    /// Artist name
    public var artistName: String

    /// Album name (optional)
    public var albumName: String?

    /// URL to the 30-second AAC preview (may expire; resolve from appleMusicID if stale)
    public var previewURL: String

    /// Album artwork URL
    public var artworkURL: String?

    /// Apple Music catalog ID — durable identifier for re-resolving on any platform
    public var appleMusicID: String

    public init(
        trackName: String,
        artistName: String,
        albumName: String? = nil,
        previewURL: String,
        artworkURL: String? = nil,
        appleMusicID: String
    ) {
        self.trackName = trackName
        self.artistName = artistName
        self.albumName = albumName
        self.previewURL = previewURL
        self.artworkURL = artworkURL
        self.appleMusicID = appleMusicID
    }
}
