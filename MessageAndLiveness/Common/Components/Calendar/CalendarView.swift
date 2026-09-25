import SwiftUI

struct CalendarView: View {
	@Binding var leaveDate: [Int]
	@Binding var selectedDates: [Date]
	@Binding var calendarDates: [Date]
	@State private var currentMonth: Date = .now
	
	private let calendar = Calendar(identifier: .gregorian)
	private let dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "LLLL yyyy"
		return formatter
	}()
	
	var body: some View {
		VStack(spacing: 16) {
			// Month-Year Header with arrows
			HStack {
				Button(action: previousMonth) {
					Image(.prevMonthIcon)
						.resizable()
						.scaledToFit()
						.frame(width: 24)
						.padding(.horizontal)
				}
				
				Spacer()
				
				Text(dateFormatter.string(from: currentMonth))
					.font(.baseStyle(size: 14, weight: .bold))
					.foregroundStyle(.neutral90)
				
				Spacer()
				
				Button(action: nextMonth) {
					Image(.nextMonthIcon)
						.resizable()
						.scaledToFit()
						.frame(width: 24)
						.padding(.horizontal)
				}
			}
			.padding(.bottom)
			
			// Weekday Headers
			let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
			LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
				ForEach(weekdays, id: \.self) { day in
					Text(day)
						.font(.baseStyle(size: 12, weight: .bold))
						.foregroundStyle(.neutral90)
				}
			}
			
			// Dates Grid
			LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 5) {
				ForEach(calendarDates, id: \.self) { date in
					Button {
						handleDateTap(date)
					} label: {
						CalendarDateCell(
							date: date,
							leaveDate: $leaveDate,
							selectedDates: $selectedDates,
							currentMonth: currentMonth
						)
					}
					.disabled(isWeekend(date))
					.buttonStyle(.plain)
				}
			}
		}
		.onAppear {
			generateDates(for: currentMonth)
			guard let date = selectedDates.first, selectedDates.count <= 1 else { return }
			handleDateTap(date)
		}
	}
	
	private func isWeekend(_ date: Date) -> Bool {
		let weekday = calendar.component(.weekday, from: date)
		return weekday == 1 || weekday == 7
	}

	// MARK: - Navigation
	private func nextMonth() {
		if let next = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
			currentMonth = next
			generateDates(for: next)
		}
	}
	
	private func handleDateTap(_ tappedDate: Date) {
		let selectedDay = calendar.startOfDay(for: tappedDate)
		
		if selectedDates.isEmpty {
			selectedDates = [selectedDay]
		} else if selectedDates.count == 1 {
			let first = selectedDates[0]
			let second = selectedDay
			
			let range = generateDateRange(from: first, to: second)
			selectedDates = range
		} else if selectedDates.first == selectedDay && selectedDates.count == 1 {
			selectedDates = []
		} else {
			// Reset
			selectedDates = [selectedDay]
		}
	}
	
	private func generateDateRange(from startDate: Date, to endDate: Date) -> [Date] {
		let start = min(startDate, endDate)
		let end = max(startDate, endDate)
		
		var dates: [Date] = []
		var current = start
		
		while current <= end {
			let weekday = calendar.component(.weekday, from: current)
			
			if weekday != 1 && weekday != 7 {
				dates.append(current)
			}
			
			guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
			current = next
		}
		
		return dates
	}
	
	private func previousMonth() {
		if let previous = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
			currentMonth = previous
			generateDates(for: previous)
		}
	}
	
	// MARK: - Date Generation
	private func generateDates(for month: Date) {
		calendarDates.removeAll()
		
		let components = calendar.dateComponents([.year, .month], from: month)
		guard let startOfMonth = calendar.date(from: components) else { return }
		
		guard let range = calendar.range(of: .day, in: .month, for: startOfMonth) else { return }
		let numDays = range.count

		let firstWeekday = calendar.component(.weekday, from: startOfMonth)
		let offset = (firstWeekday + 5) % 7 // Make it start on Monday

		// Add leading empty days from previous month
		for idx in 0..<offset {
			guard let date = calendar.date(byAdding: .day, value: idx - offset, to: startOfMonth) else { continue }
			calendarDates.append(date)
		}

		// Add actual month days
		for day in 0..<numDays {
			guard let date = calendar.date(byAdding: .day, value: day, to: startOfMonth) else { continue }
			calendarDates.append(date)
		}
	}
}

struct CalendarDateCell: View {
	let date: Date
	@Binding var leaveDate: [Int]
	@Binding var selectedDates: [Date]
	let currentMonth: Date
	
	private let calendar = Calendar(identifier: .gregorian)
	
	var body: some View {
		let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
		let isSelected = selectedDates.contains(calendar.startOfDay(for: date))
		let day = calendar.component(.day, from: date)
		let isSunday = calendar.component(.weekday, from: date) == 1
		let isSaturday = calendar.component(.weekday, from: date) == 7
		
		if isCurrentMonth {
			Text("\(day)")
				.font(.system(size: 14, weight: .regular))
				.frame(width: 30, height: 30)
				.foregroundStyle(dateColor())
				.background(
					ZStack {
						if isSelected {
							if leaveDate.contains(day) {
								Circle().fill(Color(.dangerMain))
							} else {
								Circle().fill(Color(.brandSecondary))
							}
						} else if leaveDate.contains(day) && isCurrentMonth {
							Circle().fill(Color(.dangerSurface))
						} else if isSunday || isSaturday {
							Circle().fill(Color(.neutral30))
						}
					}
				)
				.overlay {
					if leaveDate.contains(day) && isCurrentMonth {
						Circle().stroke(Color(.dangerMain), lineWidth: 1)
					}
				}
		} else {
			Rectangle()
				.foregroundStyle(.white)
		}
	}
	
	func dateColor() -> Color {
		let isSelected = selectedDates.contains(calendar.startOfDay(for: date))
		let day = calendar.component(.day, from: date)
		let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
		
		if isSelected {
			return Color.white
		} else if leaveDate.contains(day) && isCurrentMonth {
			return Color(.dangerMain)
		} else {
			return Color(.neutral90)
		}
	}
}

#Preview {
	CalendarView(
		leaveDate: .constant([]),
		selectedDates: .constant([Date()]),
		calendarDates: .constant(
			(0..<28)
				.compactMap { Calendar.current.date(byAdding: .day, value: $0, to: Date()) }
		)
	)
}
