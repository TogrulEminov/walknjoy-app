import PDFKit
import SwiftUI

struct BookingTicketView: View {
    let pdfData: Data
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            PDFKitRepresentable(data: pdfData)

            ShareLink(item: BookingTicketDocument(data: pdfData), preview: SharePreview(Text("listing.detail.ticket"))) {
                Label("common.share", systemImage: "square.and.arrow.up")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.brandInk)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        Color.brandYellow,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .padding()
            }
        }
        .navigationTitle("listing.detail.ticket")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("common.close") { dismiss() }
            }
        }
    }

}

struct PDFKitRepresentable: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        if let document = PDFDocument(data: data) {
            pdfView.document = document
        }
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = PDFDocument(data: data) {
            uiView.document = document
        }
    }
}
