import Foundation
import CoreLocation

class GooglePlacesService {
    static let shared = GooglePlacesService()
    
    private let apiKey = GooglePlacesConfig.apiKey
    private let baseURL = "https://maps.googleapis.com/maps/api/place"
    
    private init() {}
    
    // Search for places by text query
    func searchPlaces(query: String) async throws -> [Place] {
        let urlString = "\(baseURL)/textsearch/json?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw PlacesAPIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlacesAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PlacesAPIError.httpError(httpResponse.statusCode)
        }
        
        let placesResponse = try JSONDecoder().decode(PlacesResponse.self, from: data)
        
        return placesResponse.results.map { place in
            Place(
                placeId: place.placeId,
                displayName: DisplayName(text: place.name),
                formattedAddress: place.formattedAddress,
                location: Location(lat: place.geometry.location.lat, lng: place.geometry.location.lng),
                types: place.types,
                photos: place.photos?.map { photo in
                    Photo(photoURL: "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=\(photo.photoReference)&key=\(self.apiKey)")
                } ?? []
            )
        }
    }
    
    // Get place details by place ID
    func getPlaceDetails(placeId: String) async throws -> PlaceDetails {
        let urlString = "\(baseURL)/details/json?place_id=\(placeId)&fields=name,formatted_address,geometry,types,rating,user_ratings_total,price_level,opening_hours,photos,website&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw PlacesAPIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlacesAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PlacesAPIError.httpError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(PlaceDetails.self, from: data)
    }
    
    // Fetch tourist attractions for a city
    func fetchTouristAttractions(for city: City) async throws -> [TouristAttraction] {
        Logger.info("Fetching Tourist Attractions for \(city.name)")
        
        // Create a set to track unique place names to prevent duplicates
        var seenNames = Set<String>()
        var attractions: [TouristAttraction] = []
        
        // First, search for the city's landmarks using Places API to get proper photos
        for landmark in city.landmarks {
            Logger.debug("Searching for landmark: \(landmark.name)")
            let searchQuery = "\(landmark.name) in \(city.name)"
            let places = try await searchPlaces(query: searchQuery)
            
            if let place = places.first {
                // TEMPORARY DEBUG: Abort if no photo URL is available
                guard let photoURL = place.photos?.first?.photoURL else {
                    Logger.error("❌ No photo URL available for landmark: \(landmark.name)")
                    fatalError("DEBUG: No photo URL available for landmark: \(landmark.name)")
                }
                
                let imageURL = photoURL
                Logger.debug("Found image URL for \(landmark.name): \(imageURL)")
                
                let attraction = TouristAttraction(
                    id: UUID(),
                    name: landmark.name,
                    description: landmark.description,
                    category: .historical,
                    estimatedDuration: estimateVisitDuration(type: "landmark", name: landmark.name),
                    coordinates: TouristAttraction.Coordinates(
                        latitude: place.location.lat,
                        longitude: place.location.lng
                    ),
                    imageURL: imageURL,
                    tips: generateTips(for: .historical),
                    websiteURL: nil
                )
                attractions.append(attraction)
                seenNames.insert(landmark.name)
            } else {
                // Fallback to original landmark data if no match found
                Logger.debug("No Places API match found for landmark: \(landmark.name)")
                let fallbackURL = getFallbackImageURL(for: .historical)
                Logger.debug("Using fallback image URL: \(fallbackURL)")
                
                let attraction = TouristAttraction(
                    id: UUID(),
                    name: landmark.name,
                    description: landmark.description,
                    category: .historical,
                    estimatedDuration: estimateVisitDuration(type: "landmark", name: landmark.name),
                    coordinates: TouristAttraction.Coordinates(
                        latitude: city.coordinates.latitude,
                        longitude: city.coordinates.longitude
                    ),
                    imageURL: fallbackURL,
                    tips: generateTips(for: .historical),
                    websiteURL: nil
                )
                attractions.append(attraction)
                seenNames.insert(landmark.name)
            }
        }
        
        // Then, fetch nearby tourist attractions using the Places API
        let searchQueries = [
            "top tourist attractions in \(city.name)",
            "must visit places in \(city.name)",
            "popular landmarks in \(city.name)",
            "best museums in \(city.name)",
            "famous monuments in \(city.name)"
        ]
        
        for query in searchQueries {
            Logger.debug("Searching with query: \(query)")
            let places = try await searchPlaces(query: query)
            
            // Convert Places to TouristAttractions
            for place in places {
                let name = place.displayName.text
                
                // Skip if we've already seen this name
                guard !seenNames.contains(name) else { continue }
                
                // Determine the category and estimated duration based on place types
                let category = determineCategory(from: place.types)
                let duration = estimateVisitDuration(type: place.types.first ?? "tourist_attraction", name: name)
                
                // Get the photo URL if available, otherwise use a relevant fallback
                var imageURL = getFallbackImageURL(for: category)
                if let photos = place.photos, !photos.isEmpty {
                    if let firstPhotoURL = photos.first?.photoURL {
                        imageURL = firstPhotoURL
                        Logger.debug("Using place photo URL for \(name): \(firstPhotoURL)")
                    } else {
                        Logger.warning("Photo object exists but URL could not be generated for \(name).")
                    }
                } else {
                    Logger.debug("No photos available for \(name), using fallback URL: \(imageURL)")
                }
                
                let attraction = TouristAttraction(
                    id: UUID(),
                    name: name,
                    description: place.formattedAddress,
                    category: category,
                    estimatedDuration: duration,
                    coordinates: TouristAttraction.Coordinates(
                        latitude: place.location.lat,
                        longitude: place.location.lng
                    ),
                    imageURL: imageURL,
                    tips: generateTips(for: category),
                    websiteURL: nil
                )
                
                attractions.append(attraction)
                seenNames.insert(name)
            }
        }
        
        // Sort attractions by category and limit to 30 total to ensure a good mix
        return Array(attractions.prefix(30))
    }
    
    private func estimateVisitDuration(type: String, name: String) -> TimeInterval {
        // Duration in minutes
        switch type.lowercased() {
        case "museum":
            return 180 // 3 hours
        case "art_gallery":
            return 120 // 2 hours
        case "park", "garden":
            return 90 // 1.5 hours
        case "church", "temple", "mosque", "religious":
            return 60 // 1 hour
        case "landmark", "monument":
            return 90 // 1.5 hours
        case "restaurant", "cafe":
            return 90 // 1.5 hours
        case "shopping_mall":
            return 120 // 2 hours
        case "amusement_park", "theme_park":
            return 300 // 5 hours
        case "zoo", "aquarium":
            return 240 // 4 hours
        default:
            // Check name for keywords that might indicate a major attraction
            let lowercaseName = name.lowercased()
            if lowercaseName.contains("palace") || lowercaseName.contains("castle") {
                return 180 // 3 hours
            } else if lowercaseName.contains("tower") || lowercaseName.contains("cathedral") {
                return 120 // 2 hours
            } else {
                return 90 // 1.5 hours default
            }
        }
    }
    
    private func getFallbackImageURL(for category: TouristAttraction.Category) -> String {
        switch category {
        case .museum:
            return "https://images.unsplash.com/photo-1518998053901-5348d3961a04?auto=format&fit=crop&w=800&q=80"
        case .cultural:
            return "https://images.unsplash.com/photo-1577083552431-6e5fd01988ec?auto=format&fit=crop&w=800&q=80"
        case .historical:
            return "https://images.unsplash.com/photo-1589828994425-a83f2f9b8488?auto=format&fit=crop&w=800&q=80"
        case .nature:
            return "https://images.unsplash.com/photo-1511497584788-876760111969?auto=format&fit=crop&w=800&q=80"
        case .entertainment:
            return "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=800&q=80"
        case .dining:
            return "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80"
        case .shopping:
            return "https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=800&q=80"
        case .religious:
            return "https://images.unsplash.com/photo-1548276145-69a9521f0499?auto=format&fit=crop&w=800&q=80"
        case .architecture:
            return "https://images.unsplash.com/photo-1487958449943-2429e8be8625?auto=format&fit=crop&w=800&q=80"
        case .park:
            return "https://images.unsplash.com/photo-1519331379826-f10be5486c6f?auto=format&fit=crop&w=800&q=80"
        }
    }
    
    private func generateTips(for category: TouristAttraction.Category) -> [String] {
        var tips = ["Check opening hours before visiting"]
        
        switch category {
        case .museum:
            tips.append(contentsOf: [
                "Consider guided tours for better experience",
                "Check for special exhibitions",
                "Many museums have free or discounted days"
            ])
        case .cultural:
            tips.append(contentsOf: [
                "Book tickets in advance for shows",
                "Check for local events and festivals",
                "Research cultural etiquette"
            ])
        case .historical:
            tips.append(contentsOf: [
                "Morning visits usually have fewer crowds",
                "Consider hiring a local guide",
                "Photography may be restricted in some areas"
            ])
        case .nature:
            tips.append(contentsOf: [
                "Check weather forecast before visiting",
                "Bring appropriate footwear",
                "Carry water and snacks"
            ])
        case .entertainment:
            tips.append(contentsOf: [
                "Book tickets online to avoid queues",
                "Check for package deals",
                "Visit during off-peak hours"
            ])
        case .dining:
            tips.append(contentsOf: [
                "Reservations recommended",
                "Try local specialties",
                "Ask staff for recommendations"
            ])
        case .shopping:
            tips.append(contentsOf: [
                "Compare prices across shops",
                "Check return policies",
                "Ask about tax refund options"
            ])
        case .religious:
            tips.append(contentsOf: [
                "Dress modestly",
                "Check if visits are allowed during services",
                "Maintain quiet and respectful behavior"
            ])
        case .architecture:
            tips.append(contentsOf: [
                "Best photos usually early morning or sunset",
                "Look for guided architecture tours",
                "Check if interior visits are possible"
            ])
        case .park:
            tips.append(contentsOf: [
                "Early morning or late afternoon best for photos",
                "Check for seasonal attractions",
                "Bring picnic supplies"
            ])
        }
        
        return tips
    }
    
    private func determineCategory(from types: [String]) -> TouristAttraction.Category {
        // Map Google Places types to our categories
        if types.contains("museum") {
            return .museum
        } else if types.contains("park") || types.contains("natural_feature") {
            return .nature
        } else if types.contains("church") || types.contains("mosque") || types.contains("temple") {
            return .religious
        } else if types.contains("restaurant") || types.contains("cafe") {
            return .dining
        } else if types.contains("shopping_mall") || types.contains("store") {
            return .shopping
        } else if types.contains("tourist_attraction") || types.contains("point_of_interest") {
            return .historical
        } else if types.contains("art_gallery") || types.contains("theater") {
            return .cultural
        } else if types.contains("amusement_park") || types.contains("stadium") {
            return .entertainment
        } else if types.contains("building") {
            return .architecture
        }
        
        // Default category
        return .historical
    }
    
    // Find the best hotel in a city
    func findBestHotel(in city: City) async throws -> Hotel? {
        let searchQuery = "best hotels in \(city.name)"
        let places = try await searchPlaces(query: searchQuery)
        
        guard let bestPlace = places.first else {
            return nil
        }
        
        // Get detailed information about the hotel
        let details = try await getPlaceDetails(placeId: bestPlace.placeId)
        
        return Hotel(
            id: UUID(),
            name: details.name,
            description: "A highly-rated hotel in \(city.name)",
            address: details.formattedAddress,
            rating: details.rating,
            imageURL: details.photos?.first?.photoReference,
            coordinates: CLLocationCoordinate2D(
                latitude: details.geometry.location.lat,
                longitude: details.geometry.location.lng
            ),
            amenities: ["WiFi", "Restaurant", "Room Service", "Fitness Center"],
            websiteURL: details.website,
            phoneNumber: nil,
            priceLevel: mapGooglePriceLevel(details.priceLevel)
        )
    }
    
    private func mapGooglePriceLevel(_ priceLevel: Int?) -> Hotel.PriceLevel {
        switch priceLevel {
        case 0, 1: return .budget
        case 2: return .moderate
        case 3: return .luxury
        case 4: return .ultraLuxury
        default: return .moderate
        }
    }
}

