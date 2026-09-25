import SwiftUI

struct SingleDatePickerView: View {
	@Binding var selection: Date
	let range: ClosedRange<Date>
	let onDoneTapped: () -> Void
	
	var body: some View {
		VStack {
			DatePicker(
				"Select Date",
				selection: $selection,
				in: range,
				displayedComponents: [.date]
			)
			.tint(Color.brandSecondary)
			.datePickerStyle(.graphical)
			.labelsHidden()
			.padding()
			
			PrimaryButton {
				onDoneTapped()
			} label: {
				Text("Done")
			}
			.padding(.bottom)
		}
		.padding()
	}
}

#Preview("Single Date Picker") {
	SingleDatePickerView(
		selection: .constant(Date.now),
		range: {
			let start = Calendar.current.date(byAdding: .year, value: -1, to: Date.now)!
			let end = Calendar.current.date(byAdding: .year, value: 1, to: Date.now)!
			return start...end
		}(),
		onDoneTapped: {}
	)
}

private struct SingleDatePickerPreviewSheet: View {
	@State private var selectedDate = Date.now
	@State private var showSheet = false
	
	private var dateRange: ClosedRange<Date> {
		let start = Calendar.current.date(byAdding: .year, value: -1, to: Date.now)!
		let end = Calendar.current.date(byAdding: .year, value: 1, to: Date.now)!
		return start...end
	}
	
	var body: some View {
		VStack(spacing: 20) {
			Text("Selected date:")
				.font(.subheadline)
			
			Text(selectedDate.formatted(date: .long, time: .omitted))
				.font(.headline)
			
			PrimaryButton {
				showSheet = true
			} label: {
				Text("Show Date Picker")
			}
		}
		.padding()
		.sheet(isPresented: $showSheet) {
			SingleDatePickerView(
				selection: $selectedDate,
				range: dateRange,
				onDoneTapped: {
					showSheet = false
				}
			)
			.presentationDetents([.medium])
		}
	}
}

#Preview("Sheet Presentation") {
	SingleDatePickerPreviewSheet()
}
