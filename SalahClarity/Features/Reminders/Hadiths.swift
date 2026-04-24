//
//  Hadiths.swift
//  Salah Clarity
//
//  Bundled reminders. Curated from Hisnul Muslim and the two Sahihs —
//  short, well-known forms. Feel free to extend this list; the rotation
//  in HadithProvider indexes by day-of-year, so additions are automatic.
//

import Foundation

struct Reminder: Identifiable, Hashable {
    let id: String
    let category: Reminder.Category
    let source: String?

    /// Underlying title storage — either a raw string (azkar, where the Arabic
    /// transliteration is language-neutral) or a localization key for a hadith.
    private let titleStorage: Storage
    private let bodyStorage: Storage

    private enum Storage: Hashable {
        case raw(String)
        case key(String)

        func resolved() -> String {
            switch self {
            case .raw(let s): return s
            case .key(let k): return NSLocalizedString(k, comment: "")
            }
        }
    }

    /// Computed so these re-localize on the fly when the user switches language.
    var title: String { titleStorage.resolved() }
    var body:  String { bodyStorage.resolved()  }

    // MARK: Initializers

    /// Raw, non-localized content (used for the azkar — Arabic transliterations).
    init(id: String, category: Category,
         title: String, body: String, source: String? = nil) {
        self.id = id
        self.category = category
        self.titleStorage = .raw(title)
        self.bodyStorage = .raw(body)
        self.source = source
    }

    /// Localized content: looks up `hadith.<id>.title` and `hadith.<id>.body`
    /// in Localizable.strings, so the same pool renders in whichever language
    /// the user has selected.
    init(localizedHadithId id: String, source: String? = nil) {
        self.id = id
        self.category = .hadith
        self.titleStorage = .key("hadith.\(id).title")
        self.bodyStorage = .key("hadith.\(id).body")
        self.source = source
    }

    /// Localized azkar: looks up `azkar.<id>.title` / `azkar.<id>.body`.
    /// Arabic transliteration inside the body is preserved verbatim in every
    /// language — it's the actual remembrance to recite, not flavor text.
    init(localizedAzkarId id: String,
         category: Category,
         source: String? = nil) {
        self.id = id
        self.category = category
        self.titleStorage = .key("azkar.\(id).title")
        self.bodyStorage = .key("azkar.\(id).body")
        self.source = source
    }

    enum Category: String, CaseIterable, Hashable {
        case morning
        case evening
        case afterPrayer
        case hadith

        var localizedTitle: String {
            switch self {
            case .morning:     return NSLocalizedString("reminders.morning", comment: "")
            case .evening:     return NSLocalizedString("reminders.evening", comment: "")
            case .afterPrayer: return NSLocalizedString("reminders.after_prayer", comment: "")
            case .hadith:      return NSLocalizedString("reminders.daily_hadith", comment: "")
            }
        }

        var symbolName: String {
            switch self {
            case .morning:     return "sunrise.fill"
            case .evening:     return "sunset.fill"
            case .afterPrayer: return "hands.sparkles.fill"
            case .hadith:      return "book.closed.fill"
            }
        }
    }
}

enum Hadiths {

    static let all: [Reminder] = morning + evening + afterPrayer + hadiths

    static func byCategory(_ category: Reminder.Category) -> [Reminder] {
        all.filter { $0.category == category }
    }

    // MARK: - Morning azkar

    static let morning: [Reminder] = [
        .init(localizedAzkarId: "m01", category: .morning, source: "An-Nasa'i"),
        .init(localizedAzkarId: "m02", category: .morning, source: "Abu Dawud, At-Tirmidhi"),
        .init(localizedAzkarId: "m03", category: .morning, source: "Muslim"),
        .init(localizedAzkarId: "m04", category: .morning, source: "Al-Bukhari"),
        .init(localizedAzkarId: "m05", category: .morning, source: "Muslim"),
        .init(localizedAzkarId: "m06", category: .morning, source: "An-Nasa'i"),
        .init(localizedAzkarId: "m07", category: .morning, source: "Abu Dawud, At-Tirmidhi"),
        .init(localizedAzkarId: "m08", category: .morning, source: "Abu Dawud"),
        .init(localizedAzkarId: "m09", category: .morning, source: "Abu Dawud"),
        .init(localizedAzkarId: "m10", category: .morning, source: "Abu Dawud"),
        .init(localizedAzkarId: "m11", category: .morning, source: "Ahmad"),
        .init(localizedAzkarId: "m12", category: .morning, source: "At-Tirmidhi"),
        .init(localizedAzkarId: "m13", category: .morning, source: "At-Tirmidhi"),
        .init(localizedAzkarId: "m14", category: .morning, source: "Ibn Majah"),
        .init(localizedAzkarId: "m15", category: .morning, source: "An-Nasa'i"),
        .init(localizedAzkarId: "m16", category: .morning, source: "An-Nasa'i"),
        .init(localizedAzkarId: "m17", category: .morning, source: "At-Tirmidhi"),
        .init(localizedAzkarId: "m18", category: .morning, source: "Al-Bukhari, Muslim"),
        .init(localizedAzkarId: "m19", category: .morning, source: "At-Tabarani"),
    ]

