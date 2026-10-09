import SwiftUI

struct ListingBookingBar: View {
    let price: Decimal
    let currency: String
    let type: ListingType
    var showsBookingButton = true
    var onBook: (() -> Void)?
    @State private var showUnavailable = false

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) {
                priceLabel
                Spacer(minLength: 0)
                if showsBookingButton { bookingButton }
            }
            VStack(alignment: .leading, spacing: 12) {
                priceLabel
                if showsBookingButton { bookingButton.frame(maxWidth: .infinity) }
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .background(Color.surfaceBackground)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.borderColor).frame(height: 1)
        }
        .alert(
            "listing.detail.bookingUnavailable",
            isPresented: $showUnavailable
        ) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text("listing.detail.bookingUnavailableMessage")
        }
    }

    private var priceLabel: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(
                verbatim:
                    "\(price.formatted(.number.precision(.fractionLength(0...2)))) \(currency)"
            )
            .font(.title3.bold()).foregroundStyle(Color.titleText)
            Text("booking.basePrice")
            .font(.caption).foregroundStyle(Color.descriptionText)
        }.fixedSize(horizontal: true, vertical: false)
    }

    private var bookingButton: some View {
        Button {
            if let onBook { onBook() } else { showUnavailable = true }
        } label: {
            HStack(spacing: 10) {
                Text("listing.detail.book")
                Image(systemName: "arrow.right").font(.caption.weight(.bold))
            }.font(.subheadline.bold())
                .foregroundStyle(Color.brandInk)
                .padding(.horizontal, 24).frame(minHeight: 50)
                .background(
                    Color.brandYellow,
                    in: RoundedRectangle(cornerRadius: 14)
                )
        }.buttonStyle(.plain)
    }
}
