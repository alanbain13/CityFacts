import Foundation
import CoreLocation

class HotelListViewModel: ObservableObject {
    @Published var hotels: [Hotel] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    func fetchHotels(for city: City) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            let searchQuery = "hotels in \(city.name)"
            Logger.info("Searching for hotels with query: \(searchQuery)")
            let places = try await GooglePlacesService.shared.searchPlaces(query: searchQuery)
            Logger.info("Found \(places.count) places")
            
            // Convert Places to Hotels
            var loadedHotels: [Hotel] = []
            for place in places {
                Logger.info("Processing hotel: \(place.displayName.text)")
                
                // Fetch additional details including website URL
                let details = try await GooglePlacesService.shared.getPlaceDetails(placeId: place.placeId)
                
                // Determine price level based on the place's types
                let priceLevel: Hotel.PriceLevel?
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
                
                // Get the first photo URL
                let imageURL = place.photos?.first?.photoURL
                
                let hotel = Hotel(
                    id: UUID(),
                    name: place.displayName.text,
                    description: "Experience comfort and convenience at \(place.displayName.text), located in \(city.name).",
                    address: place.formattedAddress,
                    rating: nil, // Rating not available in current API
                    imageURL: imageURL,
                    coordinates: CLLocationCoordinate2D(
                        latitude: place.location.lat,
                        longitude: place.location.lng
                    ),
                    amenities: amenities,
                    websiteURL: details.website,
                    phoneNumber: nil, // Phone number not available in current API
                    priceLevel: priceLevel
                )
                
                loadedHotels.append(hotel)
                Logger.info("Added hotel: \(hotel.name)")
            }
            
            await MainActor.run {
                self.hotels = loadedHotels
                self.isLoading = false
            }
            
            Logger.success("Successfully loaded \(loadedHotels.count) hotels")
        } catch {
            Logger.error("Error loading hotels: \(error)")
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
} 