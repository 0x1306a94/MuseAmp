//
//  MacCatalystTerminationPolicy.swift
//  MuseAmp
//
//  Created by OpenAI Codex on 2026/04/15.
//

import Foundation
import MuseAmpPlayerKit

enum MacCatalystTerminationPolicy {
    static func shouldConfirmQuit(for snapshot: PlaybackSnapshot) -> Bool {
        switch snapshot.state {
        case .playing, .buffering:
            true
        case .idle, .paused, .error:
            false
        }
    }

    static func shouldConfirmTermination(
        for snapshot: PlaybackSnapshot,
        hasExecutingDownloads: Bool,
    ) -> Bool {
        shouldConfirmQuit(for: snapshot) || hasExecutingDownloads
    }

    static func shouldExitAfterSceneDisconnect(remainingWindowSceneCount: Int) -> Bool {
        remainingWindowSceneCount == 0
    }
}
