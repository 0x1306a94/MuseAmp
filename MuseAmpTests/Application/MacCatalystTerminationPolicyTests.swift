import Foundation
@testable import MuseAmp
import MuseAmpPlayerKit
import Testing

struct MacCatalystTerminationPolicyTests {
    @Test
    func `Quit confirmation is required while playback is active`() {
        let playingSnapshot = PlaybackSnapshot(
            state: .playing,
            queue: [],
            playerIndex: nil,
            currentTime: 0,
            duration: 0,
            repeatMode: .off,
            shuffled: false,
            source: nil,
            isCurrentTrackLiked: false,
            outputDevice: nil,
        )
        let bufferingSnapshot = PlaybackSnapshot(
            state: .buffering,
            queue: [],
            playerIndex: nil,
            currentTime: 0,
            duration: 0,
            repeatMode: .off,
            shuffled: false,
            source: nil,
            isCurrentTrackLiked: false,
            outputDevice: nil,
        )

        #expect(MacCatalystTerminationPolicy.shouldConfirmQuit(for: playingSnapshot) == true)
        #expect(MacCatalystTerminationPolicy.shouldConfirmQuit(for: bufferingSnapshot) == true)
    }

    @Test
    func `Quit confirmation stays silent when playback is idle or paused`() {
        let pausedSnapshot = PlaybackSnapshot(
            state: .paused,
            queue: [],
            playerIndex: nil,
            currentTime: 0,
            duration: 0,
            repeatMode: .off,
            shuffled: false,
            source: nil,
            isCurrentTrackLiked: false,
            outputDevice: nil,
        )
        let idleSnapshot = PlaybackSnapshot.empty

        #expect(MacCatalystTerminationPolicy.shouldConfirmQuit(for: pausedSnapshot) == false)
        #expect(MacCatalystTerminationPolicy.shouldConfirmQuit(for: idleSnapshot) == false)
    }

    @Test
    func `Termination confirmation is required while downloads are active`() {
        #expect(
            MacCatalystTerminationPolicy.shouldConfirmTermination(
                for: .empty,
                hasExecutingDownloads: true,
            ) == true,
        )
        #expect(
            MacCatalystTerminationPolicy.shouldConfirmTermination(
                for: .empty,
                hasExecutingDownloads: false,
            ) == false,
        )
    }

    @Test
    func `Last window closure exits the Catalyst app`() {
        #expect(MacCatalystTerminationPolicy.shouldExitAfterSceneDisconnect(remainingWindowSceneCount: 0) == true)
        #expect(MacCatalystTerminationPolicy.shouldExitAfterSceneDisconnect(remainingWindowSceneCount: 1) == false)
        #expect(MacCatalystTerminationPolicy.shouldExitAfterSceneDisconnect(remainingWindowSceneCount: 2) == false)
    }
}
