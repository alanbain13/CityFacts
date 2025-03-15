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
        
        // First, get the city's actual landmarks
        var attractions = city.landmarks.map { landmark in
            TouristAttraction(
                id: UUID(),
                name: landmark.name,
                description: landmark.description,
                category: .historical,
                estimatedDuration: 120,
                coordinates: TouristAttraction.Coordinates(
                    latitude: city.coordinates.latitude,
                    longitude: city.coordinates.longitude
                ),
                imageURL: landmark.imageURL,
                tips: ["Best time to visit: Early morning", "Photography allowed"],
                websiteURL: nil
            )
        }
        
        // Then, fetch nearby tourist attractions using the Places API
        let searchQuery = "tourist attractions in \(city.name)"
        let places = try await searchPlaces(query: searchQuery)
        
        // Convert Places to TouristAttractions
        for place in places {
            // Determine the category based on the place's types
            let category = determineCategory(from: place.types)
            
            // Get the first photo URL if available
            let imageURL = place.photos?.first?.photoURL ?? "https://images.unsplash.com/photo-1511818966892-d7d671e672a2"
            
            let attraction = TouristAttraction(
                id: UUID(),
                name: place.displayName.text,
                description: place.formattedAddress,
                category: category,
                estimatedDuration: 120, // Default duration
                coordinates: TouristAttraction.Coordinates(
                    latitude: place.location.latitude,
                    longitude: place.location.longitude
                ),
                imageURL: imageURL,
                tips: ["Check opening hours", "Plan your visit"],
                websiteURL: nil
            )
            
            attractions.append(attraction)
        }
        
        // Limit to 20 attractions total
        return Array(attractions.prefix(20))
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
        guard let uri = uri else { 
            print("Photo URI is nil")
            return nil 
        }
        
        print("Processing photo URI: \(uri)")
        
        // The Places API returns URIs in the format: "https://lh3.googleusercontent.com/..."
        // We need to ensure it's a valid URL and add the maxwidth parameter
        if uri.hasPrefix("https://") || uri.hasPrefix("http://") {
            print("Found full URL, adding maxwidth parameter")
            // If it's already a full URL, just add the maxwidth parameter
            if let url = URL(string: uri) {
                var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
                components?.queryItems = [URLQueryItem(name: "maxwidth", value: "800")]
                if let finalURL = components?.url {
                    let urlString = finalURL.absoluteString
                    print("Generated URL: \(urlString)")
                    return urlString
                }
            }
        } else {
            print("Found photo reference, constructing full URL")
            // If it's just a path, construct the full URL using the Places API photo endpoint
            if let url = GooglePlacesConfig.buildPhotoURL(photoReference: uri) {
                let urlString = url.absoluteString
                print("Generated URL: \(urlString)")
                return urlString
            }
        }
        print("Failed to generate valid URL")
        return nil
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
