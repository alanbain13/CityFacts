import SwiftUI
import MapKit

// HotelDetailView displays detailed information about a selected hotel.
// It shows the hotel's name, address, rating, amenities, and location on a map.
// Users can select the hotel, visit its website, or change their hotel selection.
struct HotelDetailView: View {
    let hotel: Hotel
    let city: City
    @Binding var selectedHotel: Hotel?
    var onHotelSelected: ((Hotel) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var showingWebsite = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Hotel Image
                if let imageURL = hotel.imageURL {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 200)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                        case .failure:
                            Image(systemName: "building.2")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "building.2")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .foregroundColor(.gray)
                }
                
                // Hotel Details
                VStack(alignment: .leading, spacing: 12) {
                    Text(hotel.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let address = hotel.address {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let rating = hotel.rating {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", rating))
                        }
                    }
                    
                    if let priceLevel = hotel.priceLevel {
                        Text(String(repeating: "$", count: priceLevel.rawValue.count))
                            .foregroundColor(.green)
                    }
                    
                    if let websiteURL = hotel.websiteURL {
                        Link("Visit Website", destination: URL(string: websiteURL)!)
                            .foregroundColor(.blue)
                    }
                    
                    if let phoneNumber = hotel.phoneNumber {
                        Button(action: {
                            if let url = URL(string: "tel:\(phoneNumber)") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "phone.fill")
                                Text(phoneNumber)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                
                // Select Hotel Button
                Button(action: {
                    selectedHotel = hotel
                    onHotelSelected?(hotel)
                    dismiss()
                }) {
                    Text("Select This Hotel")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
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