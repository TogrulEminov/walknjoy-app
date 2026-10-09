import PDFKit
import SwiftUI

struct BookingTicketView: View {
    let pdfData: Data
    @Environment(\.dismiss) private var dismiss
    @State private var shareURL: URL?
    @State private var showShare = false
    @State private var error: String?

    var body: some View {
        VStack {
            PDFKitRepresentable(data: pdfData)

            Button {
                sharePDF()
            } label: {
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
        .sheet(isPresented: $showShare) {
            if let shareURL { BookingPDFShareView(url: shareURL) }
        }
        .alert("error.title", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("common.ok", role: .cancel) {}
        } message: { Text(error ?? "") }
        .navigationTitle("listing.detail.ticket")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("common.close") { dismiss() }
            }
        }
    }

    private func sharePDF() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ticket.pdf")
        do {
            try pdfData.write(to: tempURL)
            shareURL = tempURL
            showShare = true
        } catch {
            self.error = error.localizedDescription
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


private struct BookingPDFShareView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
