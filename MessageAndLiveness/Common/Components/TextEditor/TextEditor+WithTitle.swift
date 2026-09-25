import SwiftUI

extension TextEditor {
	func withTitle(
		text: Binding<String>,
		placeholder: String = "Write details",
		_ title: String?,
		textLimit: Int = 120,
		capitalization: TextInputAutocapitalization = .never,
		keyboardType: UIKeyboardType = .default
	) -> some View {
		modifier(
			TextEditorWithTitle(
				text: text,
				placeholder: placeholder,
				title: title,
				textLimit: textLimit,
				capitalization: capitalization,
				keyboardType: keyboardType
			)
		)
	}
}
