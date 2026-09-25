import SwiftUI
import RichText

struct HTMLTextView: View {
	let htmlContent: String
	let color: Color
	
	var body: some View {
		RichText(
			html: htmlContent
		)
		.textColor(light: color, dark: color)
	}
}

#Preview {
	// swiftlint: disable line_length
	HTMLTextView(
		htmlContent: """
  <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed euismod, neque at dictum cursus, sapien massa commodo urna, vitae dictum justo turpis at urna.Nulla facilisi. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae;Integer ac mattis velit. Morbi euismod, velit nec posuere venenatis, massa justo dictum purus, eu efficitur massa lacus a tellus.</p><p>Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Etiam faucibus augue nec velit cursus, ac eleifend enim facilisis.Nam non metus ac erat lobortis tempor. Vivamus eget arcu sed tortor commodo dictum. Vestibulum euismod, erat nec euismod hendrerit, velit massa dictum nisi, at ullamcorper sem ex nec urna.</p><p>Mauris at consectetur est. Suspendisse potenti. Donec euismod, enim et bibendum pharetra, tortor magna blandit massa, nec feugiat magna arcu eu leo. In hac habitasse platea dictumst.Proin ac turpis vitae est maximus tincidunt. Sed consequat, urna eu scelerisque dictum, ipsum augue dignissim mauris, sed pulvinar erat dolor vitae nibh.&nbsp;</p>
""",
		color: .primary
		// swiftlint: enable line_length
	)
}
