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

/// Override diario del horario (`temporaryStatus` del backend).
///
/// Con `date` aplica solo ese día en hora de Cuba; sin `date` (legacy) aplica siempre.
/// Qué decide (ver `BranchHours`): `temporallyClosed` cierra el día; `openTime` y
/// `closeTime` válidos fijan un horario especial; `temporallyOpen` por sí solo no
/// decide nada y manda el horario semanal.
struct BranchTemporaryStatus: Sendable {
    let temporallyClosed: Bool
    let temporallyOpen: Bool
    let reason: String?
    /// YYYY-MM-DD (hora de Cuba) del día al que aplica; nil en overrides legacy.
    let date: String?
    /// Horario especial "HH:MM" 24h de ese día.
    let openTime: String?
    let closeTime: String?

    init(
        temporallyClosed: Bool, temporallyOpen: Bool, reason: String?,
        date: String? = nil, openTime: String? = nil, closeTime: String? = nil
    ) {
        self.temporallyClosed = temporallyClosed
        self.temporallyOpen = temporallyOpen
        self.reason = reason
        self.date = date
        self.openTime = openTime
        self.closeTime = closeTime
    }

    /// Horario especial del día (apertura, cierre) en minutos desde medianoche, si es válido.
    var specialHours: (start: Int, end: Int)? {
        guard let start = BranchHours.parseMinutes(openTime),
            let end = BranchHours.parseMinutes(closeTime)
        else { return nil }
        return (start, end)
    }

    /// "10:00 – 14:00" para mostrar el horario especial del día, si es válido.
    var specialHoursLabel: String? {
        guard let hours = specialHours else { return nil }
        return "\(BranchHours.formatMinutes(hours.start)) – \(BranchHours.formatMinutes(hours.end))"
    }
}

// MARK: - Open/Closed Logic

enum BranchOpenStatus: Sendable {
    case openNow
    case closedNow
    case temporarilyClosed(reason: String?)
    case temporarilyOpen(reason: String?)
}

/// Reglas de apertura de una sucursal.
///
/// Réplica en Swift de `LlegoBackend/services/branch_hours.py` y de
/// `OrderService._is_branch_open_now/_is_branch_open_at`, para que la app no
/// muestre abierta una tienda que el backend rechaza (ni al revés):
///
/// - "Hoy", el día de la semana y la hora se interpretan siempre en
///   America/Havana, nunca en la zona del dispositivo (quien pide desde fuera
///   de Cuba ve el horario de la tienda).
/// - Un override con `date` solo aplica ese día; otro día se ignora y manda el
///   horario semanal. Una fecha ilegible no aplica nunca. Sin `date` (legacy)
///   aplica siempre, salvo al validar pedidos programados.
/// - Cuando aplica decide así: `temporallyClosed` cierra todo el día; si no,
///   `openTime` y `closeTime` válidos dan un horario especial (si el cierre es
///   menor que la apertura cruza la medianoche); si no, no decide y manda el
///   horario semanal (`temporallyOpen` sin horas equivale al horario normal).
enum BranchHours {
    /// Todas las sucursales están en Cuba.
    static let timeZone = TimeZone(identifier: "America/Havana") ?? .current
    static let minutesPerDay = 24 * 60

    /// Día local de Cuba (año, mes, día y día de la semana 0 = domingo).
    struct LocalDay: Equatable, Sendable {
        let year: Int
        let month: Int
        let day: Int
        /// 0 = domingo ... 6 = sábado, igual que `DaySchedule.day`.
        let weekday: Int
    }

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    static func localDay(of date: Date) -> LocalDay {
        let parts = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
        return LocalDay(
            year: parts.year ?? 0, month: parts.month ?? 0, day: parts.day ?? 0,
            weekday: (parts.weekday ?? 1) - 1
        )
    }

    /// Minutos desde medianoche, hora de Cuba.
    static func localMinutes(of date: Date) -> Int {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    /// El día anterior al de `date` en Cuba.
    static func previousDay(of date: Date) -> LocalDay {
        let previous = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        return localDay(of: previous)
    }

    /// "HH:MM" 24 h a minutos desde medianoche. "24:00" vale 1440. nil si es inválida.
    static func parseMinutes(_ value: String?) -> Int? {
        guard let raw = value?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        let parts = raw.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2,
            (1...2).contains(parts[0].count), parts[1].count == 2,
            parts.allSatisfy({ $0.allSatisfy(\.isASCII) && $0.allSatisfy(\.isNumber) }),
            let hour = Int(parts[0]), let minute = Int(parts[1])
        else { return nil }

        if hour == 24 && minute == 0 { return minutesPerDay }
        guard (0...23).contains(hour), (0...59).contains(minute) else { return nil }
        return hour * 60 + minute
    }

    /// Minutos desde medianoche a "HH:MM".
    static func formatMinutes(_ minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }

    /// "YYYY-MM-DD" a (año, mes, día). nil si falta o no es una fecha real.
    static func parseOverrideDate(_ value: String?) -> (year: Int, month: Int, day: Int)? {
        guard let raw = value?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        let parts = raw.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
            parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
            parts.allSatisfy({ $0.allSatisfy(\.isASCII) && $0.allSatisfy(\.isNumber) }),
            let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]),
            year >= 1
        else { return nil }

