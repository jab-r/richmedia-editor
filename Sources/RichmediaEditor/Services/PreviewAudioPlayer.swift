//
// PreviewAudioPlayer.swift
// RichmediaEditor
//
// Looping AVPlayer for Apple Music 30-second previews
//

import AVFoundation
import Combine

#if canImport(UIKit)

@MainActor
public class PreviewAudioPlayer: ObservableObject {
    @Published public var isPlaying = false
    @Published public private(set) var currentTrack: MusicTrack?

    private var player: AVPlayer?
    private var loopObserver: Any?
    private var statusCancellable: AnyCancellable?

    public init() {}

    /// Start playing a track's preview URL in a loop
    public func play(_ track: MusicTrack) {
        stop()

        guard let url = URL(string: track.previewURL) else { return }

        configureAudioSession()

        let playerItem = AVPlayerItem(url: url)
        let avPlayer = AVPlayer(playerItem: playerItem)
        self.player = avPlayer
        self.currentTrack = track

        // Observe player item status — ensure playback starts once buffered
        statusCancellable = playerItem.publisher(for: \.status)
            .sink { [weak self] status in
                Task { @MainActor [weak self] in
                    guard let self, status == .readyToPlay else { return }
                    self.player?.play()
                }
            }

        // Loop: when playback ends, seek back to start
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.player?.seek(to: .zero)
                self?.player?.play()
            }
        }

        avPlayer.play()
        isPlaying = true
    }

    /// Pause playback (resume with `resume()`)
    public func pause() {
        player?.pause()
        isPlaying = false
    }

    /// Resume paused playback
    public func resume() {
        player?.play()
        isPlaying = true
    }

    /// Stop playback and release player
    public func stop() {
        player?.pause()
        statusCancellable?.cancel()
        statusCancellable = nil
        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
            loopObserver = nil
        }
        player = nil
        currentTrack = nil
        isPlaying = false
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: .mixWithOthers)
            try session.setActive(true)
        } catch {
            // Audio session configuration failed — playback may still work
        }
    }

    deinit {
        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

#endif
