//
//  SettingsViewController+Actions.swift
//  MuseAmp
//
//  Created by @Lakr233 on 2026/04/11.
//

import AlertController
import ConfigurableKit
import Kingfisher
import UIKit

extension SettingsViewController {
    func openPrivacyPolicy() {
        let vc = TextViewerController(
            title: String(localized: "Privacy Policy"),
            text: aboutDocumentText(for: .privacyPolicy),
        )
        navigationController?.pushViewController(vc, animated: true)
    }

    func openOpenSourceLicenses() {
        let vc = TextViewerController(
            title: String(localized: "Open Source Licenses"),
            text: aboutDocumentText(for: .openSourceLicenses),
        )
        navigationController?.pushViewController(vc, animated: true)
    }

    func makePrivacyPolicyObject() -> ConfigurableObject {
        ConfigurableObject(
            icon: "lock.shield",
            title: "Privacy Policy",
            explain: "How Muse Amp handles server settings, local music files, transfers, and on-device data.",
            ephemeralAnnotation: .action { [weak self] _ in
                guard let self else { return }
                openPrivacyPolicy()
            },
        )
    }

    func makeOpenSourceLicensesObject() -> ConfigurableObject {
        ConfigurableObject(
            icon: "flag.filled.and.flag.crossed",
            title: "Open Source Licenses",
            explain: "Third-party libraries and their license terms.",
            ephemeralAnnotation: .action { [weak self] _ in
                guard let self else { return }
                openOpenSourceLicenses()
            },
        )
    }

    func openDownloads() {
        let controller = DownloadsViewController(
            downloadManager: environment.downloadManager,
            playlistStore: environment.playlistStore,
            environment: environment,
        )
        navigationController?.pushViewController(controller, animated: true)
    }

    func openLogs() {
        let controller = LogViewerController()
        navigationController?.pushViewController(controller, animated: true)
    }

    func makeTransferObject() -> ConfigurableObject {
        ConfigurableObject(
            icon: "arrow.triangle.2.circlepath.circle",
            title: "Transfer Songs",
            explain: "Send or receive songs with another device on the same network.",
            ephemeralAnnotation: .action { [weak self] _ in
                self?.openTransfer()
            },
        )
    }

    func openTransfer() {
        let controller = SyncRoleSelectionViewController(environment: environment)
        navigationController?.pushViewController(controller, animated: true)
    }

    func makeRebuildDatabaseObject() -> ConfigurableObject {
        ConfigurableObject(
            icon: "arrow.triangle.2.circlepath",
            title: "Rebuild Database",
            explain: "Force-rescan all local audio files, re-extract artwork, and repair database mismatches.",
            ephemeralAnnotation: .action { [weak self] _ in
                guard let self else { return }
                confirmRebuildDatabase()
            },
        )
    }

    func confirmRebuildDatabase() {
        ConfirmationAlertPresenter.present(
            on: self,
            title: String(localized: "Rebuild Database"),
            message: String(localized: "This will rescan all local audio files, re-extract artwork, and rebuild the library database. Unreadable files will be removed."),
            confirmTitle: String(localized: "Rebuild"),
        ) { [weak self] in
            self?.rebuildDatabase()
        }
    }

    func rebuildDatabase() {
        let progressAlert = AlertProgressIndicatorViewController(
            title: String(localized: "Rebuilding Database"),
            message: String(localized: "Scanning local files..."),
        )
        present(progressAlert, animated: true)

        Task { @MainActor [weak self, weak progressAlert, env = environment] in
            do {
                ImageCache.default.clearMemoryCache()
                await withCheckedContinuation { continuation in
                    ImageCache.default.clearDiskCache { continuation.resume() }
                }
                Self.removeOldAPICacheDirectory()

                guard let progressAlert else { return }
                let result = try await env.rebuildLibraryDatabase(
                    forceArtwork: true,
                    progressCallback: { current, total in
                        DispatchQueue.main.async {
                            progressAlert.progressContext.purpose(
                                message: String(
                                    format: String(localized: "Processing %d/%d..."),
                                    current + 1, total,
                                ),
                            )
                        }
                    },
                )
                progressAlert.dismiss(animated: true) {
                    guard let self else { return }
                    let alert = AlertViewController(
                        title: String(localized: "Rebuild Complete"),
                        message: String(
                            format: String(localized: "Scanned %d, updated %d, removed %d, purged %d"),
                            result.filesScanned, result.upserts, result.deletions, result.purged,
                        ),
                    ) { context in
                        context.addAction(title: String(localized: "OK"), attribute: .accent) { context.dispose() }
                    }
                    self.present(alert, animated: true)
                }
            } catch {
                AppLog.error("SettingsViewController", "rebuildDatabase failed: \(error.localizedDescription)")
                progressAlert?.dismiss(animated: true) {
                    guard let self else { return }
                    let alert = AlertViewController(
                        title: String(localized: "Rebuild Failed"),
                        message: error.localizedDescription,
                    ) { context in
                        context.addAction(title: String(localized: "OK"), attribute: .accent) { context.dispose() }
                    }
                    self.present(alert, animated: true)
                }
            }
        }
    }

    private static func removeOldAPICacheDirectory() {
        guard let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return
        }
        let cacheDir = cachesURL.appendingPathComponent("APIResponseCache", isDirectory: true)
        guard FileManager.default.fileExists(atPath: cacheDir.path) else { return }
        do {
            try FileManager.default.removeItem(at: cacheDir)
            AppLog.info("SettingsViewController", "removed old APIResponseCache directory")
        } catch {
            AppLog.warning("SettingsViewController", "failed to remove APIResponseCache: \(error.localizedDescription)")
        }
    }
}

private extension SettingsViewController {
    enum AboutDocumentSection {
        case privacyPolicy
        case openSourceLicenses

        var resourceName: String {
            switch self {
            case .privacyPolicy:
                "PrivacyPolicy"
            case .openSourceLicenses:
                "OpenSourceLicenses"
            }
        }
    }

    func aboutDocumentText(for section: AboutDocumentSection) -> String {
        let fallback = String(localized: "Resource not found, please check your installation.")
        guard let url = Bundle.main.url(forResource: section.resourceName, withExtension: "md"),
              let content = try? String(contentsOf: url)
        else {
            return fallback
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
