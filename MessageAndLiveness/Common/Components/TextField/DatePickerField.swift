import SwiftUI

struct DatePickerField: View {
	
	let selectedDateText: Text
	let isDisabled: Bool
	let action: (() -> Void)?
	
	init(
		selectedDateText: Text,
		isDisabled: Bool = false,
		action: (() -> Void)? = nil
	) {
		self.selectedDateText = selectedDateText
		self.isDisabled = isDisabled
		self.action = action
	}
	
	var body: some View {
		if isDisabled {
			content
		} else {
			Button {
				action?()
			} label: {
				content
			}
		}
	}
	
	private var content: some View {
		HStack {
			selectedDateText
				.font(.baseStyle(size: 16, weight: .regular))
				.foregroundStyle(isDisabled ? .neutral60 : .neutral90)
			
			Spacer()
			
			Image(.calendar)
				.resizable()
				.frame(width: 24, height: 24)
		}
		.padding(12)
		.background(
			RoundedRectangle(cornerRadius: 8)
				.foregroundStyle(.clear)
		)
		.overlay {
			RoundedRectangle(cornerRadius: 8)
				.stroke(lineWidth: 1)
				.foregroundStyle(.neutral60)
		}
		.clipShape(RoundedRectangle(cornerRadius: 8))
	}
}

#Preview {
	DatePickerField(
		selectedDateText: Text("20 January 2025")
	)
	DatePickerField(
		selectedDateText: Text("20 January 2025"),
		isDisabled: true
	)
}
