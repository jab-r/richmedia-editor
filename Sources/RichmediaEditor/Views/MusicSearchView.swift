//
// MusicSearchView.swift
// RichmediaEditor
//
// Search Apple Music catalog and select a song for background preview playback
//

import SwiftUI
import MusicKit

#if canImport(UIKit)

struct MusicSearchView: View {
    let currentTrack: MusicTrack?
    let onSelect: (MusicTrack?) -> Void

    @StateObject private var searchService = AppleMusicSearchService()
    @StateObject private var audioPlayer = PreviewAudioPlayer()
    @State private var query = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search songs...", text: $query)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 8)

                // Content
                if !searchService.isMusicKitAvailable {
                    plistMissingView
                } else if searchService.authorizationStatus == .notDetermined {
                    authorizationPrompt
                } else if searchService.authorizationStatus == .denied {
                    deniedView
                } else {
                    resultsList
                }

                // Current selection bar
                if let track = currentTrack {
                    currentSelectionBar(track: track)
                }
            }
            .navigationTitle("Add Music")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        audioPlayer.stop()
                        dismiss()
                    }
                }
            }
            .onChange(of: query) { newValue in
                searchService.search(query: newValue)
            }
            .task {
                if searchService.isMusicKitAvailable && searchService.authorizationStatus == .notDetermined {
                    await searchService.requestAuthorization()
                }
            }
            .onDisappear {
                audioPlayer.stop()
            }
        }
    }

    // MARK: - Missing Plist Key

    private var plistMissingView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text("Music Not Configured")
                .font(.title3.bold())
            Text("Add NSAppleMusicUsageDescription to your app's Info.plist to enable Apple Music search.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Authorization

    private var authorizationPrompt: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "music.note.house")
                .font(.system(size: 48))
                .foregroundStyle(.pink.gradient)
            Text("Apple Music Access")
                .font(.title3.bold())
            Text("Allow access to search the Apple Music catalog and preview songs.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Grant Access") {
                Task {
                    await searchService.requestAuthorization()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
            Spacer()
        }
    }

    private var deniedView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "music.note.house")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Music Access Denied")
                .font(.title3.bold())
            Text("Enable Apple Music access in Settings to search for songs.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Results

    private var resultsList: some View {
        Group {
            if searchService.isSearching {
                VStack {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                }
            } else if let error = searchService.errorMessage {
                VStack {
                    Spacer()
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else if searchService.results.isEmpty && !query.isEmpty {
                VStack {
                    Spacer()
                    Text("No results")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else if searchService.results.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "music.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Search for a song to add background music")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(searchService.results, id: \.appleMusicID) { track in
                        songRow(track: track)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func songRow(track: MusicTrack) -> some View {
        HStack(spacing: 12) {
            // Artwork
            if let artworkURL = track.artworkURL, let url = URL(string: artworkURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.2))
                        .overlay {
                            Image(systemName: "music.note")
                                .foregroundColor(.secondary)
                        }
                }
                .frame(width: 50, height: 50)
                .cornerRadius(6)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "music.note")
                            .foregroundColor(.secondary)
                    }
            }

            // Track info
            VStack(alignment: .leading, spacing: 2) {
                Text(track.trackName)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(track.artistName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                if let album = track.albumName {
                    Text(album)
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Preview play/pause
            Button(action: {
                togglePreview(track: track)
            }) {
                Image(systemName: isPreviewPlaying(track: track) ? "pause.circle.fill" : "play.circle")
                    .font(.title2)
                    .foregroundStyle(.pink.gradient)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            audioPlayer.stop()
            onSelect(track)
            dismiss()
        }
    }

    // MARK: - Current Selection

    private func currentSelectionBar(track: MusicTrack) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "music.note")
                .foregroundStyle(.pink.gradient)

            VStack(alignment: .leading, spacing: 1) {
                Text(track.trackName)
                    .font(.caption.bold())
                    .lineLimit(1)
                Text(track.artistName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: {
                audioPlayer.stop()
                onSelect(nil)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: - Preview Playback

    private func togglePreview(track: MusicTrack) {
        if isPreviewPlaying(track: track) {
            audioPlayer.pause()
        } else if audioPlayer.currentTrack?.appleMusicID == track.appleMusicID {
            audioPlayer.resume()
        } else {
            audioPlayer.play(track)
        }
    }

    private func isPreviewPlaying(track: MusicTrack) -> Bool {
        audioPlayer.isPlaying && audioPlayer.currentTrack?.appleMusicID == track.appleMusicID
    }
}

#endif
