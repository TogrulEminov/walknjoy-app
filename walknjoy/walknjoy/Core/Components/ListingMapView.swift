import SwiftUI
import MapKit

struct ListingMapView: View {
    let listings: [PublicListing]
    @Binding var selection: String?

    var body: some View {
        Map(selection: $selection) {
            ForEach(listings) { listing in
                if let location = listing.location,
                   let lat = location.latitude,
                   let lon = location.longitude {
                    Marker(listing.title, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                        .tint(listing.type == .stay ? .blue : .green)
                        .tag(listing.id)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }
}
