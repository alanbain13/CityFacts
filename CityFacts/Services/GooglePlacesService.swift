import Foundation
import CoreLocation

class GooglePlacesService {
    static let shared = GooglePlacesService()
    
    private init() {}
    
    // Search for places by text query
    func searchPlaces(query: String, type: String? = nil) async throws -> [Place] {
        print("\n=== Starting searchPlaces ===")
        print("Query: \(query)")
        let endpoint = GooglePlacesConfig.searchEndpoint
        
        var requestBody: [String: Any] = [
            "textQuery": query
        ]
        
        guard let url = GooglePlacesConfig.buildURL(endpoint: endpoint) else {
            print("❌ Failed to build URL for endpoint: \(endpoint)")
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(GooglePlacesConfig.apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("places.id,places.displayName,places.formattedAddress,places.location,places.types,places.photos.name,places.photos.widthPx,places.photos.heightPx,places.primaryType,places.primaryTypeDisplayName", forHTTPHeaderField: "X-Goog-FieldMask")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("❌ Failed to serialize request body: \(error)")
            throw NetworkError.apiError(message: "Failed to serialize request: \(error.localizedDescription)")
        }
        
        print("\n=== Making API Request ===")
        print("URL: \(url)")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let httpBody = request.httpBody {
            print("Body: \(String(decoding: httpBody, as: UTF8.self))")
        } else {
            print("Body: nil")
        }
        
        do {
            print("\n=== Starting Network Request ===")
            let (data, response) = try await URLSession.shared.data(for: request)
            print("Network request completed")
            
            if let httpResponse = response as? HTTPURLResponse {
                print("\n=== API Response ===")
                print("Status Code: \(httpResponse.statusCode)")
                print("Headers: \(httpResponse.allHeaderFields)")
                
                print("Raw Response: \(String(decoding: data, as: UTF8.self))")
                
                if httpResponse.statusCode != 200 {
                    print("❌ API Error: HTTP \(httpResponse.statusCode)")
                    let errorString = String(decoding: data, as: UTF8.self)
                    print("Error details: \(errorString)")
                    throw NetworkError.apiError(message: "HTTP \(httpResponse.statusCode): \(errorString)")
                }
            } else {
                // print("❌ Invalid response type: \(type(of: response))")
                throw NetworkError.apiError(message: "Invalid response type")
            }
            
            print("\n=== Decoding Response ===")
            let decoder = JSONDecoder()
            do {
                let response = try decoder.decode(PlacesResponse.self, from: data)
                print("Successfully decoded \(response.places.count) places")
                
                // Log details of each place
                for (index, place) in response.places.enumerated() {
                    print("\nPlace \(index + 1):")
                    print("  ID: \(place.id)")
                    print("  Name: \(place.displayName.text)")
                    print("  Address: \(place.formattedAddress)")
                    print("  Types: \(place.types)")
                    if let photos = place.photos {
                        print("  Photos: \(photos.count)")
                        for (photoIndex, photo) in photos.enumerated() {
                            print("    Photo \(photoIndex + 1):")
                            print("      Name: \(photo.name)")
                            print("      URI: \(photo.uri ?? "nil")")
                            print("      Width: \(photo.widthPx ?? 0)")
                            print("      Height: \(photo.heightPx ?? 0)")
                            if let photoURL = photo.photoURL {
                                print("      Generated URL: \(photoURL)")
                            }
                        }
                    } else {
                        print("  No photos available")
                    }
                }
                
                return response.places
            } catch {
                print("\n❌ Decoding Error: \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("Missing key: \(key.stringValue)")
                        print("Coding path: \(context.codingPath)")
                    case .typeMismatch(let type, let context):
                        print("Type mismatch: expected \(type)")
                        print("Coding path: \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("Value not found: expected \(type)")
                        print("Coding path: \(context.codingPath)")
                    case .dataCorrupted(let context):
                        print("Data corrupted: \(context.debugDescription)")
                    @unknown default:
                        print("Unknown decoding error")
                    }
                }
                throw NetworkError.apiError(message: "Failed to decode response: \(error.localizedDescription)")
            }
        } catch let error as URLError {
            print("\n❌ URL Error: \(error)")
            print("Error code: \(error.code)")
            print("Error description: \(error.localizedDescription)")
            print("Error user info: \(error.userInfo)")
            throw NetworkError.apiError(message: "URL Error: \(error.localizedDescription)")
        } catch {
            print("\n❌ Network Error: \(error)")
            // print("Error type: \(type(of: error))")
            throw error
        }
    }
    
    // Get nearby places
    func getNearbyPlaces(location: CLLocationCoordinate2D, radius: Int = 5000, types: [String]? = nil) async throws -> [Place] {
        let endpoint = GooglePlacesConfig.nearbyEndpoint
        
        var requestBody: [String: Any] = [
            "locationRestriction": [
                "circle": [
                    "center": [
                        "latitude": location.latitude,
                        "longitude": location.longitude
                    ],
                    "radius": radius
                ]
            ]
        ]
        
        guard let url = GooglePlacesConfig.buildURL(endpoint: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(GooglePlacesConfig.apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("places.id,places.displayName,places.formattedAddress,places.location,places.types,places.photos.name,places.photos.widthPx,places.photos.heightPx,places.primaryType,places.primaryTypeDisplayName", forHTTPHeaderField: "X-Goog-FieldMask")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("❌ Failed to serialize request body: \(error)")
            throw NetworkError.apiError(message: "Failed to serialize request: \(error.localizedDescription)")
        }
        
        print("Fetching nearby places with URL: \(url)")
        print("Request headers: \(request.allHTTPHeaderFields ?? [:])")
        if let httpBody = request.httpBody,
           let bodyString = String(data: httpBody, encoding: .utf8) {
            print("Request body: \(bodyString)")
        } else {
            print("Request body: nil")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                print("Response headers: \(httpResponse.allHeaderFields)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Raw response data: \(responseString)")
                }
                
                if httpResponse.statusCode != 200 {
                    if let errorString = String(data: data, encoding: .utf8) {
                        throw NetworkError.apiError(message: "HTTP \(httpResponse.statusCode): \(errorString)")
                    }
                    throw NetworkError.apiError(message: "HTTP \(httpResponse.statusCode)")
                }
            }
            
            let decoder = JSONDecoder()
            let placesResponse = try decoder.decode(PlacesResponse.self, from: data)
            print("Successfully decoded \(placesResponse.places.count) nearby places")
            return placesResponse.places
        } catch {
            print("Error fetching nearby places: \(error)")
            throw error
        }
    }
    
