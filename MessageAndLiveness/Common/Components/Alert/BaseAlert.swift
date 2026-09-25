import SwiftUI

struct BaseAlert: ViewModifier {
	@Binding var isPresented: Bool
	let type: AlertType
	let title: String
	let message: String
	let confirmButtonColor: (text: Color, background: Color, stroke: Color)
	let confirmLabel: Text
	let cancelLabel: Text?
	let confirmAction: () -> Void
	let cancelAction: (() -> Void)?
	
	init(
		isPresented: Binding<Bool>,
		type: AlertType,
		title: String,
		message: String,
		confirmButtonColor: (text: Color, background: Color, stroke: Color) = (text: .white, background: .brandSecondary, stroke: .clear),
		confirmLabel: Text,
		cancelLabel: Text? = nil,
		confirmAction: @escaping () -> Void,
		cancelAction: (() -> Void)? = nil
	) {
		self._isPresented = isPresented
		self.type = type
		self.title = title
		self.message = message
		self.confirmButtonColor = confirmButtonColor
		self.confirmLabel = confirmLabel
		self.cancelLabel = cancelLabel
		self.confirmAction = confirmAction
		self.cancelAction = cancelAction
	}
	
	func body(content: Content) -> some View {
		content.overlay {
			if isPresented {
					Color.black
						.opacity(0.75)
						.ignoresSafeArea()
					
					HStack {
						Spacer()
						
						VStack {
							Spacer()
							
							VStack(spacing: 24) {
								type.icon
									.resizable()
									.scaledToFit()
									.frame(width: 44)
								
								VStack(spacing: 10) {
									Text(title)
										.font(.baseStyle(size: 16, weight: .bold))
										.foregroundStyle(type.titleColor)
										.multilineTextAlignment(.center)
									
									Text(message)
										.font(.baseStyle(size: 14, weight: .regular))
										.foregroundStyle(.neutral70)
										.multilineTextAlignment(.center)
								}
								
								HStack {
									
									if let cancelLabel, let cancelAction {
										PrimaryButton(
											size: .medium,
											backgroundColor: .clear,
											strokeColor: Color.neutral90,
											isDisabled: false,
											action: cancelAction
										) {
											cancelLabel
												.font(.baseStyle(size: 16, weight: .medium))
												.foregroundStyle(.neutral90)
										}
									}
									
									PrimaryButton(
										size: .medium,
										backgroundColor: confirmButtonColor.background,
										strokeColor: confirmButtonColor.stroke,
										isDisabled: false,
										action: confirmAction
									) {
										confirmLabel
											.font(.baseStyle(size: 16, weight: .medium))
											.foregroundStyle(confirmButtonColor.text)
									}
								}
							}
							.padding(.top, 24)
							.padding([.horizontal, .bottom], 20)
							.background(Color(.systemBackground))
							.clipShape(RoundedRectangle(cornerRadius: 12))
							.padding()
							
							Spacer()
						}
						
						Spacer()
					}
				}
		}
	}
}

extension View {
	func baseAlert(
		isPresented: Binding<Bool>,
		type: AlertType,
		title: String,
		message: String,
		confirmButtonColor: (text: Color, background: Color, stroke: Color),
		confirmLabel: Text,
		cancelLabel: Text? = nil,
		confirmAction: @escaping () -> Void,
		cancelAction: (() -> Void)? = nil
	) -> some View {
		modifier(
			BaseAlert(
				isPresented: isPresented,
				type: type,
				title: title,
				message: message,
				confirmButtonColor: confirmButtonColor,
				confirmLabel: confirmLabel,
				cancelLabel: cancelLabel,
				confirmAction: confirmAction,
				cancelAction: cancelAction
			)
		)
	}
}

#Preview {
	Color.white
		.baseAlert(
			isPresented: .constant(true),
			type: .error,
			title: "Send request to delete account?",
			message: "We’ll submit your request to permanently delete your account and data.",
			confirmButtonColor: (text: .white, background: .dangerMain, stroke: .clear),
			confirmLabel: Text("Send Request"),
			confirmAction: {}
		)
}

#Preview("Warning – Confirm & Cancel") {
	Color.white
		.baseAlert(
			isPresented: .constant(true),
			type: .passwordUpdate,
			title: "Are you sure?",
			message: "This action cannot be undone.",
			confirmButtonColor: (text: .white, background: .brandSecondary, stroke: .clear),
			confirmLabel: Text("Continue"),
			cancelLabel: Text("Cancel"),
			confirmAction: {},
			cancelAction: {}
		)
}

#Preview("Success – Confirm Only") {
	Color.white
		.baseAlert(
			isPresented: .constant(true),
			type: .success,
			title: "Request sent",
			message: "Your request has been successfully submitted.",
			confirmButtonColor: (text: .white, background: .successMain, stroke: .clear),
			confirmLabel: Text("OK"),
			confirmAction: {}
		)
}

#Preview("Info – Confirm & Cancel") {
	Color.white
		.baseAlert(
			isPresented: .constant(true),
			type: .passwordUpdate,
			title: "Enable notifications?",
			message: "You can change this later in Settings.",
			confirmButtonColor: (text: .white, background: .brandPrimary, stroke: .clear),
			confirmLabel: Text("Enable"),
			cancelLabel: Text("Not Now"),
			confirmAction: {},
			cancelAction: {}
		)
}
