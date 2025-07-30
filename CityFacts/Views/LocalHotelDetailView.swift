// MARK: - LocalHotelDetailView
// Description: Detailed view for hotels with rich UI including images and information.
// Version: 0.0.1
// Modification Date: 2024-06-09
// Author: Cursor

import SwiftUI
import MapKit

struct LocalHotelDetailView: View {
    let hotel: Hotel
    @Environment(\.dismiss) private var dismiss
    @State private var region: MKCoordinateRegion
    
    init(hotel: Hotel) {
        self.hotel = hotel
        self._region = State(initialValue: MKCoordinateRegion(
            center: hotel.coordinates,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Hero Image
                    AsyncImage(url: URL(string: hotel.imageURL ?? "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&h=400&fit=crop")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 250)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(1.5)
                            )
                    }
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Title and Rating
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(hotel.name)
                                    .font(.title2)
                                    .bold()
                                
                                if let priceLevel = hotel.priceLevel {
                                    Text(priceLevel.rawValue.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                            
                            Spacer()
                            
                            if let rating = hotel.rating {
                                VStack(alignment: .trailing, spacing: 4) {
                                    HStack {
                                        ForEach(0..<Int(rating), id: \.self) { _ in
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                                .font(.caption)
                                        }
                                    }
                                    Text("\(rating, specifier: "%.1f")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        // Description
                        Text(hotel.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        // Details
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(icon: "mappin.circle.fill", title: "Address", value: hotel.address ?? "Address not available")
                            
                            if let phone = hotel.phoneNumber {
                                DetailRow(icon: "phone.fill", title: "Phone", value: phone)
                            }
                            
                            if let website = hotel.websiteURL {
                                DetailRow(icon: "globe", title: "Website", value: website)
                            }
                        }
                        
                        // Amenities
                        if !hotel.amenities.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Amenities")
                                    .font(.headline)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 8) {
                                    ForEach(hotel.amenities, id: \.self) { amenity in
                                        HStack(spacing: 8) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.caption)
                                            
                                            Text(amenity)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Map
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location")
                                .font(.headline)
                            
                            Map(coordinateRegion: $region, annotationItems: [hotel]) { hotel in
                                MapMarker(coordinate: hotel.coordinates, tint: .green)
                            }
                            .frame(height: 200)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Hotel Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LocalHotelDetailView(hotel: Hotel(
        id: UUID(),
        name: "Grand Hotel London",
        description: "Luxury hotel in the heart of London",
        address: "123 Oxford Street, London, UK",
        rating: 4.5,
        imageURL: "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&h=300&fit=crop",
        coordinates: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
        amenities: ["WiFi", "Breakfast", "Gym", "Spa"],
        websiteURL: "https://example.com",
        phoneNumber: "+44 20 1234 5678",
        priceLevel: .luxury
    ))
} 