    // Get place details
    func getPlaceDetails(placeId: String) async throws -> PlaceDetails {
        let endpoint = "\(GooglePlacesConfig.detailsEndpoint)/\(placeId)"
        
        guard let url = GooglePlacesConfig.buildURL(endpoint: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(GooglePlacesConfig.apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("places.id,places.displayName,places.formattedAddress,places.location,places.types,places.photos.name,places.photos.widthPx,places.photos.heightPx,places.primaryType,places.primaryTypeDisplayName", forHTTPHeaderField: "X-Goog-FieldMask")
        
        print("Fetching place details with URL: \(url)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode != 200 {
                if let errorString = String(data: data, encoding: .utf8) {
                    throw NetworkError.apiError(message: "HTTP \(httpResponse.statusCode): \(errorString)")
                }
                throw NetworkError.apiError(message: "HTTP \(httpResponse.statusCode)")
            }
        }
        
        return try JSONDecoder().decode(PlaceDetails.self, from: data)
    }
    
    // Fetch tourist attractions for a city
    func fetchTouristAttractions(for city: City) async throws -> [TouristAttraction] {
        print("\n=== Fetching Tourist Attractions for \(city.name) ===")
        
        // Create a set to track unique place names to prevent duplicates
        var seenNames = Set<String>()
        var attractions: [TouristAttraction] = []
        
        // First, search for the city's landmarks using Places API to get proper photos
        for landmark in city.landmarks {
            print("Searching for landmark: \(landmark.name)")
            let searchQuery = "\(landmark.name) in \(city.name)"
            let places = try await searchPlaces(query: searchQuery)
            
            if let place = places.first {
                // Use the first matching place
                let imageURL = place.photos?.first?.photoURL ?? getFallbackImageURL(for: .historical)
                
                let attraction = TouristAttraction(
                    id: UUID(),
                    name: landmark.name,
                    description: landmark.description,
                    category: .historical,
                    estimatedDuration: estimateVisitDuration(type: "landmark", name: landmark.name),
                    coordinates: TouristAttraction.Coordinates(
                        latitude: place.location.latitude,
                        longitude: place.location.longitude
                    ),
                    imageURL: imageURL,
                    tips: generateTips(for: .historical),
                    websiteURL: nil
                )
                attractions.append(attraction)
                seenNames.insert(landmark.name)
            } else {
                // Fallback to original landmark data if no match found
                print("No Places API match found for landmark: \(landmark.name)")
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
                    imageURL: landmark.imageURL ?? getFallbackImageURL(for: .historical),
                    tips: generateTips(for: .historical),
                    websiteURL: nil
                )
                attractions.append(attraction)
                seenNames.insert(landmark.name)
            }
        }
        
        // Then, fetch nearby tourist attractions using the Places API
        let searchQuery = "top tourist attractions in \(city.name)"
        let places = try await searchPlaces(query: searchQuery)
        
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
                    print("Using place photo URL: \(firstPhotoURL)")
                } else {
                    print("Failed to get photo URL for place: \(name)")
                }
            }
            
            let attraction = TouristAttraction(
                id: UUID(),
                name: name,
                description: place.formattedAddress,
                category: category,
                estimatedDuration: duration,
                coordinates: TouristAttraction.Coordinates(
                    latitude: place.location.latitude,
                    longitude: place.location.longitude
                ),
                imageURL: imageURL,
                tips: generateTips(for: category),
                websiteURL: nil
            )
            
            attractions.append(attraction)
            seenNames.insert(name)
        }
        
        // Sort attractions by category and limit to 15 total to ensure a good mix
        return Array(attractions.prefix(15))
    }
    
    private func estimateVisitDuration(type: String, name: String) -> TimeInterval {
        // Convert minutes to seconds (TimeInterval)
        let minutesToSeconds: (Int) -> TimeInterval = { minutes in
            TimeInterval(minutes * 60)
        }
        
        // Duration in minutes, converted to seconds
        switch type.lowercased() {
        case "museum":
            return minutesToSeconds(180) // 3 hours
        case "art_gallery":
            return minutesToSeconds(120) // 2 hours
        case "park", "garden":
            return minutesToSeconds(90) // 1.5 hours
        case "church", "temple", "mosque", "religious":
            return minutesToSeconds(60) // 1 hour
        case "landmark", "monument":
            return minutesToSeconds(90) // 1.5 hours
        case "restaurant", "cafe":
            return minutesToSeconds(90) // 1.5 hours
        case "shopping_mall":
            return minutesToSeconds(120) // 2 hours
        case "amusement_park", "theme_park":
            return minutesToSeconds(300) // 5 hours
        case "zoo", "aquarium":
            return minutesToSeconds(240) // 4 hours
        default:
            // Check name for keywords that might indicate a major attraction
            let lowercaseName = name.lowercased()
            if lowercaseName.contains("palace") || lowercaseName.contains("castle") {
                return minutesToSeconds(180) // 3 hours
            } else if lowercaseName.contains("tower") || lowercaseName.contains("cathedral") {
                return minutesToSeconds(120) // 2 hours
            } else {
                return minutesToSeconds(90) // 1.5 hours default
            }
        }
    }
    
    private func getFallbackImageURL(for category: TouristAttraction.Category) -> String {
        switch category {
        case .museum:
            return "https://images.unsplash.com/photo-1518998053901-5348d3961a04"
        case .cultural:
            return "https://images.unsplash.com/photo-1577083552431-6e5fd01988ec"
        case .historical:
            return "https://images.unsplash.com/photo-1589828994425-a83f2f9b8488"
        case .nature:
            return "https://images.unsplash.com/photo-1511497584788-876760111969"
        case .entertainment:
            return "https://images.unsplash.com/photo-1514525253161-7a46d19cd819"
        case .dining:
            return "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4"
        case .shopping:
            return "https://images.unsplash.com/photo-1441986300917-64674bd600d8"
        case .religious:
            return "https://images.unsplash.com/photo-1548276145-69a9521f0499"
        case .architecture:
            return "https://images.unsplash.com/photo-1487958449943-2429e8be8625"
        case .park:
            return "https://images.unsplash.com/photo-1519331379826-f10be5486c6f"
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
}

// Response models for Places API (New)
struct PlacesResponse: Codable {
    let places: [Place]
    
    enum CodingKeys: String, CodingKey {
        case places
    }
}

struct Place: Codable {
    let id: String
    let displayName: DisplayName
    let formattedAddress: String
    let location: Location
    let types: [String]
    let photos: [Photo]?
    let primaryType: String?
    let primaryTypeDisplayName: DisplayName?
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "displayName"
        case formattedAddress = "formattedAddress"
        case location
        case types
        case photos
        case primaryType = "primaryType"
        case primaryTypeDisplayName = "primaryTypeDisplayName"
    }
}

