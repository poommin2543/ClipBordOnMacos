import Foundation

enum AppVersion {
    /// `CFBundleShortVersionString` from the running bundle (set when packaging the `.app`).
    static var marketing: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    static var displayLabel: String {
        let v = marketing.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !v.isEmpty, v != "—" else {
            return "dev"
        }
        return v.hasPrefix("v") ? v : "v\(v)"
    }
}
