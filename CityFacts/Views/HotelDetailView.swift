import SwiftUI
import MapKit

struct HotelDetailView: View {
    let hotel: Hotel
    let city: City
    @Binding var selectedHotel: Hotel?
    @Environment(\.dismiss) private var dismiss
    @State private var showingHotelList = false
    @State private var showingWebsite = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Hotel Image
                AsyncImage(url: URL(string: hotel.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 12) {
                    // Hotel Name and Rating
                    HStack {
                        Text(hotel.name)
                            .font(.title)
                            .fontWeight(.bold)
                        Spacer()
                        HStack(spacing: 4) {
                            Text("\(hotel.rating, specifier: "%.1f")")
                                .foregroundColor(.yellow)
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(hotel.priceLevel.rawValue)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Address
                    Text(hotel.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Description
                    Text(hotel.description)
                        .font(.body)
                    
                    // Map
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: hotel.coordinates,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )), annotationItems: [hotel]) { hotel in
                        MapMarker(coordinate: hotel.coordinates)
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Amenities
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amenities")
                            .font(.headline)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(hotel.amenities, id: \.self) { amenity in
                                HStack {
                                    Image(systemName: amenityIcon(for: amenity))
                                        .foregroundColor(.blue)
                                    Text(amenity)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            selectedHotel = hotel
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Select Hotel")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        if let websiteURL = hotel.websiteURL {
                            Button(action: { showingWebsite = true }) {
                                HStack {
                                    Image(systemName: "globe")
                                    Text("Visit Website")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Change Hotel") {
                    showingHotelList = true
                }
            }
        }
        .sheet(isPresented: $showingHotelList) {
            NavigationView {
                HotelListView(city: city, selectedHotel: $selectedHotel)
            }
        }
        .sheet(isPresented: $showingWebsite) {
            if let websiteURLString = hotel.websiteURL,
               let websiteURL = URL(string: websiteURLString) {
                NavigationView {
                    HotelWebView(url: websiteURL)
                        .navigationTitle("Hotel Website")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingWebsite = false
                                }
                            }
                        }
                }
            }
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