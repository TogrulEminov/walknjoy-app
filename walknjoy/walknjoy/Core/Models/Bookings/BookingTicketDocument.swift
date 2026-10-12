import CoreTransferable
import Foundation
import UniformTypeIdentifiers
 
nonisolated struct BookingTicketDocument: Transferable {
    let data: Data
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .pdf) { document in
            document.data
        }
        .suggestedFileName("ticket.pdf")
    }
}
