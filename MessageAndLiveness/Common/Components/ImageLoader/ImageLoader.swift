import SwiftUI

struct ImageLoader: View {
	let path: String
	let width: CGFloat
	let height: CGFloat
	
	init(path: String, width: CGFloat = .infinity, height: CGFloat = .infinity) {
		self.path = path
		self.width = width
		self.height = height
	}
	
	var body: some View {
		AsyncImage(
			url: URL(string: path),
			transaction: Transaction(animation: .default)
		) { phase in
			switch phase {
			case .empty:
				Color.neutral50
					.overlay {
						ProgressView()
							.progressViewStyle(.circular)
							.tint(.white)
					}
					.frame(width: width, height: height)
			case .success(let image):
				image
					.resizable()
					.scaledToFill()
					.frame(width: width, height: height)
					
			case .failure:
				Color.neutral50
					.overlay {
						Image(systemName: "exclamationmark.circle")
							.resizable()
							.scaledToFit()
							.frame(width: width/3)
							.foregroundStyle(.white)
					}
					.frame(width: width, height: height)
			default:
				Color.neutral50
					.overlay {
						Image(systemName: "exclamationmark.circle")
							.resizable()
							.scaledToFit()
							.frame(width: width/3)
							.foregroundStyle(.white)
					}
					.frame(width: width, height: height)
			}
		}
		.scaledToFill()
		.frame(width: width, height: height)
	}
}

#Preview {
	VStack {
		ImageLoader(path: "https://hjk-staging.s3.ap-southeast-2.amazonaws.com/assets/pages/01K7E3P8THAGCQ6J5BD1FY4VH9.jpg", width: 150, height: 120)
			.clipShape(RoundedRectangle(cornerRadius: 10))
			.clipped()
		
		ImageLoader(path: "https://hjk-staging.s3.ap-southeast-2.amazonaws.com/assets/pages/invalid.jpg", width: 150, height: 120)
			.clipShape(RoundedRectangle(cornerRadius: 10))
			.clipped()
		
		ImageLoader(path: "", width: 150, height: 120)
			.clipShape(RoundedRectangle(cornerRadius: 10))
			.clipped()
	}
}
