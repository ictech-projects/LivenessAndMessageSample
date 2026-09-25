import SwiftUI

struct OutlinedButton: View {
	let action: () -> Void
	let title: Text
	var leftImage: Image? = nil
	
	var body: some View {
		Button(action: action) {
			HStack(spacing: 6) {
				if let leftImage {
					leftImage
						.resizable()
						.frame(width: 18, height: 18)
				}
				
				title
					.font(.baseStyle(size: 16, weight: .medium))
					.foregroundStyle(.neutral90)
			}
			.padding(.horizontal, 8)
			.padding(.vertical, 4)
			.background(
				RoundedRectangle(cornerRadius: 8)
					.fill(Color.neutral10)
			)
			.overlay {
				RoundedRectangle(cornerRadius: 8)
					.stroke(Color.neutral90, lineWidth: 1)
			}
		}
		.buttonStyle(.plain)
	}
}

#Preview {
	VStack {
		OutlinedButton(
			action: {},
			title: Text("Copy"),
			leftImage: Image(.copy)
		)
		
		OutlinedButton(
			action: {},
			title: Text("Continue")
		)
	}
}
