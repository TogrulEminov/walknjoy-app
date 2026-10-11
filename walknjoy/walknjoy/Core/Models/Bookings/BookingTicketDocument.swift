import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// The system exports the PDF directly; the View does not manage temporary files.
struct BookingTicketDocument: Transferable {
    let data: Data
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .pdf) { document in document.data }
            .suggestedFileName("ticket.pdf")
    }
}
