//
//  OTPRepresentable.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 16.09.26.
//
import SwiftUI

/// Measure the actual row width before crossing the SwiftUI/UIKit boundary.
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

        otpInput.onCodeChanged = { newCode in
            code = newCode
        }

        return otpInput
    }

    func updateUIView(_ uiView: OtpInput, context: Context) {
        uiView.hasValidationError = hasValidationError
        if uiView.code != code {
            uiView.setCode(code)
        }
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: OtpInput,
        context: Context
    ) -> CGSize? {
        let preferredWidth = CGFloat(digitCount * 48 + (digitCount - 1) * 8)

        // Use the parent container's width, including Form row insets.
        // SwiftUI can also probe with an unspecified or infinite proposal.
        let width = proposal.width.flatMap { $0.isFinite ? max(0, $0) : nil }
        return CGSize(width: width ?? preferredWidth, height: 56)
    }
}
