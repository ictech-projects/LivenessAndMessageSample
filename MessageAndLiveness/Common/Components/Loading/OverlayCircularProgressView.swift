import SwiftUI

struct OverlayCircularProgressView: View {
	
	let show: Bool
	
	var body: some View {
		Group {
			if show {
				Color.black.opacity(0.5)
					.background(.ultraThinMaterial)
					.ignoresSafeArea()
				
				ProgressView()
					.progressViewStyle(.circular)
					.tint(.white)
			}
		}
	}
}

#Preview {
	ZStack {
		Color.blue.ignoresSafeArea(edges: .all)
		PreviewHelperView()
		OverlayCircularProgressView(show: true)
	}
}
