import Foundation
import CoreLocation

class GooglePlacesService {
    static let shared = GooglePlacesService()
    
    private init() {}
    
    // Search for places by text query
    func searchPlaces(query: String, type: String? = nil) async throws -> [Place] {
        Logger.info("Starting searchPlaces")
        Logger.debug("Query: \(query)")
        
        // Construct URL using URLComponents with base URL
        let fullEndpoint = GooglePlacesConfig.baseURL + GooglePlacesConfig.searchEndpoint
        guard var urlComponents = URLComponents(string: fullEndpoint) else {
            Logger.error("Failed to create URL components for endpoint: \(fullEndpoint)")
            throw NetworkError.invalidURL
        }
        
        // Add the API key as a query parameter
        urlComponents.queryItems = [
            URLQueryItem(name: "key", value: GooglePlacesConfig.apiKey)
        ]
        
        guard let url = urlComponents.url else {
            Logger.error("Failed to create URL from components")
            throw NetworkError.invalidURL
        }
        
        // Create request body with text query and type
        var requestBody: [String: Any] = [
            "textQuery": query
        ]
        
        // Add locationBias if searching for hotels
        if query.lowercased().contains("hotel") {
            requestBody["includedType"] = "lodging"
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(GooglePlacesConfig.apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("places.id,places.displayName,places.formattedAddress,places.location,places.types,places.photos,places.primaryType,places.primaryTypeDisplayName,places.websiteUri,places.rating,places.priceLevel", forHTTPHeaderField: "X-Goog-FieldMask")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            Logger.error("Failed to serialize request body: \(error)")
            throw NetworkError.apiError(message: "Failed to serialize request: \(error.localizedDescription)")
        }
        
        Logger.debug("Making API Request")
        Logger.debug("URL: \(url)")
        
        do {
            Logger.debug("Starting Network Request")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                Logger.debug("Status Code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    Logger.error("API Error: HTTP \(httpResponse.statusCode)")
                    let errorString = String(decoding: data, as: UTF8.self)
                    Logger.error("Error details: \(errorString)")
                    throw NetworkError.apiError(message: "HTTP \(httpResponse.statusCode): \(errorString)")
                }
            }
            
            Logger.debug("Decoding Response")
            let decoder = JSONDecoder()
            do {
                let response = try decoder.decode(PlacesResponse.self, from: data)
                Logger.success("Successfully decoded \(response.places.count) places")
                return response.places
            } catch {
                Logger.error("Decoding Error: \(error)")
                throw NetworkError.apiError(message: "Failed to decode response: \(error.localizedDescription)")
            }
        } catch let error as URLError {
            Logger.error("URL Error: \(error)")
            throw NetworkError.apiError(message: "URL Error: \(error.localizedDescription)")
        } catch {
            Logger.error("Network Error: \(error)")
            throw error
        }
    }
    
