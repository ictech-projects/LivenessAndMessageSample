import SwiftUI

extension TextField {
	func withTitle(
		_ title: Text?,
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
		onLeftIconPressed: (() -> Void)? = nil,
		onRightIconPressed: (() -> Void)? = nil
	) -> some View {
		modifier(
			TextFieldWithTitle(
				title: title,
				capitalization: capitalization,
				keyboardType: keyboardType,
				backgroundColor: backgroundColor,
				titleColor: titleColor,
				strokeColor: strokeColor,
				leftIcon: leftIcon,
				leftIconColor: leftIconColor,
				rightIcon: rightIcon,
				rightIconColor: rightIconColor,
				errorDescription: errorDescription,
				onLeftIconPressed: onLeftIconPressed,
				onRightIconPressed: onRightIconPressed
			)
		)
	}
}
