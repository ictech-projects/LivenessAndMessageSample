//
//  SinglePickerItem.swift
//  MessageAndLiveness
//
//  Created by Ewide Dev 5 on 28/01/26.
//

import SwiftUI

struct SingleItemPicker<Item, Content>: View where Item: Hashable, Content: View {
	@Binding var selection: Item?
	let title: String?
	@ViewBuilder let content: Content

	init(selection: Binding<Item?>, title: String? = nil, @ViewBuilder content: () -> Content) {
		self._selection = selection
		self.title = title
		self.content = content()
	}
	
	var body: some View {
		VStack(alignment: .leading) {
			if let title = title {
				Text(title)
					.font(.baseStyle(size: 16, weight: .medium))
					.foregroundStyle(.neutral90)
			}
			
			Menu {
				Picker("", selection: $selection) { content }
			} label: {
				HStack {
					Group {
						if let item = selection as? String {
							Text(item)
								.foregroundStyle(.neutral90)
						} else {
							Text("Choose types of leave")
								.foregroundStyle(.neutral60)
						}
					}
					.lineLimit(1)
					.font(.baseStyle(size: 12, weight: .regular))
					
					Spacer()
					
					Image(.chevronDownIcon)
						.renderingMode(.template)
						.resizable()
						.scaledToFit()
						.frame(width: 20)
						.foregroundStyle(selection != nil ? .neutral90 : .neutral50)
				}
				.frame(height: 46)
				.padding(.horizontal)
				.overlay {
					RoundedRectangle(cornerRadius: 12)
						.stroke(selection != nil ? .neutral90 : .neutral50, lineWidth: 1)
				}
				.contentShape(RoundedRectangle(cornerRadius: 12))
			}
		}
	}
}

#Preview("Without Label") {
	PreviewItemPicker()
}

#Preview("With Labeled") {
	PreviewItemPicker(title: "Type of leave")
}

fileprivate struct PreviewItemPicker: View {
	@State var selection: String?
	@State var displaySelection = ""
	
	private let title: String?
	
	init(title: String? = nil) {
		self.title = title
	}
	
	var body: some View {
		SingleItemPicker(selection: $selection, title: title) {
			ForEach(0...5, id: \.self) { item in
				Text("item \(item)")
					.tag("item \(item)")
			}
		}
	}
}
