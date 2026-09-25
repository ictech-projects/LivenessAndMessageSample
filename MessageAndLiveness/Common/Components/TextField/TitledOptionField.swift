import SwiftUI

struct TitledOptionField: View {
	let title: Text
	let value: String
	let isLoading: Bool
	let height: CGFloat?
	let isDisabled: Bool
	let action: (() -> Void)?
	
	init(
		title: Text,
		value: String,
		isLoading: Bool = false,
		height: CGFloat?,
		isDisabled: Bool = false,
		action: (() -> Void)? = nil
	) {
		self.title = title
		self.value = value
		self.isLoading = isLoading
		self.height = height
		self.isDisabled = isDisabled
		self.action = action
	}
	
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack {
				title
					.font(.baseStyle(size: 16, weight: .medium))
					.foregroundStyle(.neutral90)
					.padding(.horizontal, 2)
				
				if isLoading {
					ProgressView()
						.progressViewStyle(.circular)
						.scaleEffect(0.8)
				}
			}
			
			
			if isDisabled {
				OptionField(value: value, height: height, isDisabled: isDisabled)
			} else {
				Button {
					action?()
				} label: {
					OptionField(value: value, height: height, isDisabled: isDisabled)
				}
			}
		}
	}
}

struct OptionField: View {
	let value: String
	let height: CGFloat?
	let isDisabled: Bool
	
	var body: some View {
		HStack {
			Text(value)
				.font(.baseStyle(size: 16, weight: .regular))
				.foregroundStyle(isDisabled ? .neutral60 : .neutral90)
			Spacer()
			Image(.chevronDownIcon)
		}
		.frame(height: height ?? nil)
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

#Preview("TitledOptionField") {
	TitledOptionField(
		title: Text("State"),
		value: "Select state",
		isLoading: false,
		height: nil,
		isDisabled: false
	)
	.padding()
	.background(.white)
	
	TitledOptionField(
		title: Text("State"),
		value: "Select state",
		isLoading: true,
		height: nil,
		isDisabled: true,
		action: { }
	)
	.padding()
	.background(.white)
}

#Preview("OptionField") {
	OptionField(
		value: "a value",
		height: nil,
		isDisabled: false
	)
}