    // Get nearby places
    func getNearbyPlaces(location: CLLocationCoordinate2D, radius: Int = 5000, types: [String]? = nil) async throws -> [Place] {
        Logger.info("Getting nearby places")
        Logger.debug("Location: \(location.latitude), \(location.longitude)")
        Logger.debug("Radius: \(radius)")
        Logger.debug("Types: \(types)")
        
        // Construct URL using URLComponents with base URL
        let fullEndpoint = GooglePlacesConfig.baseURL + GooglePlacesConfig.nearbyEndpoint
        guard var urlComponents = URLComponents(string: fullEndpoint) else {
            Logger.error("Failed to create URL components for endpoint: \(fullEndpoint)")
            throw NetworkError.invalidURL
        }
        
        // Add the API key as a query parameter
        urlComponents.queryItems = [
            URLQueryItem(name: "key", value: GooglePlacesConfig.apiKey)
        ]
        
        guard let url = urlComponents.url else {
            Logger.error("Failed to create URL from components")
            throw NetworkError.invalidURL
        }
        
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
        
        // Add includedTypes if specified
        if let types = types {
            requestBody["includedTypes"] = types
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(GooglePlacesConfig.apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("id,displayName,formattedAddress,location,types,photos.name,photos.widthPx,photos.heightPx,primaryType,primaryTypeDisplayName,websiteUri", forHTTPHeaderField: "X-Goog-FieldMask")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            Logger.error("Failed to serialize request body: \(error)")
            throw NetworkError.apiError(message: "Failed to serialize request: \(error.localizedDescription)")
        }
        
        Logger.debug("Fetching nearby places with URL: \(url)")
        Logger.debug("Request headers: \(request.allHTTPHeaderFields ?? [:])")
        if let httpBody = request.httpBody,
           let bodyString = String(data: httpBody, encoding: .utf8) {
            Logger.debug("Request body: \(bodyString)")
        } else {
            Logger.debug("Request body: nil")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                Logger.debug("HTTP Status Code: \(httpResponse.statusCode)")
                Logger.debug("Response headers: \(httpResponse.allHeaderFields)")
                if let responseString = String(data: data, encoding: .utf8) {
                    Logger.debug("Raw response data: \(responseString)")
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
            Logger.success("Successfully decoded \(placesResponse.places.count) nearby places")
            return placesResponse.places
        } catch {
            Logger.error("Error fetching nearby places: \(error)")
            throw error
        }
    }
    
    // Get place details
    func getPlaceDetails(placeId: String) async throws -> PlaceDetails {
        Logger.info("Getting place details for ID: \(placeId)")
        
        // Construct URL using URLComponents with base URL
        let fullEndpoint = GooglePlacesConfig.baseURL + GooglePlacesConfig.detailsEndpoint + "/" + placeId
        guard var urlComponents = URLComponents(string: fullEndpoint) else {
            Logger.error("Failed to create URL components for endpoint: \(fullEndpoint)")
            throw NetworkError.invalidURL
        }
        
        // Add the API key as a query parameter
        urlComponents.queryItems = [
            URLQueryItem(name: "key", value: GooglePlacesConfig.apiKey)
        ]
        
        guard let url = urlComponents.url else {
            Logger.error("Failed to create URL from components")
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(GooglePlacesConfig.apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("id,displayName,formattedAddress,location,types,photos.name,photos.widthPx,photos.heightPx,primaryType,primaryTypeDisplayName,websiteUri", forHTTPHeaderField: "X-Goog-FieldMask")
        
        Logger.debug("Fetching place details with URL: \(url)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            Logger.debug("HTTP Status Code: \(httpResponse.statusCode)")
            Logger.debug("Response headers: \(httpResponse.allHeaderFields)")
            if let responseString = String(data: data, encoding: .utf8) {
                Logger.debug("Raw response data: \(responseString)")
            }
            
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
        Logger.info("Finding Best Hotel in \(city.name)")
        
        let searchQuery = "best luxury hotel in \(city.name)"
        let places = try await searchPlaces(query: searchQuery)
        
        guard let bestHotel = places.first else {
            Logger.warning("No hotels found in \(city.name)")
            return nil
        }
        
        // Get additional details for the hotel
        let details = try await getPlaceDetails(placeId: bestHotel.id)
        
        // Determine price level based on the place's types
        let priceLevel: Hotel.PriceLevel?
        if bestHotel.types.contains("luxury") {
            priceLevel = .ultraLuxury
        } else if bestHotel.types.contains("upscale") {
            priceLevel = .luxury
        } else if bestHotel.types.contains("budget") {
            priceLevel = .budget
        } else {
            priceLevel = .moderate
        }
        
        // Get amenities based on place types
        var amenities = ["Wi-Fi", "Air Conditioning"]
        if bestHotel.types.contains("spa") { amenities.append("Spa") }
        if bestHotel.types.contains("restaurant") { amenities.append("Restaurant") }
        if bestHotel.types.contains("fitness_center") { amenities.append("Fitness Center") }
        if bestHotel.types.contains("swimming_pool") { amenities.append("Swimming Pool") }
        
        // Get the first photo URL or use a default image
        let imageURL = bestHotel.photos?.first?.photoURL
        
        let hotel = Hotel(
            id: UUID(),
            name: bestHotel.displayName.text,
            description: "Experience luxury and comfort at \(bestHotel.displayName.text), one of \(city.name)'s finest hotels.",
            address: bestHotel.formattedAddress,
            rating: nil, // Rating not available in the current API response
            imageURL: imageURL,
            coordinates: CLLocationCoordinate2D(
                latitude: bestHotel.location.latitude,
                longitude: bestHotel.location.longitude
            ),
            amenities: amenities,
            websiteURL: details.websiteUri,
            phoneNumber: nil, // Phone number not available in the current API response
            priceLevel: priceLevel
        )
        
        Logger.success("Successfully created hotel: \(hotel.name)")
        return hotel
    }
    
    // Add this enum before the searchCities method
    enum GooglePlacesError: Error {
        case invalidURL
        case invalidResponse
        case decodingError
    }
    
    /// Searches for cities using the Google Places API
    /// - Parameter query: The search query for the city
    /// - Returns: An array of City objects matching the search query
    func searchCities(query: String) async throws -> [City] {
        Logger.info("Starting searchCities")
        Logger.debug("Query: \(query)")
        
        let places = try await searchPlaces(query: query)
        
        // Filter places to only include cities and convert them to City objects
        let cities = places.compactMap { place -> City? in
            // Check if the place is a city (locality or administrative_area_level_1)
            guard place.types.contains("locality") || place.types.contains("administrative_area_level_1") else {
                return nil
            }
            
            let country = place.formattedAddress.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespaces) ?? ""
            
            // Create a City object
            return City(
                id: UUID(),
                name: place.displayName.text,
                country: country,
                continent: determineContinent(from: country),
                population: 0, // This would need to be fetched from another API
                description: "",
                landmarks: [],
                coordinates: City.Coordinates(latitude: place.location.latitude, longitude: place.location.longitude),
                timezone: "", // This would need to be determined based on coordinates
                imageURLs: place.photos?.compactMap { $0.photoURL } ?? [],
                facts: []
            )
        }
        
        Logger.success("Found \(cities.count) cities")
        return cities
    }
    
    // Helper function to determine continent from country
    private func determineContinent(from country: String) -> CityStore.Continent {
        let lowercasedCountry = country.lowercased()
        
        // North America
        if ["united states", "canada", "mexico", "usa", "us"].contains(where: { lowercasedCountry.contains($0) }) {
            return .northAmerica
        }
        
        // South America
        if ["brazil", "argentina", "chile", "peru", "colombia", "venezuela"].contains(where: { lowercasedCountry.contains($0) }) {
            return .southAmerica
        }
        
        // Europe
        if ["france", "germany", "italy", "spain", "uk", "united kingdom", "netherlands", "switzerland", "sweden", "norway", "denmark", "finland", "austria", "belgium", "portugal", "greece", "ireland", "poland", "czech", "hungary"].contains(where: { lowercasedCountry.contains($0) }) {
            return .europe
        }
        
        // Asia
        if ["china", "japan", "india", "korea", "thailand", "vietnam", "malaysia", "singapore", "indonesia", "philippines", "taiwan", "hong kong", "turkey", "israel", "uae", "saudi arabia", "qatar"].contains(where: { lowercasedCountry.contains($0) }) {
            return .asia
        }
        
        // Africa
        if ["south africa", "egypt", "morocco", "nigeria", "kenya", "ethiopia", "ghana", "tanzania", "uganda"].contains(where: { lowercasedCountry.contains($0) }) {
            return .africa
        }
        
        // Oceania
        if ["australia", "new zealand", "fiji", "samoa", "tonga"].contains(where: { lowercasedCountry.contains($0) }) {
            return .oceania
        }
        
        // Default to Europe if we can't determine
        return .europe
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
        // Correct format for Places API v1
        let baseURL = "https://places.googleapis.com/v1"
        let maxHeight = 800
        let photoURL = "\(baseURL)/\(name)/media?maxHeightPx=\(maxHeight)&key=\(GooglePlacesConfig.apiKey)"
        Logger.debug("Generated v1 photo URL: \(photoURL)")
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

// Add this structure for decoding the autocomplete response
struct PlacesAutocompleteResponse: Codable {
    let predictions: [Prediction]
    
    struct Prediction: Codable {
        let description: String
        let placeId: String
        
        enum CodingKeys: String, CodingKey {
            case description
            case placeId = "place_id"
        }
    }
} 
