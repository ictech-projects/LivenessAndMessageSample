import SwiftUI

struct TextFieldWithTitle: ViewModifier {
	let title: Text?
	let capitalization: TextInputAutocapitalization
	let keyboardType: UIKeyboardType
	let backgroundColor: Color
	let titleColor: Color
	let strokeColor: Color
	let leftIcon: Image?
	let leftIconColor: Color
	let rightIcon: Image?
	let rightIconColor: Color
	let errorDescription: Text?
	let isDisabled: Bool
	let onLeftIconPressed: (() -> Void)?
	let onRightIconPressed: (() -> Void)?
	
	init(
		title: Text?,
		capitalization: TextInputAutocapitalization = .never,
		keyboardType: UIKeyboardType = .default,
		backgroundColor: Color = .clear,
		titleColor: Color = .neutral90,
		strokeColor: Color = .neutral60,
		leftIcon: Image? = nil,
		leftIconColor: Color = .neutral90,
		rightIcon: Image? = nil,
		rightIconColor: Color = .neutral90,
		errorDescription: Text? = nil,
		isDisabled: Bool = false,
		onLeftIconPressed: (() -> Void)? = nil,
		onRightIconPressed: (() -> Void)? = nil
	) {
		self.title = title
		self.capitalization = capitalization
		self.keyboardType = keyboardType
		self.backgroundColor = backgroundColor
		self.titleColor = titleColor
		self.strokeColor = strokeColor
		self.leftIcon = leftIcon
		self.leftIconColor = leftIconColor
		self.rightIcon = rightIcon
		self.rightIconColor = rightIconColor
		self.errorDescription = errorDescription
		self.isDisabled = isDisabled
		self.onLeftIconPressed = onLeftIconPressed
		self.onRightIconPressed = onRightIconPressed
	}
	
	func body(content: Content) -> some View {
		VStack(alignment: .leading, spacing: 12) {
			if let title {
				title
					.font(.baseStyle(size: 16, weight: .medium))
					.foregroundStyle(titleColor)
			}
			
			HStack {
				if let leftIcon {
					Button {
						onLeftIconPressed?()
					} label: {
						leftIcon
							.renderingMode(.template)
							.resizable()
							.scaledToFit()
							.frame(width: 24)
							.foregroundStyle(leftIconColor)
					}
					.buttonStyle(.plain)
				}
				
				content
					.foregroundStyle(isDisabled ? .neutral60 : .neutral90)
				
				if let rightIcon {
					Button {
						onRightIconPressed?()
					} label: {
						rightIcon
							.renderingMode(.template)
							.resizable()
							.scaledToFit()
							.frame(width: 24)
							.foregroundStyle(rightIconColor)
					}
					.buttonStyle(.plain)
				}
			}
			.padding(10)
			.frame(height: 48)
			.background {
				RoundedRectangle(cornerRadius: 8)
					.foregroundStyle(hasError ? Color.dangerMain : backgroundColor)
			}
			.overlay {
				RoundedRectangle(cornerRadius: 8)
					.stroke(lineWidth: 1)
					.foregroundStyle(strokeColor)
			}
			.font(.baseStyle(size: 16, weight: .regular))
			.tint(.neutral90)
			.autocorrectionDisabled(true)
			.textInputAutocapitalization(capitalization)
			.keyboardType(keyboardType)
			
			if let errorDescription {
				errorDescription
					.foregroundStyle(.dangerMain)
					.font(.baseStyle(size: 14, weight: .regular))
			}
		}
	}
	
	private var hasError: Bool {
		errorDescription != nil
	}
}

#Preview {
	VStack(spacing: 24) {
		TextField(text: .constant("")) {
			Text("Enter your email")
				.font(.baseStyle(size: 16, weight: .regular))
		}
		.modifier(
			TextFieldWithTitle(
				title: Text("Email"),
				capitalization: .never,
				keyboardType: .emailAddress,
				rightIcon: Image(.eyeOff),
				onLeftIconPressed: {},
				onRightIconPressed: {}
			)
		)
		
		TextField(text: .constant("")) {
			Text("Enter your email")
				.font(.baseStyle(size: 16, weight: .regular))
		}
		.modifier(
			TextFieldWithTitle(
				title: Text("Email"),
				capitalization: .never,
				keyboardType: .emailAddress,
				leftIcon: Image(.eye),
				rightIcon: Image(.eyeOff),
				onLeftIconPressed: {},
				onRightIconPressed: {}
			)
		)
		
		TextField(text: .constant("")) {
			Text("Enter code")
				.font(.baseStyle(size: 16, weight: .regular))
		}
		.multilineTextAlignment(.center)
		.modifier(
			TextFieldWithTitle(
				title: nil,
				capitalization: .never,
				keyboardType: .emailAddress,
				onLeftIconPressed: {},
				onRightIconPressed: {}
			)
		)
	}
}
