import SwiftUI

enum TagViewStyle {
	case thinRed
	case solidRed
}

struct TagView: View {
	
	private let style: TagViewStyle
	private let leftIcon: Image
	private let text: Text
	
	init(
		style: TagViewStyle,
		leftIcon: Image,
		text: Text
	) {
		self.style = style
		self.leftIcon = leftIcon
		self.text = text
	}
	
	var body: some View {
		HStack {
			leftIcon
				.renderingMode(.template)
			text
				.font(.baseStyle(size: 12, weight: .bold))
		}
		.foregroundStyle(textColor)
		.padding(.horizontal, 16)
		.padding(.vertical, 8)
		.background(
			RoundedRectangle(cornerRadius: 6)
				.fill(backgroundColor)
		)
		.overlay {
			RoundedRectangle(cornerRadius: 6)
				.stroke(borderColor, lineWidth: 1)
		}
	}
	
	private var textColor: Color {
		switch style {
		case .thinRed:
			return .dangerMain
		case .solidRed:
			return .grayF1F1F1
		}
	}
	
	private var backgroundColor: Color {
		switch style {
		case .thinRed:
			return .danger50
		case .solidRed:
			return .dangerMain
		}
	}
	
	private var borderColor: Color {
		switch style {
		case .thinRed:
			return .dangerMain
		case .solidRed:
			return .dangerMain
		}
	}
	
}

#Preview {
	TagView(style: .thinRed, leftIcon: Image(.warning), text: Text("Action required"))
	TagView(style: .solidRed, leftIcon: Image(.warning), text: Text("Action required"))
}
