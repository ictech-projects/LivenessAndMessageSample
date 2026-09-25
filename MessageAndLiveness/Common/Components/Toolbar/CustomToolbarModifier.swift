import SwiftUI

struct CustomToolbarModifier: ViewModifier {
	let backButton: (Image, () -> Void)
	let background: (Visibility, Color)
	var centerContent: (Bool, Text?)
	var trailing: (Image, () -> Void)?
	var hideNavigationButton: Bool = false
	
	func body(content: Content) -> some View {
		content
			.navigationBarTitleDisplayMode(.inline)
			.navigationBarBackButtonHidden()
			.toolbarBackground(background.1, for: .navigationBar)
			.toolbarBackground(background.0, for: .navigationBar)
			.toolbar {
				if !hideNavigationButton {
					ToolbarItem(placement: .navigation) {
						BackButton(backButton: backButton)
					}
				}
				
				ToolbarItem(placement: .principal) {
					titleText()
							.font(.baseStyle(size: 18, weight: .bold))
							.foregroundStyle(.neutral90)
				}
				
				if let trailing = trailing {
					ToolbarItem(placement: .topBarTrailing) {
						Button(action: trailing.1) {
							trailing.0
						}
					}
				}
			}
			.onAppear {
				let appearance = UINavigationBarAppearance()
				appearance.configureWithOpaqueBackground()
				appearance.shadowColor = .clear
				appearance.shadowImage = UIImage()
				
				UINavigationBar.appearance().standardAppearance = appearance
				UINavigationBar.appearance().scrollEdgeAppearance = appearance
			}
			.onDisappear {
				let appearance = UINavigationBarAppearance()
				UINavigationBar.appearance().standardAppearance = appearance
				UINavigationBar.appearance().scrollEdgeAppearance = appearance
			}
	}
	
	@ViewBuilder
	private func titleText() -> some View {
		if let text = centerContent.1 {
			text
		} else {
			Text("")
		}
	}
}

struct BackButton: View {
	let backButton: (Image, () -> Void)
	
	var body: some View {
		Button(action: backButton.1) {
			backButton.0
				.tint(.neutral90)
				.accessibilityLabel("Back")
		}
	}
}

extension View {
	/// withCustomToolbar have 2 parameter with tuple
	///
	/// **background**
	/// - have tuple contain Visibility and Color that represent toolbar visibility and color background
	///
	/// **centerContent**
	/// - have Boolean and Text? tuple that represent showing logo or no and the title with SwiftUI.Text input
	func withCustomToolBar(
		backButton: (Image, () -> Void) = (Image(.backArrow), {}),
		background: (Visibility, Color) = (.hidden, .clear),
		centerContent: (isShowLogo: Bool, title: Text?),
		trailing: (Image, (() -> Void))? = nil,
		hideNavigationButton: Bool = false
	) -> some View {
		modifier(CustomToolbarModifier(backButton: backButton, background: background, centerContent: centerContent, trailing: trailing, hideNavigationButton: hideNavigationButton))
	}
}

#Preview("Custom Toolbar") {
	NavigationStack {
		VStack(spacing: 16) {
			Text("Main Content")
				.font(.baseStyle(size: 16, weight: .regular))
			
			Text("Scroll / interact to see toolbar behavior")
				.font(.footnote)
				.foregroundStyle(.secondary)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color.white)
		.withCustomToolBar(
			backButton: (
				Image(systemName: "chevron.left"),
				{ print("Back tapped") }
			),
			background: (.visible, .white),
			centerContent: (
				isShowLogo: false,
				title: Text("Custom Toolbar")
			),
			trailing: (
				Image(systemName: "ellipsis"),
				{ print("Trailing tapped") }
			)
		)
	}
}
