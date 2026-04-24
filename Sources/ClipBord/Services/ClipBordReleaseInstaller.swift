import AppKit
import Foundation

/// Downloads a release DMG and replaces the running `.app` bundle after the process exits.
enum ClipBordReleaseInstaller {
    private static func shellSingleQuoted(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// `true` when the executable lives inside `Something.app/Contents/MacOS/`.
    static var isRunningFromAppBundle: Bool {
        Bundle.main.bundlePath.contains(".app/Contents/MacOS/")
    }

    static func installAfterQuit(dmgURL: URL, targetAppBundle: URL) throws {
        let dmgPath = dmgURL.path
        let targetPath = targetAppBundle.path
        let dmgQ = shellSingleQuoted(dmgPath)
        let targetQ = shellSingleQuoted(targetPath)

        let lines = [
            "#!/bin/bash",
            "set -euo pipefail",
            "DMG=\(dmgQ)",
            "TARGET=\(targetQ)",
            "sleep 2",
            "MOUNT=\"$(/usr/bin/mktemp -d /tmp/clipbord-upd.XXXXXX)\"",
            "/usr/bin/hdiutil attach \"$DMG\" -mountpoint \"$MOUNT\" -nobrowse -quiet",
            "if [[ ! -d \"$MOUNT/ClipBord.app\" ]]; then",
            "  /usr/bin/hdiutil detach \"$MOUNT\" -force -quiet || true",
            "  /bin/rm -rf \"$MOUNT\"",
            "  exit 1",
            "fi",
            "/bin/rm -rf \"$TARGET\"",
            "/usr/bin/ditto \"$MOUNT/ClipBord.app\" \"$TARGET\"",
            "/usr/bin/hdiutil detach \"$MOUNT\" -force -quiet || true",
            "/bin/rm -rf \"$MOUNT\"",
            "/usr/bin/open \"$TARGET\"",
            "/bin/rm -f \"$DMG\"",
        ]
        let body = lines.joined(separator: "\n") + "\n"

        let tempDir = FileManager.default.temporaryDirectory
        let scriptURL = tempDir.appendingPathComponent("clipbord-install-\(UUID().uuidString).sh")
        try body.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [scriptURL.path]
        process.standardOutput = nil
        process.standardError = nil
        try process.run()
    }
}
