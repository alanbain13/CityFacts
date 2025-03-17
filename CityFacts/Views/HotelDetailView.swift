import SwiftUI
import MapKit

struct HotelDetailView: View {
    let hotel: Hotel
    let city: City
    @Binding var selectedHotel: Hotel?
    @Environment(\.dismiss) private var dismiss
    @State private var showingHotelList = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Hotel Image
                AsyncImage(url: URL(string: hotel.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(height: 250)
                .clipped()
                
                VStack(alignment: .leading, spacing: 16) {
                    // Hotel Name and Rating
                    HStack {
                        Text(hotel.name)
                            .font(.title)
                            .fontWeight(.bold)
                        Spacer()
                        Button {
                            showingHotelList = true
                        } label: {
                            Text("Change Hotel")
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    
                    // Rating and Price
                    HStack {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text(String(format: "%.1f", hotel.rating))
                                .fontWeight(.semibold)
                        }
                        Text("•")
                        Text(hotel.priceLevel.rawValue)
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                    
                    // Description
                    Text(hotel.description)
                        .font(.body)
                        .padding(.vertical, 8)
                    
                    // Address
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.blue)
                        Text(hotel.address)
                            .font(.subheadline)
                    }
                    
                    // Amenities
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amenities")
                            .font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(hotel.amenities, id: \.self) { amenity in
                                HStack {
                                    Image(systemName: amenityIcon(for: amenity))
                                        .foregroundStyle(.blue)
                                    Text(amenity)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Map
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: hotel.coordinates,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )), annotationItems: [hotel]) { hotel in
                        MapMarker(coordinate: hotel.coordinates)
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Contact Buttons
                    VStack(spacing: 12) {
                        if let websiteURL = hotel.websiteURL {
                            Link(destination: URL(string: websiteURL)!) {
                                HStack {
                                    Image(systemName: "globe")
                                    Text("Book on Booking.com")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        
                        if let phoneNumber = hotel.phoneNumber {
                            Link(destination: URL(string: "tel:\(phoneNumber)")!) {
                                HStack {
                                    Image(systemName: "phone.fill")
                                    Text("Call Hotel")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingHotelList) {
            HotelListView(city: city, selectedHotel: $selectedHotel)
        }
        .onChange(of: selectedHotel) { newHotel in
            if let newHotel = newHotel {
                dismiss()
            }
        }
    }
    
    private func amenityIcon(for amenity: String) -> String {
        switch amenity.lowercased() {
        case let name where name.contains("wifi"):
            return "wifi"
        case let name where name.contains("spa"):
            return "sparkles"
        case let name where name.contains("restaurant"):
            return "fork.knife"
        case let name where name.contains("fitness"):
            return "figure.run"
        case let name where name.contains("pool"):
            return "figure.pool.swim"
        case let name where name.contains("air"):
            return "air.conditioner.horizontal"
        default:
            return "checkmark.circle"
        }
    }
} 