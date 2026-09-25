import SwiftUI

struct Footer<Content: View>: View {
	
	let showShadowEffect: Bool
	@ViewBuilder var content: Content
	
	init(showShadowEffect: Bool = true, @ViewBuilder content: () -> Content) {
		self.showShadowEffect = showShadowEffect
		self.content = content()
	}
	
	var body: some View {
		if showShadowEffect {
			container()
				.background(
					RoundedRectangle(cornerRadius: 12)
						.fill(Color.neutral10)
						.shadow(
							color: .cardShadow,
							radius: 4,
							x: 0,
							y: 1
						)
				)
		} else {
			container()
		}
	}
	
	private func container() -> some View {
		VStack {
			content
				.padding(.horizontal, 16)
				.padding(.top, 16)
				.padding(.bottom, 10)
		}
		.frame(maxWidth: .infinity)
		.frame(height: 95)
		.background(Color.neutral10)
	}
}

#Preview {
	VStack {
		Spacer()
		
		Footer {
			PrimaryButton {
				// action
			} label: {
				Text("Footer")
			}
		}
	}
	.frame(maxWidth: .infinity, maxHeight: .infinity)
	.background(Color.gray.opacity(0.1))
}

#Preview {
	ZStack(alignment: .bottom) {
		Color.gray.opacity(0.1)
		
		Footer {
			PrimaryButton {
				// action
			} label: {
				Text("Footer")
			}
		}
	}
	.frame(maxWidth: .infinity, maxHeight: .infinity)
}
