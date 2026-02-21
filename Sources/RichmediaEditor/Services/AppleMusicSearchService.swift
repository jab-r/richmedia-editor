//
// AppleMusicSearchService.swift
// RichmediaEditor
//
// Searches the Apple Music catalog via MusicKit and maps results to MusicTrack
//

import Foundation
import MusicKit
import Combine

#if canImport(UIKit)

@MainActor
public class AppleMusicSearchService: ObservableObject {
    @Published public var results: [MusicTrack] = []
    @Published public var isSearching = false
    @Published public var authorizationStatus: MusicAuthorization.Status = .notDetermined
    @Published public var errorMessage: String?
    @Published public var isMusicKitAvailable: Bool = false

    private var searchTask: Task<Void, Never>?

    /// Check whether the host app has the required NSAppleMusicUsageDescription plist key.
    /// Accessing MusicKit APIs without it causes an immediate crash.
    static var hasUsageDescription: Bool {
        Bundle.main.object(forInfoDictionaryKey: "NSAppleMusicUsageDescription") != nil
    }

    public init() {
        if Self.hasUsageDescription {
            isMusicKitAvailable = true
            authorizationStatus = MusicAuthorization.currentStatus
        }
    }

    /// Request MusicKit authorization (one-time system prompt)
    public func requestAuthorization() async {
        guard isMusicKitAvailable else { return }
        let status = await MusicAuthorization.request()
        authorizationStatus = status
    }

    /// Search Apple Music catalog with debounce. Cancels any in-flight search.
    public func search(query: String) {
        searchTask?.cancel()
        errorMessage = nil

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            isSearching = false
            return
        }

        guard isMusicKitAvailable else {
            errorMessage = "Apple Music is not configured. Add NSAppleMusicUsageDescription to your Info.plist."
            return
        }

        isSearching = true

        searchTask = Task {
            // Debounce 400ms
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }

            do {
                var request = MusicCatalogSearchRequest(term: trimmed, types: [Song.self])
                request.limit = 20

                let response = try await request.response()

                guard !Task.isCancelled else { return }

                let tracks: [MusicTrack] = response.songs.compactMap { song in
                    // Preview URL is required — skip songs without one
                    guard let previewURL = song.previewAssets?.first?.url?.absoluteString else {
                        return nil
                    }

                    let artworkURL = song.artwork?.url(width: 100, height: 100)?.absoluteString

                    return MusicTrack(
                        trackName: song.title,
                        artistName: song.artistName,
                        albumName: song.albumTitle,
                        previewURL: previewURL,
                        artworkURL: artworkURL,
                        appleMusicID: song.id.rawValue
                    )
                }

                self.results = tracks
            } catch is CancellationError {
                // Cancelled — no-op
            } catch {
                guard !Task.isCancelled else { return }
                self.errorMessage = "Search failed. Please try again."
                self.results = []
            }

            self.isSearching = false
        }
    }

    /// Clear results and cancel any pending search
    public func clear() {
        searchTask?.cancel()
        results = []
        isSearching = false
        errorMessage = nil
    }
}

#endif
