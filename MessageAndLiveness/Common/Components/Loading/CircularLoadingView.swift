import SwiftUI

struct CircularLoadingView: View {
	@State private var rotation: Double = 0

	var body: some View {
		ZStack {
			Circle()
				.stroke(Color.neutral40, lineWidth: 8)

			Circle()
				.trim(from: 0.0, to: 0.25)
				.stroke(
					Color.neutral60,
					style: StrokeStyle(lineWidth: 8, lineCap: .round)
				)
				.rotationEffect(.degrees(rotation))
		}
		.frame(width: 80, height: 80)
		.onAppear {
			withAnimation(
				.linear(duration: 1.0)
				.repeatForever(autoreverses: false)
			) {
				rotation = 360
			}
		}
	}
}

#Preview {
	CircularLoadingView()
}
