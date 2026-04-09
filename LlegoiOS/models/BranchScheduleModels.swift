import Foundation

// MARK: - UI Models

struct BranchSchedule: Sendable {
    let days: [DaySchedule]
    let temporaryStatus: BranchTemporaryStatus?
}

struct DaySchedule: Sendable {
    /// 0 = Sunday, 1 = Monday, ..., 6 = Saturday (same as Calendar.weekday - 1)
    let day: Int
    let isOpen: Bool
    let hours: [TimeRange]
}

struct TimeRange: Sendable {
    let open: String   // "HH:MM" 24h
    let close: String  // "HH:MM" 24h
}

struct BranchTemporaryStatus: Sendable {
    let temporallyClosed: Bool
    let temporallyOpen: Bool
    let reason: String?
}

// MARK: - Open/Closed Logic

enum BranchOpenStatus: Sendable {
    case openNow
    case closedNow
    case temporarilyClosed(reason: String?)
    case temporarilyOpen(reason: String?)
}

extension BranchSchedule {
    func currentStatus(at date: Date = Date()) -> BranchOpenStatus {
        // 1. Temporary status takes absolute priority
        if let temp = temporaryStatus {
            if temp.temporallyClosed {
                return .temporarilyClosed(reason: temp.reason)
            }
            if temp.temporallyOpen {
                return .temporarilyOpen(reason: temp.reason)
            }
        }

        // 2. Find today's schedule (day: 0=Sun, 1=Mon, ..., 6=Sat)
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date) - 1  // Convert 1-based to 0-based

        guard let todaySchedule = days.first(where: { $0.day == weekday }) else {
            return .closedNow
        }

        // 3. Closed day or no hours defined
        guard todaySchedule.isOpen, !todaySchedule.hours.isEmpty else {
            return .closedNow
        }

        // 4. Check if current time falls within any range
        let currentMinutes = minutesFromMidnight(date: date, calendar: calendar)

        for range in todaySchedule.hours {
            if isWithinRange(currentMinutes: currentMinutes, open: range.open, close: range.close) {
                return .openNow
            }
        }

        return .closedNow
    }

    /// Converts "HH:MM" string to minutes from midnight
    private func parseMinutes(_ timeString: String) -> Int? {
        let parts = timeString.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return parts[0] * 60 + parts[1]
    }

    private func minutesFromMidnight(date: Date, calendar: Calendar) -> Int {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return hour * 60 + minute
    }

    /// Handles ranges that cross midnight (e.g. "22:00" - "02:00")
    private func isWithinRange(currentMinutes: Int, open: String, close: String) -> Bool {
        guard let openMin = parseMinutes(open), let closeMin = parseMinutes(close) else {
            return false
        }

        if closeMin > openMin {
            // Normal range: e.g. 08:00 - 20:00
            return currentMinutes >= openMin && currentMinutes < closeMin
        } else {
            // Crosses midnight: e.g. 22:00 - 02:00
            return currentMinutes >= openMin || currentMinutes < closeMin
        }
    }
}

// MARK: - Display Helpers

extension BranchOpenStatus {
    var isOpen: Bool {
        switch self {
        case .openNow, .temporarilyOpen: return true
        case .closedNow, .temporarilyClosed: return false
        }
    }

    var label: String {
        switch self {
        case .openNow:
            return "Abierto"
        case .closedNow:
            return "Cerrado"
        case .temporarilyClosed(let reason):
            if let reason = reason, !reason.isEmpty {
                return "Cerrado · \(reason)"
            }
            return "Cerrado temporalmente"
        case .temporarilyOpen(let reason):
            if let reason = reason, !reason.isEmpty {
                return "Abierto · \(reason)"
            }
            return "Abierto temporalmente"
        }
    }
}
