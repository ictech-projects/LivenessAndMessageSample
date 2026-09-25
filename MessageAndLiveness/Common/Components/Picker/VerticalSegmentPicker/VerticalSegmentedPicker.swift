import SwiftUI

protocol VerticalSegmentedItem: Hashable, CaseIterable {
	var title: String { get }
	var icon: Image { get }
}

struct VerticalSegmentedPicker<Item: VerticalSegmentedItem>: View {
	@Binding var selection: Item
	
	var body: some View {
		VStack(spacing: 8) {
			ForEach(Array(Item.allCases), id: \.self) { item in
				Button {
					withAnimation {
						selection = item
					}
				} label: {
					HStack {
						Spacer()
						
						item.icon
							.renderingMode(.template)
							.foregroundStyle(
								selection == item ? Color.neutral90 : Color.neutral70
							)
						
						Text(item.title)
							.font(.baseStyle(size: 16, weight: .medium))
							.foregroundStyle(
								selection == item ? .neutral90 : .neutral70
							)
						
						Spacer()
					}
					.padding(.vertical, 12)
					.padding(.horizontal, 16)
					.background(
						RoundedRectangle(cornerRadius: 12)
							.fill(selection == item ? Color.neutral10 : .clear)
					)
					.overlay {
						RoundedRectangle(cornerRadius: 12)
							.stroke(
								selection == item ? Color.neutral40 : .clear,
								lineWidth: 1
							)
					}
				}
			}
		}
		.padding(8)
		.background(
			RoundedRectangle(cornerRadius: 16)
				.fill(Color.neutral30)
		)
	}
}

// MARK: - Example

private enum ExampleSegment: String, CaseIterable, Hashable {
	case personalDetails = "Personal Details"
	case additionalInformation = "Additional Information"
}

extension ExampleSegment: VerticalSegmentedItem {
	var title: String { rawValue }
	
	var icon: Image {
		switch self {
		case .personalDetails:
			return Image(.person)
		case .additionalInformation:
			return Image(.information)
		}
	}
}

private struct VerticalSegmentedPickerPreview: View {
	@State private var selectedForm: ExampleSegment = .personalDetails
	
	var body: some View {
		VStack(spacing: 16) {
			VerticalSegmentedPicker(selection: $selectedForm)
			
			Text("Selected: \(selectedForm.title)")
				.font(.baseStyle(size: 14, weight: .regular))
				.foregroundStyle(.neutral60)
			
			Spacer()
		}
		.padding()
	}
}

#Preview {
	VerticalSegmentedPickerPreview()
}
