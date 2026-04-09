import SwiftUI

struct ScheduledOrderPickerView: View {
    let schedule: BranchSchedule
    @Binding var selectedDate: Date?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var gradientManager = GradientStateManager.shared

    @State private var selectedDay: Int = 0  // 0 = hoy, 1 = mañana
    @State private var pickerTime: Date = Date()
    @State private var validationError: String? = nil

    private static let havanaTimeZone = TimeZone(identifier: "America/Havana") ?? .current

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Picker("Día", selection: $selectedDay) {
                    Text("Hoy").tag(0)
                    Text("Mañana").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                DatePicker(
                    "Hora",
                    selection: $pickerTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.timeZone, Self.havanaTimeZone)
                .frame(maxWidth: .infinity)

                if let error = validationError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()
            }
            .navigationTitle("Programar pedido")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(gradientManager.currentAccentColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") { confirmSelection() }
                        .fontWeight(.semibold)
                        .foregroundColor(gradientManager.currentAccentColor)
                }
            }
            .onChange(of: pickerTime) { _, _ in validationError = nil }
            .onChange(of: selectedDay) { _, _ in validationError = nil }
            .onAppear { setupInitialState() }
        }
    }

    // MARK: - Setup

    private func setupInitialState() {
        if let existing = selectedDate {
            var cal = makeCal()
            selectedDay = cal.isDateInToday(existing) ? 0 : 1
            pickerTime = existing
        } else {
            // Default: now + 60 min, rounded to next 30 min boundary
            let future = Date().addingTimeInterval(3600)
            var cal = makeCal()
            let m = cal.component(.minute, from: future)
            let snap = m <= 30 ? 30 : 0
            let extraHour = m <= 30 ? 0 : 1
            if let snapped = cal.date(bySetting: .minute, value: snap, of: future),
               let final = cal.date(byAdding: .hour, value: extraHour, to: snapped) {
                pickerTime = final
            } else {
                pickerTime = future
            }
        }
    }

    // MARK: - Confirm

    private func confirmSelection() {
        let cal = makeCal()
        let base = targetDate(dayOffset: selectedDay)
        let h = cal.component(.hour, from: pickerTime)
        let m = cal.component(.minute, from: pickerTime)

        guard let combined = cal.date(bySettingHour: h, minute: m, second: 0, of: base) else {
            validationError = "No se pudo calcular la fecha."
            return
        }

        // At least 60 min in the future
        guard combined > Date().addingTimeInterval(3600) else {
            validationError = "La hora debe estar al menos 60 min en el futuro."
            return
        }

        // Within branch hours
        guard isWithinBranchHours(combined) else {
            validationError = "La tienda está cerrada a esa hora. Elige un horario dentro del horario de atención."
            return
        }

        selectedDate = combined
        dismiss()
    }

    // MARK: - Validation

    private func isWithinBranchHours(_ date: Date) -> Bool {
        if let temp = schedule.temporaryStatus, temp.temporallyClosed { return false }
        let cal = makeCal()
        let weekday = cal.component(.weekday, from: date) - 1
        guard let day = schedule.days.first(where: { $0.day == weekday }), day.isOpen else { return false }
        let mins = cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date)
        for range in day.hours {
            guard let open = parseMinutes(range.open), let close = parseMinutes(range.close) else { continue }
            if mins >= open && mins < close { return true }
        }
        return false
    }

    private func parseMinutes(_ s: String) -> Int? {
        let parts = s.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return parts[0] * 60 + parts[1]
    }

    private func makeCal() -> Calendar {
        var cal = Calendar.current
        cal.timeZone = Self.havanaTimeZone
        return cal
    }

    private func targetDate(dayOffset: Int) -> Date {
        var cal = makeCal()
        return cal.date(byAdding: .day, value: dayOffset, to: cal.startOfDay(for: Date())) ?? Date()
    }
}