struct DisplayName: Codable {
    let text: String
    let languageCode: String?
    
    enum CodingKeys: String, CodingKey {
        case text
        case languageCode = "languageCode"
    }
}

struct Location: Codable {
    let latitude: Double
    let longitude: Double
    
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
}

struct Photo: Codable {
    let name: String
    let uri: String?
    let widthPx: Int?
    let heightPx: Int?
    
    enum CodingKeys: String, CodingKey {
        case name
        case uri
        case widthPx = "widthPx"
        case heightPx = "heightPx"
    }
    
    var photoURL: String? {
        guard let name = name.components(separatedBy: "/").last else { 
            print("Photo name is invalid")
            return nil 
        }
        
        // Construct the Places Photo URL with the photo reference
        let baseURL = "https://places.googleapis.com/v1/"
        let maxWidth = 800 // Maximum width for photos
        let photoURL = "\(baseURL)\(self.name)/media?maxWidthPx=\(maxWidth)&key=\(GooglePlacesConfig.apiKey)"
        print("Generated photo URL: \(photoURL)")
        return photoURL
    }
}

struct PlaceDetails: Codable {
    let id: String
    let displayName: DisplayName
    let formattedAddress: String
    let location: Location
    let types: [String]
    let photos: [Photo]?
    let primaryType: String?
    let primaryTypeDisplayName: DisplayName?
    let websiteUri: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "displayName"
        case formattedAddress = "formattedAddress"
        case location
        case types
        case photos
        case primaryType = "primaryType"
        case primaryTypeDisplayName = "primaryTypeDisplayName"
        case websiteUri = "websiteUri"
    }
}

struct Review: Codable {
    let authorName: String
    let rating: Double
    let text: String
    let time: Int
    
    enum CodingKeys: String, CodingKey {
        case authorName = "author_name"
        case rating
        case text
        case time
    }
}

struct OpeningHours: Codable {
    let isOpen: Bool
    let periods: [Period]?
    
    enum CodingKeys: String, CodingKey {
        case isOpen = "open_now"
        case periods
    }
}

struct Period: Codable {
    let open: Time
    let close: Time?
}

struct Time: Codable {
    let day: Int
    let time: String
} 
