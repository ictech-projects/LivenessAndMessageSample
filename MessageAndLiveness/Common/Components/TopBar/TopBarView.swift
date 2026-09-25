import SwiftUI

struct TopBarView: View {
	let title: String
	let onBackPressed: (() -> Void)?
	
	init(title: String, onBackPressed: (() -> Void)? = nil) {
		self.title = title
		self.onBackPressed = onBackPressed
	}
	
	var body: some View {
		VStack(spacing: 0) {
			ZStack(alignment: .center) {
				if let onBackPressed {
					HStack {
						Button {
							onBackPressed()
						} label: {
							Image(.backArrow)
								.resizable()
								.scaledToFit()
								.frame(width: 24)
								.accessibilityLabel("Back")
						}
						
						Spacer()
					}
					.padding(.leading)
				}
				
				HStack {
					Spacer()
					
					Text(title)
						.font(.baseStyle(size: 18, weight: .bold))
						.foregroundStyle(.neutral100)
						.padding(.horizontal)
					
					Spacer()
				}
			}
			.padding(.top, 5)
			.padding(.bottom)
			.background(
				Rectangle()
					.foregroundStyle(.neutral30)
					.ignoresSafeArea()
			)
		}
	}
}

#Preview {
	VStack {
		TopBarView(title: "About Us", onBackPressed: {})
		Spacer()
	}
}

#Preview {
	VStack {
		TopBarView(title: "About Us", onBackPressed: nil)
		Spacer()
	}
}

