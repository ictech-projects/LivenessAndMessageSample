import SwiftUI

struct ForceUpdateView: View {
	@Environment(\.openURL) private var openURL

	var body: some View {
		ZStack {
			//			TODO: use background
			//			Image(.forceUpdateBackground)
			//				.resizable()
			//				.scaledToFill()
			//				.ignoresSafeArea()
			
			VStack(spacing: 65) {
				Spacer()
	
				//				TODO: use background
				//				Image(.appIconForForceUpdate)
				//					.resizable()
				//					.scaledToFit()
				//					.frame(width: 150)
				
				VStack(spacing: 24) {
					Text("Please Update\nApp Name")
						.font(.baseStyle(size: 24, weight: .bold))
						.foregroundStyle(.neutral90)
						.multilineTextAlignment(.center)
					
					Text("This version of the app is no longer supported. Please update to the latest version to continue using the app.")
						.font(.baseStyle(size: 14, weight: .regular))
						.foregroundStyle(.neutral60)
						.multilineTextAlignment(.center)
				}
				.padding(.horizontal, 28)
				
				PrimaryButton(size: .mediumIntrinsic) {
					if let url = URL(string: "https://apps.apple.com/us/app/app_name/some-id") {
						openURL(url)
					}
				} label: {
					Text("Update Now")
				}
				
				Spacer()
			}
		}
	}
}

#Preview {
	ForceUpdateView()
}
