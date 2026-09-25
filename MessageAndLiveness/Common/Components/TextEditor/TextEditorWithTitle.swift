import SwiftUI

struct TextEditorWithTitle: ViewModifier {
	@Binding var text: String
	let title: String?
	let placeholder: String
	let textLimit: Int
	let capitalization: TextInputAutocapitalization
	let keyboardType: UIKeyboardType
	
	init(
		text: Binding<String>,
		placeholder: String = "Write details",
		title: String?,
		textLimit: Int = 120,
		capitalization: TextInputAutocapitalization = .never,
		keyboardType: UIKeyboardType = .default
	) {
		self._text = text
		self.placeholder = placeholder
		self.title = title
		self.textLimit = textLimit
		self.capitalization = capitalization
		self.keyboardType = keyboardType
	}
	
	func body(content: Content) -> some View {
		VStack(alignment: .leading) {
			if let title {
				Text(title)
					.font(.baseStyle(size: 14, weight: .medium))
					.foregroundStyle(.neutral90)
			}

			ZStack(alignment: .topLeading) {
				if text.isEmpty {
					Text(placeholder)
						.font(.baseStyle(size: 14, weight: .regular))
						.foregroundStyle(.neutral60)
						.padding(.horizontal, 4)
						.padding(.vertical, 8)
				}

				VStack(alignment: .trailing, spacing: 5) {
					content
						.font(.baseStyle(size: 12, weight: .regular))
						.tint(.neutral90)
						.autocorrectionDisabled(true)
						.textInputAutocapitalization(capitalization)
						.keyboardType(keyboardType)
						.scrollContentBackground(.hidden)
						.background(Color.clear)

					Text("\(text.count)/\(textLimit)")
						.font(.baseStyle(size: 10, weight: .regular))
						.foregroundStyle(.neutral60)
				}
			}
			.padding(10)
			.frame(height: 150)
			.overlay {
				RoundedRectangle(cornerRadius: 10)
					.stroke(lineWidth: 1)
					.foregroundStyle(.neutral50)
			}
		}
		.padding(.vertical)
		.onChange(of: text) { newValue in
			if newValue.count > textLimit {
				text = String(newValue.prefix(textLimit))
			}
		}
	}
}

#Preview {
	TextEditor(text: .constant(""))
		.modifier(
			TextEditorWithTitle(text: .constant(""), title: "How Can We Help?")
		)
}
