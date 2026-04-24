import AppKit
import Foundation

/// Fetches the latest GitHub release and compares it to the running app version.
@MainActor
final class GitHubUpdateChecker: ObservableObject {
    enum Phase: Equatable {
        case idle
        case checking
        case upToDate
        case updateAvailable(versionLabel: String, installSourceURL: URL)
        case downloading
        case failed
    }

    /// `owner/name` repository that hosts releases (DMG attached to each release).
    static let defaultRepository = "poommin2543/ClipBordOnMacos"

    private static let lastCheckDefaultsKey = "ClipBord.lastGitHubReleaseCheck"
    private static let minimumCheckInterval: TimeInterval = 3 * 60 * 60

    @Published private(set) var phase: Phase = .idle

    private var pendingVersionLabel: String?
    private var pendingRemoteURL: URL?
    private var isReleaseCheckInFlight = false

    private let repository: String
    private let session: URLSession

    init(repository: String = GitHubUpdateChecker.defaultRepository) {
        self.repository = repository
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 120
        configuration.timeoutIntervalForResource = 600
        session = URLSession(configuration: configuration)
    }

    /// Checks the GitHub API unless a check is already running or the last successful check was recent.
    /// Called from `ClipboardPanelView` when the panel appears.
    func checkIfNeeded() {
        guard phase != .checking, phase != .downloading, !isReleaseCheckInFlight else {
            return
        }

        let now = Date()
        if let last = UserDefaults.standard.object(forKey: Self.lastCheckDefaultsKey) as? Date,
           now.timeIntervalSince(last) < Self.minimumCheckInterval {
            return
        }

        isReleaseCheckInFlight = true
        Task { @MainActor [weak self] in
            defer { self?.isReleaseCheckInFlight = false }
            await self?.checkNow()
        }
    }

    /// Checks GitHub on every cold launch (no throttle) so a newer release is not missed for hours.
    /// Still skips if another check is already in flight.
    func checkOnColdLaunch() {
        guard phase != .checking, phase != .downloading, !isReleaseCheckInFlight else {
            return
        }

        isReleaseCheckInFlight = true
        Task { @MainActor [weak self] in
            defer { self?.isReleaseCheckInFlight = false }
            await self?.checkNow()
        }
    }

    /// Opens the DMG in the browser (no in-place install).
    func openReleaseDownloadPage(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    /// When running from a packaged `.app`, downloads the DMG then installs over this bundle after quit.
    func beginInstallUpdate() {
        guard case let .updateAvailable(versionLabel, remoteURL) = phase else {
            return
        }

        if !ClipBordReleaseInstaller.isRunningFromAppBundle {
            NSWorkspace.shared.open(remoteURL)
            return
        }

        pendingVersionLabel = versionLabel
        pendingRemoteURL = remoteURL
        phase = .downloading

        Task {
            await downloadAndOfferInstall(remoteURL: remoteURL)
        }
    }

    private func downloadAndOfferInstall(remoteURL: URL) async {
        do {
            let (tmpFile, _) = try await session.download(from: remoteURL)
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent("ClipBord-update-\(UUID().uuidString).dmg")
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.moveItem(at: tmpFile, to: dest)

            await MainActor.run {
                self.installFromDownloadedDMG(localDmgURL: dest)
            }
        } catch {
            await MainActor.run {
                self.restorePendingUpdateAfterDownloadFailure()
            }
        }
    }

    private func restorePendingUpdateAfterDownloadFailure() {
        if let label = pendingVersionLabel, let url = pendingRemoteURL {
            phase = .updateAvailable(versionLabel: label, installSourceURL: url)
        } else {
            phase = .failed
        }
    }

    /// One-step install after download: schedule the shell installer, then quit immediately so the update can run.
    private func installFromDownloadedDMG(localDmgURL: URL) {
        NSApp.activate(ignoringOtherApps: true)

        do {
            try ClipBordReleaseInstaller.installAfterQuit(
                dmgURL: localDmgURL,
                targetAppBundle: Bundle.main.bundleURL
            )
            NSApplication.shared.terminate(nil)
        } catch {
            let errorAlert = NSAlert()
            errorAlert.messageText = "Could not install update"
            errorAlert.informativeText = error.localizedDescription
            errorAlert.runModal()
            try? FileManager.default.removeItem(at: localDmgURL)
            restorePendingUpdateAfterDownloadFailure()
        }
    }

    private func checkNow() async {
        phase = .checking
        pendingVersionLabel = nil
        pendingRemoteURL = nil

        do {
            let release = try await fetchLatestRelease()
            let remoteVersion = Self.normalizedVersion(fromTag: release.tagName)

            guard Self.isPlausibleSemver(remoteVersion) else {
                phase = .upToDate
                UserDefaults.standard.set(Date(), forKey: Self.lastCheckDefaultsKey)
                return
            }

            let rawLocal = AppVersion.marketing.trimmingCharacters(in: .whitespacesAndNewlines)
            let localEffective: String
            if rawLocal.isEmpty || rawLocal == "—" || !Self.isPlausibleSemver(rawLocal) {
                localEffective = "0.0.0"
            } else {
                localEffective = rawLocal
            }

            guard Self.isVersionString(remoteVersion, newerThan: localEffective) else {
                phase = .upToDate
                UserDefaults.standard.set(Date(), forKey: Self.lastCheckDefaultsKey)
                return
            }

            guard let url = Self.preferredDownloadURL(from: release) else {
                phase = .failed
                return
            }

            let label = "v\(remoteVersion)"
            pendingVersionLabel = label
            pendingRemoteURL = url
            phase = .updateAvailable(versionLabel: label, installSourceURL: url)
            UserDefaults.standard.set(Date(), forKey: Self.lastCheckDefaultsKey)
        } catch {
            phase = .failed
        }
    }

    private func fetchLatestRelease() async throws -> GitHubLatestReleaseDTO {
        let endpoint = URL(string: "https://api.github.com/repos/\(repository)/releases/latest")!
        var request = URLRequest(url: endpoint)
        request.setValue("ClipBord/\(AppVersion.marketing)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200 ... 299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(GitHubLatestReleaseDTO.self, from: data)
    }

    private static func normalizedVersion(fromTag tag: String) -> String {
        var t = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("v") || t.hasPrefix("V") {
            t.removeFirst()
        }
        return t
    }

    private static func isPlausibleSemver(_ string: String) -> Bool {
        guard !string.isEmpty else {
            return false
        }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-+"))
        return string.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    private static func isVersionString(_ lhs: String, newerThan rhs: String) -> Bool {
        lhs.compare(rhs, options: .numeric) == .orderedDescending
    }

    private static func preferredDownloadURL(from release: GitHubLatestReleaseDTO) -> URL? {
        let assets = release.assets
        let dmgAssets = assets.filter { $0.name.lowercased().hasSuffix(".dmg") }
        let named = dmgAssets.first { $0.name.localizedCaseInsensitiveContains("ClipBord") }
        let chosen = named ?? dmgAssets.first
        if let urlString = chosen?.browserDownloadUrl, let url = URL(string: urlString) {
            return url
        }
        return URL(string: release.htmlUrl)
    }
}

// MARK: - DTOs

private struct GitHubLatestReleaseDTO: Decodable {
    let tagName: String
    let htmlUrl: String
    let assets: [GitHubReleaseAssetDTO]
}

private struct GitHubReleaseAssetDTO: Decodable {
    let name: String
    let browserDownloadUrl: String
}
