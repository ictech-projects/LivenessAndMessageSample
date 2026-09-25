import Lottie
import SwiftUI

extension View {
	func loadingState<T: Codable>(
		_ state: Binding<RequestState<T>>,
		title: Text,
		description: Text,
		loadingViewAccentStyle: LoadingViewAccentStyle = .appAccent,
		loadingViewBackgroundStyle: LoadingViewBackgroundStyle = .lightTranslucent
	) -> some View {
		modifier(LoadingView(
			state: state,
			title: title,
			description:
				description,
			loadingViewAccentStyle: loadingViewAccentStyle,
			loadingViewBackgroundStyle: loadingViewBackgroundStyle
		))
	}
}

enum LoadingViewAccentStyle {
	case appAccent
	case gray
}

enum LoadingViewBackgroundStyle {
	/// Dark content with blur background
	case darkBlur
	
	/// Light content with blur background
	case lightBlur
	
	/// Dark content with translucent (non-blurred) background
	case darkTranslucent
	
	/// Light content with translucent (non-blurred) background
	case lightTranslucent
	
	/// Light content with solid defualt background
	case lightSolid
}

struct LoadingView<T: Codable>: ViewModifier {
	@Binding private var state: RequestState<T>
	private let title: Text
	private let description: Text
	private let loadingViewAccentStyle: LoadingViewAccentStyle
	private let loadingViewBackgroundStyle: LoadingViewBackgroundStyle
	
	init(
		state: Binding<RequestState<T>>,
		title: Text, description: Text,
		loadingViewAccentStyle: LoadingViewAccentStyle = .appAccent,
		loadingViewBackgroundStyle: LoadingViewBackgroundStyle = .lightTranslucent
	) {
		self._state = state
		self.title = title
		self.description = description
		self.loadingViewAccentStyle = loadingViewAccentStyle
		self.loadingViewBackgroundStyle = loadingViewBackgroundStyle
	}
	
	private var backgroundColor: Color {
		switch loadingViewBackgroundStyle {
		case .darkBlur:
			Color.black.opacity(0.8)
		case .lightBlur:
			Color.neutral90.opacity(0.1)
		case .darkTranslucent:
			Color.neutral90.opacity(0.5)
		case .lightTranslucent:
			Color.neutral90.opacity(0.5)
		case .lightSolid:
			Color.neutral30
		}
	}
	
	func body(content: Content) -> some View {
		ZStack {
			content
			
			if state == .loading {
				if loadingViewBackgroundStyle == .lightBlur || loadingViewBackgroundStyle == .darkBlur {
					backgroundColor
						.background(.ultraThinMaterial)
						.ignoresSafeArea()
				} else {
					backgroundColor
						.ignoresSafeArea()
				}
				
				VStack(spacing: 32) {
					Spacer()
					
					Group {
						switch loadingViewAccentStyle {
						case .appAccent:
							LottieView({
								LottieAnimation.named(LottieFile.loading.rawValue)
							})
							.looping()
						case .gray:
							CircularLoadingView()
						}
					}
					.frame(width: 88, height: 88)
					
					if loadingViewBackgroundStyle == .lightBlur {
						VStack(spacing: 6) {
							title
								.foregroundStyle(.neutral90)
								.font(.baseStyle(size: 16, weight: .medium))
							description
								.foregroundStyle(.neutral90)
								.font(.baseStyle(size: 14, weight: .regular))
						}
					} else {
						VStack(spacing: 6) {
							title
								.font(.baseStyle(size: 16, weight: .medium))
							description
								.font(.baseStyle(size: 14, weight: .regular))
						}
					}
					
					Spacer()
				}
			}
		}
	}
}

struct PreviewHelperView: View {
	var body: some View {
		VStack {
			LazyVGrid(
				columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 6),
				spacing: 0
			) {
				ForEach(0..<60, id: \.self) { _ in
					Rectangle()
						.fill(
							Color(
								red: .random(in: 0.2...1),
								green: .random(in: 0.2...1),
								blue: .random(in: 0.2...1)
							)
						)
						.frame(height: 80)
				}
			}
			.ignoresSafeArea()
		}
	}
}

#Preview("Dark blur - Loading for Login View content") {
	VStack {
		PreviewHelperView()
	}
	.loadingState(
		.constant(RequestState<String>.loading),
		title: Text("Getting things ready")
			.foregroundColor(.neutral10),
		description: Text("Please wait")
			.foregroundColor(.neutral10),
		loadingViewBackgroundStyle: .darkBlur
	)
}

#Preview("Loading for light translucent backgroud content") {
	PreviewHelperView()
		.loadingState(
			.constant(RequestState<String>.loading),
			title: Text("Getting things ready"),
			description: Text("Please wait"),
			loadingViewBackgroundStyle: .lightBlur
		)
}

#Preview("Light solid - Setup Authentitactor app loading view style") {
	PreviewHelperView()
		.loadingState(
			.constant(RequestState<String>.loading),
			title: Text("Generating QR code.")
				.foregroundColor(.neutral90),
			description: Text("Please wait.")
				.foregroundColor(.neutral90),
			loadingViewAccentStyle: .gray,
			loadingViewBackgroundStyle: .lightSolid
		)
}

#Preview("Light blur Loading State") {
	PreviewHelperView()
		.loadingState(
			.constant(RequestState<String>.loading),
			title: Text("Generating QR code."),
			description: Text("Please wait."),
			loadingViewBackgroundStyle: .lightBlur
		)
}

#Preview("Light Translucent Loading State") {
	PreviewHelperView()
		.loadingState(
			.constant(RequestState<String>.loading),
			title: Text("Generating QR code.")
				.foregroundColor(.neutral90),
			description: Text("Please wait.")
				.foregroundColor(.neutral90),
			loadingViewBackgroundStyle: .lightTranslucent
		)
}
