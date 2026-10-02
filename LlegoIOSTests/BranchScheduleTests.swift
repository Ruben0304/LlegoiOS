import XCTest
@testable import LlegoiOS

/// Réplica de las reglas de `LlegoBackend/services/branch_hours.py`: el override
/// diario (`temporaryStatus`) solo aplica el día de su fecha en hora de Cuba y
/// `temporallyOpen` sin horas equivale al horario normal.
final class BranchScheduleTests: XCTestCase {

    // 2026-10-04 es domingo, 2026-10-05 lunes, 2026-10-06 martes.
    private var havana: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Havana")!
        return calendar
    }()

    /// Fecha en hora de Cuba.
    private func at(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        havana.date(
            from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    /// Horario con el lunes abierto en `monday`, el martes opcional y el resto cerrado.
    private func schedule(
        monday: [(String, String)],
        tuesday: [(String, String)]? = nil,
        status: BranchTemporaryStatus? = nil
    ) -> BranchSchedule {
        func ranges(_ pairs: [(String, String)]) -> [TimeRange] {
            pairs.map { TimeRange(open: $0.0, close: $0.1) }
        }
        let days = (0...6).map { day -> DaySchedule in
            switch day {
            case 1: return DaySchedule(day: 1, isOpen: true, hours: ranges(monday))
            case 2:
                return DaySchedule(
                    day: 2, isOpen: tuesday != nil, hours: ranges(tuesday ?? []))
            default: return DaySchedule(day: day, isOpen: false, hours: [])
            }
        }
        return BranchSchedule(days: days, temporaryStatus: status)
    }

    private func status(
        closed: Bool = false, open: Bool = false, reason: String? = nil,
        date: String? = nil, openTime: String? = nil, closeTime: String? = nil
    ) -> BranchTemporaryStatus {
        BranchTemporaryStatus(
            temporallyClosed: closed, temporallyOpen: open, reason: reason,
            date: date, openTime: openTime, closeTime: closeTime)
    }

    // MARK: - Horario semanal

    func test_weekly_openInsideHoursAndClosedOutside() {
        let s = schedule(monday: [("08:00", "20:00")])
        XCTAssertTrue(s.isOpen(at: at(2026, 10, 5, 12)))
        XCTAssertTrue(s.isOpen(at: at(2026, 10, 5, 8, 0)))
        XCTAssertFalse(s.isOpen(at: at(2026, 10, 5, 7, 59)))
        XCTAssertFalse(s.isOpen(at: at(2026, 10, 5, 20, 0)), "el cierre es exclusivo")
        XCTAssertFalse(s.isOpen(at: at(2026, 10, 6, 12)), "el martes está cerrado")
    }

    func test_weekly_overnightShiftSpillsIntoNextMorning() {
        let s = schedule(monday: [("22:00", "02:00")])
        XCTAssertTrue(s.isOpen(at: at(2026, 10, 5, 23)))
        XCTAssertTrue(s.isOpen(at: at(2026, 10, 6, 1)), "la cola del turno llega al martes")
        XCTAssertFalse(s.isOpen(at: at(2026, 10, 6, 2)))
        XCTAssertFalse(s.isOpen(at: at(2026, 10, 5, 1)), "el domingo no abre")
        XCTAssertFalse(s.isOpen(at: at(2026, 10, 5, 12)))
    }

    func test_weekly_midnightClosingAndEmptyRanges() {
        XCTAssertTrue(
            schedule(monday: [("00:00", "24:00")]).isOpen(at: at(2026, 10, 5, 23, 59)))
        XCTAssertFalse(
            schedule(monday: [("10:00", "10:00")]).isOpen(at: at(2026, 10, 5, 10)),
            "apertura igual al cierre nunca abre")
        XCTAssertFalse(
            BranchSchedule(days: [], temporaryStatus: nil).isOpen(at: at(2026, 10, 5, 12)))
    }

    func test_weekdayAndMinutesUseHavanaNotDeviceTimeZone() {
        // Lunes 23:30 en Cuba ya es martes en UTC; "hoy" sigue siendo lunes.
        let date = at(2026, 10, 5, 23, 30)
        XCTAssertEqual(BranchHours.localDay(of: date).weekday, 1)
        XCTAssertEqual(BranchHours.localMinutes(of: date), 23 * 60 + 30)
    }

    // MARK: - Override con fecha

    func test_dateOverride_closedToday_appliesOnlyThatDay() {
        let s = schedule(
            monday: [("08:00", "20:00")],
            status: status(closed: true, reason: "Duelo", date: "2026-10-05"))

        XCTAssertFalse(s.isOpen(at: at(2026, 10, 5, 12)))
        XCTAssertNotNil(s.applicableTemporaryStatus(at: at(2026, 10, 5, 12)))
        if case .temporarilyClosed(let reason) = s.currentStatus(at: at(2026, 10, 5, 12)) {
            XCTAssertEqual(reason, "Duelo")
        } else {
            XCTFail("debía estar cerrada temporalmente")
        }

        // El lunes siguiente el override (de otra fecha) se ignora y manda el semanal.
        XCTAssertTrue(s.isOpen(at: at(2026, 10, 12, 12)))
        XCTAssertNil(s.applicableTemporaryStatus(at: at(2026, 10, 12, 12)))
        if case .openNow = s.currentStatus(at: at(2026, 10, 12, 12)) {
        } else {
            XCTFail("debía estar abierta con el horario normal")
        }
    }

    func test_dateOverride_ofYesterdayIsIgnored() {
        let s = schedule(
            monday: [("08:00", "20:00")], status: status(closed: true, date: "2026-10-04"))
        XCTAssertTrue(s.isOpen(at: at(2026, 10, 5, 12)))
    }

    func test_dateOverride_closedTodayStaysClosedLateAtNight() {
        // Lunes 23:30 Cuba: la fecha del override se compara en hora de Cuba, no en UTC.
        let s = schedule(
            monday: [("08:00", "24:00")], status: status(closed: true, date: "2026-10-05"))
        XCTAssertFalse(s.isOpen(at: at(2026, 10, 5, 23, 30)))
    }

    func test_dateOverride_unreadableDateNeverApplies() {
        for bad in ["2026-02-30", "26-10-05", "abc", "2026/10/05", "2026-13-01", "0000-01-01"] {
            let s = schedule(
                monday: [("08:00", "20:00")], status: status(closed: true, date: bad))
            XCTAssertTrue(s.isOpen(at: at(2026, 10, 5, 12)), "fecha ilegible \(bad)")
        }
    }

    func test_undatedOverride_isLegacyAndAppliesAlways() {
        let s = schedule(
            monday: [("08:00", "20:00")], status: status(closed: true, reason: "Cerrado"))
        XCTAssertFalse(s.isOpen(at: at(2026, 10, 5, 12)))
        XCTAssertFalse(s.isOpen(at: at(2026, 10, 12, 12)))

        let blankDate = schedule(
            monday: [("08:00", "20:00")], status: status(closed: true, date: "  "))
        XCTAssertFalse(blankDate.isOpen(at: at(2026, 10, 5, 12)))
    }

    // MARK: - Horario especial y temporallyOpen

    func test_specialHours_replaceWeeklyHoursThatDay() {
        let s = schedule(
            monday: [("08:00", "20:00")],
            status: status(
                open: true, reason: "Feriado", date: "2026-10-05",
                openTime: "10:00", closeTime: "12:00"))

        XCTAssertTrue(s.isOpen(at: at(2026, 10, 5, 11)))
        XCTAssertFalse(s.isOpen(at: at(2026, 10, 5, 13)), "fuera del horario especial")
        XCTAssertFalse(s.isOpen(at: at(2026, 10, 5, 9)))
        if case .temporarilyOpen(let reason) = s.currentStatus(at: at(2026, 10, 5, 11)) {
            XCTAssertEqual(reason, "Feriado")
        } else {
            XCTFail("debía estar abierta por horario especial")
        }
        if case .closedNow = s.currentStatus(at: at(2026, 10, 5, 13)) {
        } else {
            XCTFail("fuera del horario especial debía estar cerrada")
        }
        XCTAssertEqual(
            s.applicableTemporaryStatus(at: at(2026, 10, 5, 11))?.specialHoursLabel,
            "10:00 – 12:00")
    }

    func test_specialHours_canOpenADayClosedInTheWeeklySchedule() {
        let s = schedule(
            monday: [("08:00", "20:00")],
            status: status(date: "2026-10-06", openTime: "10:00", closeTime: "12:00"))
        XCTAssertTrue(s.isOpen(at: at(2026, 10, 6, 11)))
    }

    func test_temporallyOpenWithoutHours_meansNormalSchedule() {
        let s = schedule(
            monday: [("08:00", "20:00")], status: status(open: true, date: "2026-10-05"))
        XCTAssertFalse(s.isOpen(at: at(2026, 10, 5, 22)), "no abre fuera del horario normal")
        XCTAssertTrue(s.isOpen(at: at(2026, 10, 5, 12)))
        if case .closedNow = s.currentStatus(at: at(2026, 10, 5, 22)) {
        } else {
            XCTFail("debía estar cerrada con el horario normal")
        }
        if case .openNow = s.currentStatus(at: at(2026, 10, 5, 12)) {
        } else {
            XCTFail("debía estar abierta con el horario normal")
        }
    }

    func test_incompleteSpecialHours_doNotDecide() {
        let s = schedule(
            monday: [("08:00", "20:00")],
            status: status(open: true, date: "2026-10-05", openTime: "10:00"))
        XCTAssertTrue(s.isOpen(at: at(2026, 10, 5, 9)), "manda el horario semanal")
    }

    // MARK: - Pedidos programados

    func test_scheduledOrder_dateOverrideOnlyBlocksItsOwnDay() {
        let s = schedule(
            monday: [("08:00", "20:00")], tuesday: [("08:00", "20:00")],
            status: status(closed: true, date: "2026-10-05"))
        XCTAssertFalse(s.isOpenForScheduledOrder(at: at(2026, 10, 5, 12)))
        XCTAssertTrue(s.isOpenForScheduledOrder(at: at(2026, 10, 6, 12)))
    }

    func test_scheduledOrder_ignoresUndatedOverride() {
        let s = schedule(monday: [("08:00", "20:00")], status: status(closed: true))
        XCTAssertTrue(s.isOpenForScheduledOrder(at: at(2026, 10, 5, 12)))
    }

    func test_scheduledOrder_endIsExclusive() {
        let s = schedule(monday: [("08:00", "20:00")])
        XCTAssertTrue(s.isOpenForScheduledOrder(at: at(2026, 10, 5, 8, 0)))
        XCTAssertFalse(s.isOpenForScheduledOrder(at: at(2026, 10, 5, 20, 0)))
    }

    // MARK: - Parseo

    func test_parseMinutes() {
        XCTAssertEqual(BranchHours.parseMinutes("24:00"), 1440)
        XCTAssertEqual(BranchHours.parseMinutes("9:30"), 570)
        XCTAssertEqual(BranchHours.parseMinutes("09:30"), 570)
        XCTAssertEqual(BranchHours.parseMinutes("00:00"), 0)
        XCTAssertEqual(BranchHours.parseMinutes(" 10:00 "), 600)
        for invalid in ["25:00", "24:01", "12:5", "12:60", "", "10:00:00", "1a:00"] {
            XCTAssertNil(BranchHours.parseMinutes(invalid), invalid)
        }
        XCTAssertNil(BranchHours.parseMinutes(nil))
    }
}