        // Descarta fechas que no existen (2026-02-30) comprobando que el calendario
        // devuelva los mismos componentes.
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(identifier: "UTC") ?? .current
        let components = DateComponents(year: year, month: month, day: day)
        guard let date = gregorian.date(from: components) else { return nil }
        let check = gregorian.dateComponents([.year, .month, .day], from: date)
        guard check.year == year, check.month == month, check.day == day else { return nil }
        return (year, month, day)
    }
}

extension BranchTemporaryStatus {
    /// ¿Trae fecha? (los legacy no).
    fileprivate var isDated: Bool {
        !(date ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// ¿El override aplica en `day` (fecha local de Cuba)?
    ///
    /// Un override con fecha ilegible no aplica nunca: es preferible ignorarlo a dejar
    /// la tienda cerrada (o abierta) indefinidamente.
    func applies(on day: BranchHours.LocalDay, includeUndated: Bool = true) -> Bool {
        guard isDated else { return includeUndated }
        guard let parsed = BranchHours.parseOverrideDate(date) else { return false }
        return parsed.year == day.year && parsed.month == day.month && parsed.day == day.day
    }

    /// Rangos de apertura que impone el override para su día (sin mirar la fecha):
    /// `[]` cerrada todo el día, `[(inicio, fin)]` horario especial, `nil` no decide.
    fileprivate var dayRanges: [(Int, Int)]? {
        if temporallyClosed { return [] }
        if let hours = specialHours { return [(hours.start, hours.end)] }
        // temporallyOpen sin horas no decide: manda el horario semanal.
        return nil
    }
}

extension BranchSchedule {
    /// Rangos del horario semanal para el día de la semana de `day`.
    private func weeklyRanges(on day: BranchHours.LocalDay) -> [(Int, Int)] {
        guard let schedule = days.first(where: { $0.day == day.weekday }), schedule.isOpen else {
            return []
        }
        return schedule.hours.compactMap { range in
            guard let start = BranchHours.parseMinutes(range.open),
                let end = BranchHours.parseMinutes(range.close)
            else { return nil }
            return (start, end)
        }
    }

    /// Rangos que impone el override si aplica en `day`, o nil.
    private func overrideRanges(on day: BranchHours.LocalDay, includeUndated: Bool) -> [(Int, Int)]? {
        guard let status = temporaryStatus,
            status.applies(on: day, includeUndated: includeUndated)
        else { return nil }
        return status.dayRanges
    }

    /// Rangos de apertura reales de un día: el override si aplica, si no el semanal.
    private func effectiveRanges(on day: BranchHours.LocalDay, includeUndated: Bool = true)
        -> [(Int, Int)]
    {
        overrideRanges(on: day, includeUndated: includeUndated) ?? weeklyRanges(on: day)
    }

    /// Override que aplica hoy (hora de Cuba), para mostrarlo en la UI. nil si no hay
    /// o si es de otra fecha.
    func applicableTemporaryStatus(at date: Date = Date()) -> BranchTemporaryStatus? {
        guard let status = temporaryStatus,
            status.applies(on: BranchHours.localDay(of: date))
        else { return nil }
        return status
    }

    /// ¿Está abierta la sucursal ahora? (`OrderService._is_branch_open_now`)
    ///
    /// "Cerrado hoy" cierra el día entero, incluida la cola de un turno nocturno de
    /// ayer. Un turno que cruza la medianoche (22:00-02:00) cuenta para la madrugada
    /// del día siguiente.
    func isOpen(at date: Date = Date()) -> Bool {
        let current = BranchHours.localMinutes(of: date)
        let today = BranchHours.localDay(of: date)

        if let closedToday = overrideRanges(on: today, includeUndated: true), closedToday.isEmpty {
            return false
        }

        for (start, end) in effectiveRanges(on: today) {
            if start == 0 && end == BranchHours.minutesPerDay { return true }
            if start < end && start <= current && current < end { return true }
            if start > end && current >= start { return true }  // inicio de turno nocturno
        }

        // Turnos nocturnos que vienen de ayer (p. ej. 22:00-02:00).
        for (start, end) in effectiveRanges(on: BranchHours.previousDay(of: date))
        where start > end && current < end {
            return true
        }

        return false
    }

    /// ¿Está abierta a la hora de un pedido programado? (`OrderService._is_branch_open_at`)
    ///
    /// Aquí el override solo cuenta si tiene fecha y es la del día programado ("cerrado
    /// hoy" bloquea un pedido para hoy, no uno para mañana); los legacy sin fecha se
    /// ignoran.
    func isOpenForScheduledOrder(at date: Date) -> Bool {
        let target = BranchHours.localMinutes(of: date)
        let ranges = effectiveRanges(on: BranchHours.localDay(of: date), includeUndated: false)

        for (start, end) in ranges {
            if start == 0 && end == BranchHours.minutesPerDay { return true }
            if start < end && start <= target && target < end { return true }
            if start > end && (target >= start || target < end) { return true }
        }
        return false
    }

    func currentStatus(at date: Date = Date()) -> BranchOpenStatus {
        let open = isOpen(at: date)

        guard let status = applicableTemporaryStatus(at: date) else {
            return open ? .openNow : .closedNow
        }
        if status.temporallyClosed {
            return .temporarilyClosed(reason: status.reason)
        }
        if status.specialHours != nil {
            return open ? .temporarilyOpen(reason: status.reason) : .closedNow
        }
        // temporallyOpen sin horas: no decide, manda el horario normal.
        return open ? .openNow : .closedNow
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