// MARK: - API Response Models

struct PlacesResponse: Codable {
    let results: [PlaceResult]
    let status: String
}

struct PlaceResult: Codable {
    let placeId: String
    let name: String
    let formattedAddress: String
    let geometry: Geometry
    let types: [String]
    let rating: Double?
    let userRatingsTotal: Int?
    let priceLevel: Int?
    let openingHours: OpeningHours?
    let photos: [PhotoResult]?
    let website: String?
    
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case formattedAddress = "formatted_address"
        case geometry
        case types
        case rating
        case userRatingsTotal = "user_ratings_total"
        case priceLevel = "price_level"
        case openingHours = "opening_hours"
        case photos
        case website
    }
}

struct Geometry: Codable {
    let location: Location
}

struct Location: Codable {
    let lat: Double
    let lng: Double
}

struct OpeningHours: Codable {
    let openNow: Bool
    
    enum CodingKeys: String, CodingKey {
        case openNow = "open_now"
    }
}

struct PhotoResult: Codable {
    let photoReference: String
    
    enum CodingKeys: String, CodingKey {
        case photoReference = "photo_reference"
    }
}

struct PlaceDetails: Codable {
    let name: String
    let formattedAddress: String
    let geometry: Geometry
    let types: [String]
    let rating: Double?
    let userRatingsTotal: Int?
    let priceLevel: Int?
    let openingHours: OpeningHours?
    let photos: [PhotoResult]?
    let website: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case formattedAddress = "formatted_address"
        case geometry
        case types
        case rating
        case userRatingsTotal = "user_ratings_total"
        case priceLevel = "price_level"
        case openingHours = "opening_hours"
        case photos
        case website
    }
}

// MARK: - App Models

struct Place {
    let placeId: String
    let displayName: DisplayName
    let formattedAddress: String
    let location: Location
    let types: [String]
    let photos: [Photo]?
}

struct DisplayName {
    let text: String
}

struct Photo {
    let photoURL: String
}

enum PlacesAPIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        }
    }
} 