    // MARK: - Evening azkar

    static let evening: [Reminder] = [
        .init(localizedAzkarId: "e01", category: .evening, source: "An-Nasa'i"),
        .init(localizedAzkarId: "e02", category: .evening, source: "Abu Dawud, At-Tirmidhi"),
        .init(localizedAzkarId: "e03", category: .evening, source: "Muslim"),
        .init(localizedAzkarId: "e04", category: .evening, source: "Al-Bukhari"),
        .init(localizedAzkarId: "e05", category: .evening, source: "Muslim"),
        .init(localizedAzkarId: "e06", category: .evening, source: "Al-Bukhari, Muslim"),
        .init(localizedAzkarId: "e07", category: .evening, source: "Al-Bukhari, Muslim"),
        .init(localizedAzkarId: "e08", category: .evening, source: "Abu Dawud"),
        .init(localizedAzkarId: "e09", category: .evening, source: "Al-Bukhari, Muslim"),
        .init(localizedAzkarId: "e10", category: .evening, source: "At-Tirmidhi"),
        .init(localizedAzkarId: "e11", category: .evening, source: "Abu Dawud"),
        .init(localizedAzkarId: "e12", category: .evening, source: "Al-Bukhari"),
        .init(localizedAzkarId: "e13", category: .evening, source: "Al-Bukhari"),
        .init(localizedAzkarId: "e14", category: .evening, source: "Al-Bukhari"),
        .init(localizedAzkarId: "e15", category: .evening, source: "At-Tirmidhi"),
        .init(localizedAzkarId: "e16", category: .evening, source: "At-Tabarani"),
        .init(localizedAzkarId: "e17", category: .evening, source: "At-Tirmidhi"),
        .init(localizedAzkarId: "e18", category: .evening, source: "Ahmad"),
        .init(localizedAzkarId: "e19", category: .evening, source: "Ahmad"),
        .init(localizedAzkarId: "e20", category: .evening, source: "At-Tabarani"),
    ]

    // MARK: - After-prayer dhikr

    static let afterPrayer: [Reminder] = [
        .init(localizedAzkarId: "p01", category: .afterPrayer, source: "Muslim"),
        .init(localizedAzkarId: "p02", category: .afterPrayer, source: "Al-Bukhari, Muslim"),
        .init(localizedAzkarId: "p03", category: .afterPrayer, source: "Al-Bukhari"),
        .init(localizedAzkarId: "p04", category: .afterPrayer, source: "Muslim"),
        .init(localizedAzkarId: "p05", category: .afterPrayer, source: "An-Nasa'i"),
        .init(localizedAzkarId: "p06", category: .afterPrayer, source: "Abu Dawud, At-Tirmidhi"),
        .init(localizedAzkarId: "p07", category: .afterPrayer, source: "Abu Dawud, An-Nasa'i"),
        .init(localizedAzkarId: "p08", category: .afterPrayer, source: "Muslim"),
        .init(localizedAzkarId: "p09", category: .afterPrayer, source: "At-Tirmidhi"),
        .init(localizedAzkarId: "p10", category: .afterPrayer, source: "Ibn Majah"),
        .init(localizedAzkarId: "p11", category: .afterPrayer, source: "Muslim"),
        .init(localizedAzkarId: "p12", category: .afterPrayer, source: "Muslim"),
        .init(localizedAzkarId: "p13", category: .afterPrayer, source: "Al-Bukhari"),
        .init(localizedAzkarId: "p14", category: .afterPrayer, source: "At-Tirmidhi"),
        .init(localizedAzkarId: "p15", category: .afterPrayer, source: "Qur'an 14:41"),
    ]

    // MARK: - General hadith of the day

