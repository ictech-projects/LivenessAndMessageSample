import SwiftUI

struct WheelPickerView<Item: Hashable>: View {
	let items: [Item]
	@Binding var selection: Item
	let title: String
	let label: (Item) -> String
	let onDoneTapped: (() -> Void)?
	
	init(
		items: [Item],
		selection: Binding<Item>,
		title: String,
		label: @escaping (Item) -> String,
		onDoneTapped: (() -> Void)? = nil
	) {
		self.items = items
		self._selection = selection
		self.title = title
		self.label = label
		self.onDoneTapped = onDoneTapped
	}
	
	@Environment(\.dismiss) private var dismiss
	
	var body: some View {
		VStack(spacing: 20) {
			Text(title)
				.font(.baseStyle(size: 16, weight: .medium))
			
			Picker(title, selection: $selection) {
				ForEach(items, id: \.self) { item in
					Text(label(item))
						.font(.baseStyle(size: 16, weight: .regular))
						.tag(item)
				}
			}
			.pickerStyle(.wheel)
			.onAppear {
				// SwiftUI wheel Picker only updates the binding when a scroll event occurs.
				// If there is only one item, no scrolling is possible, so the selection
				// may never be propagated. Preselect the only available item to ensure
				// the binding is correctly initialized.
				if items.count == 1, let onlyItem = items.first {
					selection = onlyItem
				}
			}
			.labelsHidden()
			.frame(height: 150)
			
			PrimaryButton {
				dismiss()
				onDoneTapped?()
			} label: {
				Text("Done")
			}
			.padding(.bottom)
		}
		.padding()
		.presentationDetents([.height(300)])
	}
}

// MARK: - SwiftUI Preview

private enum PreviewGender: CaseIterable, Hashable {
	case male
	case female
	case other
	
	var title: String {
		switch self {
		case .male: return "Male"
		case .female: return "Female"
		case .other: return "Other"
		}
	}
}

private struct WheelPickerPreviewContainer: View {
	@State private var selectedGender: PreviewGender = .male
	@State private var showPicker = false
	
	var body: some View {
		VStack(spacing: 16) {
			Text("Selected: \(selectedGender.title)")
				.font(.baseStyle(size: 16, weight: .medium))
			
			Button("Select Gender") {
				showPicker = true
			}
		}
		.sheet(isPresented: $showPicker) {
			WheelPickerView(
				items: PreviewGender.allCases,
				selection: $selectedGender,
				title: "Select Gender",
				label: { $0.title },
				onDoneTapped: {
					showPicker = false
				}
			)
		}
		.padding()
	}
}

#Preview {
	WheelPickerPreviewContainer()
}
