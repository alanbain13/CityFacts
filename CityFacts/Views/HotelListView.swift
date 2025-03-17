import SwiftUI
import CoreLocation
import WebKit

struct HotelListView: View {
    let city: City
    @Binding var selectedHotel: Hotel?
    @Environment(\.dismiss) private var dismiss
    @State private var hotels: [Hotel] = []
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading hotels...")
                } else if let error = error {
                    VStack(spacing: 16) {
                        Text("Error loading hotels")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            Task {
                                await loadHotels()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else {
                    List(hotels) { hotel in
                        HotelRow(
                            hotel: hotel,
                            isSelected: hotel.id == selectedHotel?.id,
                            onSelect: {
                                selectedHotel = hotel
                                dismiss()
                            }
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .navigationTitle("Hotels in \(city.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadHotels()
        }
    }
    
    private func loadHotels() async {
        isLoading = true
        error = nil
        
        do {
            let searchQuery = "hotels in \(city.name)"
            print("Searching for hotels with query: \(searchQuery)")
            let places = try await GooglePlacesService.shared.searchPlaces(query: searchQuery)
            print("Found \(places.count) places")
            
            // Convert Places to Hotels
            var loadedHotels: [Hotel] = []
            for place in places {
                print("Processing hotel: \(place.displayName.text)")
                
                // Fetch additional details including website URL
                let details = try await GooglePlacesService.shared.getPlaceDetails(placeId: place.id)
                
                let priceLevel: Hotel.PriceLevel
                if place.types.contains("luxury") {
                    priceLevel = .ultraLuxury
                } else if place.types.contains("upscale") {
                    priceLevel = .luxury
                } else if place.types.contains("budget") {
                    priceLevel = .budget
                } else {
                    priceLevel = .moderate
                }
                
                // Get amenities based on place types
                var amenities = ["Wi-Fi", "Air Conditioning"]
                if place.types.contains("spa") { amenities.append("Spa") }
                if place.types.contains("restaurant") { amenities.append("Restaurant") }
                if place.types.contains("fitness_center") { amenities.append("Fitness Center") }
                if place.types.contains("swimming_pool") { amenities.append("Swimming Pool") }
                
                let imageURL = place.photos?.first?.photoURL ?? "https://images.unsplash.com/photo-1566073771259-6a8506099945"
                print("Hotel image URL: \(imageURL)")
                
                let hotel = Hotel(
                    id: UUID(),
                    name: place.displayName.text,
                    description: "Experience comfort and convenience at \(place.displayName.text), located in \(city.name).",
                    address: place.formattedAddress,
                    rating: 4.5,
                    imageURL: imageURL,
                    coordinates: CLLocationCoordinate2D(
                        latitude: place.location.latitude,
                        longitude: place.location.longitude
                    ),
                    amenities: amenities,
                    websiteURL: details.websiteUri,
                    phoneNumber: nil,
                    priceLevel: priceLevel
                )
                loadedHotels.append(hotel)
                print("Added hotel: \(hotel.name)")
            }
            
            print("Total hotels loaded: \(loadedHotels.count)")
            self.hotels = loadedHotels
        } catch {
            print("Error loading hotels: \(error)")
            self.error = error
        }
        
        isLoading = false
    }
}

struct HotelRow: View {
    let hotel: Hotel
    let isSelected: Bool
    @State private var showingWebsite = false
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: hotel.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(hotel.name)
                    .font(.headline)
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text(String(format: "%.1f", hotel.rating))
                    Text("•")
                    Text(hotel.priceLevel.rawValue)
                }
                .font(.subheadline)
                Text(hotel.address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                if hotel.websiteURL != nil {
                    Button {
                        showingWebsite = true
                    } label: {
                        HStack {
                            Image(systemName: "globe")
                            Text("Visit Website")
                                .font(.caption)
                        }
                        .foregroundStyle(.blue)
                    }
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .sheet(isPresented: $showingWebsite) {
            if let websiteURL = hotel.websiteURL, let url = URL(string: websiteURL) {
                NavigationStack {
                    HotelWebView(url: url)
                        .navigationTitle(hotel.name)
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
        .padding(.vertical, 4)
    }
}

struct HotelWebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
} 