    /// Sources kept next to each ID so the Reminder struct stays compact; the
    /// title/body are looked up from Localizable.strings at display time.
    /// Collection names are transliterated Arabic — universally recognizable,
    /// so they don't need their own localization entries.
    static let hadiths: [Reminder] = [
        .init(localizedHadithId: "h01",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h02",  source: "Al-Bukhari"),
        .init(localizedHadithId: "h03",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h04",  source: "At-Tirmidhi"),
        .init(localizedHadithId: "h05",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h06",  source: "Muslim"),
        .init(localizedHadithId: "h07",  source: "Al-Bukhari"),
        .init(localizedHadithId: "h08",  source: "At-Tirmidhi"),
        .init(localizedHadithId: "h09",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h10",  source: "Muslim"),
        .init(localizedHadithId: "h11",  source: "Al-Bukhari"),
        .init(localizedHadithId: "h12",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h13",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h14",  source: "Muslim"),
        .init(localizedHadithId: "h15",  source: "Abu Dawud, At-Tirmidhi"),
        .init(localizedHadithId: "h16",  source: "At-Tirmidhi"),
        .init(localizedHadithId: "h17",  source: "Muslim"),
        .init(localizedHadithId: "h18",  source: "Al-Bukhari"),
        .init(localizedHadithId: "h19",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h20",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h21",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h22",  source: "At-Tirmidhi"),
        .init(localizedHadithId: "h23",  source: "At-Tirmidhi"),
        .init(localizedHadithId: "h24",  source: "At-Tirmidhi"),
        .init(localizedHadithId: "h25",  source: "Muslim"),
        .init(localizedHadithId: "h26",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h27",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h28",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h29",  source: "Muslim"),
        .init(localizedHadithId: "h30",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h31",  source: "Muslim"),
        .init(localizedHadithId: "h32",  source: "Abu Dawud, At-Tirmidhi"),
        .init(localizedHadithId: "h33",  source: "Muslim"),
        .init(localizedHadithId: "h34",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h35",  source: "Muslim"),
        .init(localizedHadithId: "h36",  source: "Muslim"),
        .init(localizedHadithId: "h37",  source: "Ibn Majah"),
        .init(localizedHadithId: "h38",  source: "Al-Bukhari"),
        .init(localizedHadithId: "h39",  source: "Muslim"),
        .init(localizedHadithId: "h40",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h41",  source: "Abu Dawud"),
        .init(localizedHadithId: "h42",  source: "At-Tirmidhi, An-Nasa'i"),
        .init(localizedHadithId: "h43",  source: "At-Tirmidhi"),
        .init(localizedHadithId: "h44",  source: "Muslim"),
        .init(localizedHadithId: "h45",  source: "Abu Dawud, Ibn Majah"),
        .init(localizedHadithId: "h46",  source: "Muslim"),
        .init(localizedHadithId: "h47",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h48",  source: "Muslim"),
        .init(localizedHadithId: "h49",  source: "Muslim"),
        .init(localizedHadithId: "h50",  source: "At-Tirmidhi"),
        .init(localizedHadithId: "h51",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h52",  source: "At-Tabarani"),
        .init(localizedHadithId: "h53",  source: "Al-Bukhari"),
        .init(localizedHadithId: "h54",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h55",  source: "At-Tirmidhi"),
        .init(localizedHadithId: "h56",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h57",  source: "Muslim"),
        .init(localizedHadithId: "h58",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h59",  source: "Muslim"),
        .init(localizedHadithId: "h60",  source: "Muslim"),
        .init(localizedHadithId: "h61",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h62",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h63",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h64",  source: "At-Tirmidhi, Abu Dawud"),
        .init(localizedHadithId: "h65",  source: "Ahmad"),
        .init(localizedHadithId: "h66",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h67",  source: "At-Tirmidhi"),
        .init(localizedHadithId: "h68",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h69",  source: "Muslim"),
        .init(localizedHadithId: "h70",  source: "Muslim"),
        .init(localizedHadithId: "h71",  source: "Muslim"),
        .init(localizedHadithId: "h72",  source: "Abu Dawud, Ahmad"),
        .init(localizedHadithId: "h73",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h74",  source: "Muslim"),
        .init(localizedHadithId: "h75",  source: "At-Tirmidhi"),
        .init(localizedHadithId: "h76",  source: "Muslim"),
        .init(localizedHadithId: "h77",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h78",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h79",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h80",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h81",  source: "Ahmad"),
        .init(localizedHadithId: "h82",  source: "Abu Dawud"),
        .init(localizedHadithId: "h83",  source: "At-Tirmidhi"),
        .init(localizedHadithId: "h84",  source: "Al-Bukhari"),
        .init(localizedHadithId: "h85",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h86",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h87",  source: "Muslim"),
        .init(localizedHadithId: "h88",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h89",  source: "Muslim"),
        .init(localizedHadithId: "h90",  source: "Al-Bukhari"),
        .init(localizedHadithId: "h91",  source: "Muslim"),
        .init(localizedHadithId: "h92",  source: "At-Tirmidhi"),
        .init(localizedHadithId: "h93",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h94",  source: "At-Tirmidhi"),
        .init(localizedHadithId: "h95",  source: "At-Tirmidhi"),
        .init(localizedHadithId: "h96",  source: "Al-Bukhari, Muslim"),
        .init(localizedHadithId: "h97",  source: "Muslim"),
        .init(localizedHadithId: "h98",  source: "At-Tirmidhi"),
        .init(localizedHadithId: "h99",  source: "Muslim"),
        .init(localizedHadithId: "h100", source: "At-Tirmidhi"),
    ]
}
