import SwiftUI

extension View {
	func cardStyle() -> some View {
		modifier(CardModifier())
	}
}

struct CardModifier: ViewModifier {
	func body(content: Content) -> some View {
		content
			.padding(16)
			.background(
				RoundedRectangle(cornerRadius: 12)
					.fill(.neutral10)
					.shadow(
						color: .cardShadow,
						radius: 4,
						x: 0,
						y: 1
					)
			)
	}
}

#Preview {
	VStack(alignment: .leading, spacing: 8) {
		Text("Hello")
		Text("World")
	}
	.cardStyle()
	.padding()
}

#Preview {
	List {
		Text("First Card")
			.cardStyle()
			.listRowSeparator(.hidden)
			.listRowBackground(Color.clear)
	}
	.listStyle(.plain)
}

#Preview {
	HStack(spacing: 12) {
		Image(systemName: "book.closed.fill")
		VStack(alignment: .leading) {
			Text("Learn SwiftUI")
			Text("Build beautiful apps quickly.")
		}
	}
	.cardStyle()
}
