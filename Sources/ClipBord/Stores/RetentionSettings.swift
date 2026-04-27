import Foundation

@MainActor
final class RetentionSettings: ObservableObject {
    static let unlimited = 0

    static let countOptions: [(value: Int, title: String)] = [
        (unlimited, "Off"),
        (50, "50 items"),
        (60, "60 items"),
        (100, "100 items"),
        (200, "200 items"),
        (500, "500 items"),
    ]

    static let ageOptions: [(value: Int, title: String)] = [
        (unlimited, "Off"),
        (7, "7 days"),
        (30, "30 days"),
        (90, "90 days"),
    ]

    @Published var maximumUnpinnedItems: Int {
        didSet {
            UserDefaults.standard.set(maximumUnpinnedItems, forKey: Self.maximumUnpinnedItemsKey)
        }
    }

    @Published var maximumUnpinnedAgeDays: Int {
        didSet {
            UserDefaults.standard.set(maximumUnpinnedAgeDays, forKey: Self.maximumUnpinnedAgeDaysKey)
        }
    }

    init() {
        let defaults = UserDefaults.standard
        let savedMaximum = defaults.object(forKey: Self.maximumUnpinnedItemsKey) as? Int
        let savedAge = defaults.object(forKey: Self.maximumUnpinnedAgeDaysKey) as? Int

        maximumUnpinnedItems = savedMaximum ?? 60
        maximumUnpinnedAgeDays = savedAge ?? Self.unlimited
    }

    var summary: String {
        let count = Self.title(for: maximumUnpinnedItems, in: Self.countOptions)
        let age = Self.title(for: maximumUnpinnedAgeDays, in: Self.ageOptions)
        return "Recent: \(count), age: \(age)"
    }

    static func title(for value: Int, in options: [(value: Int, title: String)]) -> String {
        options.first(where: { $0.value == value })?.title ?? "\(value)"
    }

    private static let maximumUnpinnedItemsKey = "ClipBord.retention.maximumUnpinnedItems"
    private static let maximumUnpinnedAgeDaysKey = "ClipBord.retention.maximumUnpinnedAgeDays"
}
