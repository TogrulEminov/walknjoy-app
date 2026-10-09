import SwiftUI

struct BookingSuccessView: View {
    let booking: BookingResponse
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.brandYellow)
                .padding(.top, 40)

            VStack(spacing: 8) {
                Text("listing.detail.bookingSuccessTitle")
                    .font(.title2.bold())
                    .foregroundStyle(Color.titleText)
                Text("listing.detail.bookingSuccessMessage")
                    .font(.subheadline)
                    .foregroundStyle(Color.descriptionText)
                    .multilineTextAlignment(.center)
            }
            .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                HStack {
                    Text("listing.detail.bookingRef").font(.caption)
                        .foregroundStyle(Color.descriptionText)
                    Spacer()
                    Text(booking.reference).font(.subheadline.bold())
                        .foregroundStyle(Color.titleText)
                }
                HStack {
                    Text("listing.detail.totalAmount").font(.caption)
                        .foregroundStyle(Color.descriptionText)
                    Spacer()
                    Text(
                        "\(booking.totalAmount.formatted(.number.precision(.fractionLength(0...2)))) \(booking.currency)"
                    )
                    .font(.subheadline.bold()).foregroundStyle(Color.titleText)
                }
            }
            .padding()
            .background(
                Color.surfaceBackground,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16).stroke(Color.borderColor)
            )

            Button("listing.detail.viewMyBookings", action: onClose)
                .font(.subheadline.bold())
                .foregroundStyle(Color.brandInk)
                .padding(.horizontal, 24)
                .frame(height: 52)
                .background(
                    Color.brandYellow,
                    in: RoundedRectangle(cornerRadius: 16)
                )
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}
