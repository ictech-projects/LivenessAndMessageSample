import SwiftUI
import UIKit

/// The app's base typeface. Montserrat ships in `Common/Resource/Fonts` and is
/// registered at launch by `FontRegistrar` (the target generates its Info.plist,
/// so fonts are registered programmatically rather than via `UIAppFonts`).
enum BaseFont {
	static func name(for weight: Font.Weight) -> String {
		switch weight {
		case .bold, .semibold, .heavy, .black:
			return "Montserrat-Bold"
		case .medium:
			return "Montserrat-Medium"
		case .light, .thin, .ultraLight:
			return "Montserrat-Light"
		default:
			return "Montserrat-Regular"
		}
	}
}

extension UIFont {
	static func baseStyle(size: CGFloat, weight: Font.Weight) -> UIFont {
		UIFont(name: BaseFont.name(for: weight), size: size)
			?? .systemFont(ofSize: size, weight: weight.uiWeight)
	}
}

extension Font {
	static func baseStyle(size: CGFloat, weight: Font.Weight) -> Font {
		.custom(BaseFont.name(for: weight), size: size)
	}
}

private extension Font.Weight {
	var uiWeight: UIFont.Weight {
		switch self {
		case .bold, .semibold, .heavy, .black: return .bold
		case .medium: return .medium
		case .light, .thin, .ultraLight: return .light
		default: return .regular
		}
	}
}

struct BaseStyleFontPreview: View {
	let sizes: [CGFloat] = [12, 14, 16, 20, 24, 26, 28, 30, 32, 40, 48]
	let weights: [Font.Weight] = [.light, .regular, .medium, .bold]

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 24) {

				ForEach(sizes, id: \.self) { size in
					VStack(alignment: .leading, spacing: 12) {
						Text("Size \(Int(size)) pt")
							.font(.headline)
							.padding(.bottom, 4)

						ForEach(weights, id: \.self) { weight in
							Text("Font \(weightName(weight)) • \(Int(size)) pt")
								.font(.baseStyle(size: size, weight: weight))
						}
					}
				}
			}
			.padding()
		}
	}

	private func weightName(_ weight: Font.Weight) -> String {
		switch weight {
		case .light: return "Light"
		case .regular: return "Regular"
		case .medium: return "Medium"
		case .bold: return "Bold"
		default: return "Regular"
		}
	}
}

#Preview {
	BaseStyleFontPreview()
}
