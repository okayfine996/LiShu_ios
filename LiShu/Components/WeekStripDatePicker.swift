import SwiftUI

struct WeekStripDatePicker: View {
    @Binding var selectedDate: Date
    @State private var currentWeekStart: Date
    @State private var showFullCalendar = true

    private let calendar = Calendar.current

    init(selectedDate: Binding<Date>) {
        _selectedDate = selectedDate
        let date = selectedDate.wrappedValue
        let weekday = Calendar.current.component(.weekday, from: date)
        let daysToMonday = (weekday + 5) % 7
        let startOfWeek = Calendar.current.date(byAdding: .day, value: -daysToMonday, to: date) ?? date
        _currentWeekStart = State(initialValue: Calendar.current.startOfDay(for: startOfWeek))
        _displayedMonth = State(initialValue: date)
    }

    private var weekDays: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: currentWeekStart) }
    }

    private var monthYearTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: showFullCalendar ? displayedMonth : currentWeekStart)
    }

    @State private var displayedMonth: Date

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    withAnimation {
                        if showFullCalendar {
                            shiftMonth(by: -1)
                        } else {
                            shiftWeek(by: -1)
                        }
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        if !showFullCalendar {
                            displayedMonth = selectedDate
                        }
                        showFullCalendar.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(monthYearTitle)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                            .fontWeight(.semibold)

                        Image(systemName: showFullCalendar ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    withAnimation {
                        if showFullCalendar {
                            shiftMonth(by: 1)
                        } else {
                            shiftWeek(by: 1)
                        }
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }

            if showFullCalendar {
                monthCalendarView
            } else {
                weekStripView
            }
        }
        .padding(12)
        .background(DesignSystem.Colors.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
    }

    // MARK: - Week Strip

    private var weekStripView: some View {
        HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { day in
                dayCell(day)
            }
        }
    }

    // MARK: - Full Month Calendar

    private var monthCalendarView: some View {
        let weeks = calendarWeeks(for: displayedMonth)
        let weekdaySymbols = shortWeekdaySymbols()

        return VStack(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            ForEach(weeks, id: \.self) { week in
                HStack(spacing: 0) {
                    ForEach(week, id: \.self) { day in
                        if let day {
                            dayCell(day)
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Shared Day Cell

    private func dayCell(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(day)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDate = day
                syncWeekStart(to: day)
            }
        } label: {
            VStack(spacing: showFullCalendar ? 0 : 4) {
                if !showFullCalendar {
                    Text(weekdayAbbrev(day))
                        .font(DesignSystem.Typography.small)
                        .foregroundStyle(isSelected ? DesignSystem.Colors.textOnPrimary : DesignSystem.Colors.textTertiary)
                }

                Text(dayNumber(day))
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundStyle(
                        isSelected
                            ? DesignSystem.Colors.textOnPrimary
                            : (isToday ? DesignSystem.Colors.primary : DesignSystem.Colors.textPrimary)
                    )
            }
            .frame(maxWidth: .infinity)
            .frame(height: showFullCalendar ? 36 : nil)
            .padding(.vertical, showFullCalendar ? 0 : 8)
            .background(
                isSelected
                    ? DesignSystem.Colors.primary
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.input))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func shiftWeek(by weeks: Int) {
        if let newStart = calendar.date(byAdding: .weekOfYear, value: weeks, to: currentWeekStart) {
            currentWeekStart = newStart
        }
    }

    private func shiftMonth(by months: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: months, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    private func syncWeekStart(to date: Date) {
        let weekday = calendar.component(.weekday, from: date)
        let daysToMonday = (weekday + 5) % 7
        if let start = calendar.date(byAdding: .day, value: -daysToMonday, to: date) {
            currentWeekStart = calendar.startOfDay(for: start)
        }
    }

    private func calendarWeeks(for referenceDate: Date) -> [[Date?]] {
        let components = calendar.dateComponents([.year, .month], from: referenceDate)
        guard let firstOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth)
        else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingEmpty = (firstWeekday + 5) % 7

        var days: [Date?] = Array(repeating: nil, count: leadingEmpty)
        for day in range {
            if let date = calendar.date(bySetting: .day, value: day, of: firstOfMonth) {
                days.append(date)
            }
        }
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<min($0 + 7, days.count)]) }
    }

    private func shortWeekdaySymbols() -> [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        let symbols = formatter.shortWeekdaySymbols ?? []
        return Array(symbols[1...]) + [symbols[0]]
    }

    private func weekdayAbbrev(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

#Preview {
    WeekStripDatePicker(selectedDate: .constant(Date()))
        .padding()
        .background(DesignSystem.Colors.bgPage)
}
