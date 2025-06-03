import SwiftUI
import CoreLocation
import WebKit

// HotelListView displays a list of hotels for a selected city.
// Users can select a hotel to view details or choose it for their itinerary.
// The view fetches hotel data and supports navigation to HotelDetailView.
struct HotelListView: View {
    let city: City
    @Binding var selectedHotel: Hotel?
    @Environment(\.dismiss) private var dismiss
    @State private var hotels: [Hotel] = []
    @State private var isLoading = true
    @State private var error: Error?
    @State private var selectedHotelForDetails: Hotel?
    @State private var showingHotelDetails = false
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading hotels...")
                } else if let error = error {
                    VStack {
                        Text("Error loading hotels")
                            .foregroundColor(.red)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button("Try Again") {
                            Task {
                                await loadHotels()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else if hotels.isEmpty {
                    Text("No hotels found")
                        .foregroundColor(.secondary)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(hotels, id: \.id) { hotel in
                                HotelRow(hotel: hotel) {
                                    selectedHotel = hotel
                                    dismiss()
                                }
                                .onTapGesture {
                                    selectedHotelForDetails = hotel
                                    showingHotelDetails = true
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Hotels in \(city.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingHotelDetails) {
                if let hotel = selectedHotelForDetails {
                    NavigationView {
                        HotelDetailView(hotel: hotel, city: city, selectedHotel: $selectedHotel)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") {
                                        showingHotelDetails = false
                                    }
                                }
                            }
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
    let onSelect: () -> Void
    @State private var showingWebsite = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Hotel Image
            AsyncImage(url: URL(string: hotel.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Hotel Info
            VStack(alignment: .leading, spacing: 4) {
                Text(hotel.name)
                    .font(.headline)
                
                Text(hotel.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("\(hotel.rating, specifier: "%.1f")")
                        .foregroundColor(.yellow)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(hotel.priceLevel.rawValue)
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
            }
            .padding(.horizontal, 4)
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: onSelect) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Select Hotel")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                if let websiteURL = hotel.websiteURL {
                    Button(action: { showingWebsite = true }) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Website")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
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
}

// HotelWebView is a UIViewRepresentable that displays a hotel's website in a WebKit view.
// It provides a clean, non-persistent web view for viewing hotel websites within the app.
// The view supports back/forward navigation gestures and loads the specified URL.
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