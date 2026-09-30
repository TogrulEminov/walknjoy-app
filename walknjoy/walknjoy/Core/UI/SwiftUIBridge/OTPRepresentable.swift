//
//  OTPRepresentable.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 16.09.26.
//
import SwiftUI

/// Adapts the UIKit OTP control to SwiftUI while keeping the entered code in a binding.
struct OTPRepresentable: View {
    @Binding var code: String
    let digitCount: Int

    var body: some View {
        GeometryReader { geometry in
            OTPUIKitBridge(code: $code, digitCount: digitCount)
                .frame(width: max(0, geometry.size.width), height: 56)
        }
        .frame(height: 56)
        .frame(maxWidth: .infinity)
    }
}

private struct OTPUIKitBridge: UIViewRepresentable {

    @Environment(\.fieldHasValidationError) private var hasValidationError

    @Binding var code: String
    let digitCount: Int

    func makeUIView(context: Context) -> OtpInput {
        let otpInput = OtpInput(digitCount: digitCount)

        // Forward edits from the UIKit control to the SwiftUI source of truth.
        otpInput.onCodeChanged = { newCode in
            code = newCode
        }

        return otpInput
    }

    func updateUIView(_ uiView: OtpInput, context: Context) {
        uiView.hasValidationError = hasValidationError
        // Also apply programmatic changes, such as clearing the code after an error.
        if uiView.code != code {
            uiView.setCode(code)
        }
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: OtpInput,
        context: Context
    ) -> CGSize? {
        // Use the available width when SwiftUI proposes one; otherwise size cells from their count.
        let preferredWidth = CGFloat(digitCount * 48 + (digitCount - 1) * 8)

        let width = proposal.width.flatMap { $0.isFinite ? max(0, $0) : nil }
        return CGSize(width: width ?? preferredWidth, height: 56)
    }
}
