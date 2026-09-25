import SwiftUI

struct PrimaryButton<Label: View>: View {
	let backgroundColor: Color
	let strokeColor: Color?
	let size: CustomButtonSize
	let action: () -> Void
	let label: () -> Label
	let isDisabled: Bool
	
	init(
		size: CustomButtonSize = .medium,
		backgroundColor: Color = .brandSecondary,
		strokeColor: Color? = nil,
		isDisabled: Bool = false,
		action: @escaping () -> Void,
		@ViewBuilder label: @escaping () -> Label
	) {
		self.size = size
		self.backgroundColor = backgroundColor
		self.strokeColor = strokeColor
		self.isDisabled = isDisabled
		self.action = action
		self.label = label
	}
	
	var body: some View {
		Button(action: action) {
			label()
				.font(size.font)
				.foregroundStyle(.white)
				.padding(.horizontal, 16)
				.frame(height: size.height)
				.frame(maxWidth: size.shouldStretch ? .infinity : nil)
				.background(
					RoundedRectangle(cornerRadius: 12)
						.fill(isDisabled ? .brandSecondaryDisabled : backgroundColor)
				)
				.overlay {
					if let strokeColor {
						RoundedRectangle(cornerRadius: 12)
							.stroke(
								isDisabled ? .brandSecondaryDisabled : strokeColor,
								lineWidth: 1
							)
					}
				}
			
				.contentShape(RoundedRectangle(cornerRadius: 12))
		}
		.disabled(isDisabled)
	}
	
	enum CustomButtonSize {
		case small
		case medium
		case mediumIntrinsic
		case large
		
		var height: CGFloat {
			switch self {
			case .small: return 28
			case .medium, .mediumIntrinsic: return 42
			case .large: return 56
			}
		}
		
		var font: Font {
			switch self {
			case .small: return .baseStyle(size: 10, weight: .bold)
			case .medium, .mediumIntrinsic: return .baseStyle(size: 14, weight: .bold)
			case .large: return .baseStyle(size: 16, weight: .bold)
			}
		}
		
		var shouldStretch: Bool {
			switch self {
			case .small, .mediumIntrinsic: return false
			case .medium, .large: return true
			}
		}
	}
}

#Preview {
	VStack(spacing: 16) {
		
		PrimaryButton(size: .small, action: {}) {
			Text("Small Enabled")
		}
		
		PrimaryButton(size: .small, isDisabled: true, action: {}) {
			Text("Small Disabled")
		}
		
		PrimaryButton(size: .mediumIntrinsic, action: {}) {
			Text("Medium Intrinsic Enabled")
		}
		
		PrimaryButton(size: .medium, action: {}) {
			Text("Medium Enabled")
		}
		
		PrimaryButton(size: .medium, isDisabled: true, action: {}) {
			Text("Medium Disabled")
		}
		
		PrimaryButton(size: .large, action: {}) {
			Text("Large Enabled")
		}
		
		PrimaryButton(size: .large, isDisabled: true, action: {}) {
			Text("Large Disabled")
		}
	}
	.padding()
}
