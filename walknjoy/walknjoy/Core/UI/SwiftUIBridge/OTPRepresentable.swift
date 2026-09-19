//
//  OTPRepresentable.swift
//  walknjoy
//
//  Created by Eminov Togrul Punhan on 16.09.26.
//
import SwiftUI

struct OTPRepresentable: UIViewRepresentable {

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
        if uiView.code != code {
            uiView.setCode(code)
        }
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: OtpInput,
        context: Context
    ) -> CGSize? {
        let minimumWidth = CGFloat(digitCount * 48 + (digitCount - 1) * 8)
        let proposedWidth = proposal.width ?? minimumWidth

        return CGSize(
            width: max(proposedWidth, minimumWidth),
            height: 56
        )
    }
}
