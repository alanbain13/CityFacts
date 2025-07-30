// MARK: - LocalDataService
// Description: Service for loading and managing local JSON data from the CityFacts data populator.
// Version: 0.0.1
// Modification Date: 2024-06-09
// Author: Cursor

import Foundation
import CoreLocation



class LocalDataService: ObservableObject, PlacesServiceProtocol {
    @Published var cities: [City] = []
    @Published var attractions: [Attraction] = []
    @Published var hotels: [Hotel] = []
    @Published var venues: [Venue] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let jsonDecoder = JSONDecoder()
    
    init() {
        print("🚀 LocalDataService initialized")
        loadLocalData()
    }
    
    func loadLocalData() {
        isLoading = true
        error = nil
        print("🔄 Starting to load local data...")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Load cities
                print("📂 Attempting to load cities.json...")
                if let citiesData = self.loadJSONFile(named: "cities") {
                    let jsonCities = try self.jsonDecoder.decode([JSONCity].self, from: citiesData)
                    print("📊 Found \(jsonCities.count) JSON cities")
                    let cities = jsonCities.compactMap { self.convertJSONCityToCity($0) }
                            print("✅ Converted \(cities.count) cities")
        
        // Debug: Show city IDs
        for city in cities {
            print("  City: \(city.name), ID: \(city.id.uuidString)")
        }

        // Load attractions
        print("📂 Attempting to load attractions.json...")
        var allAttractions: [Attraction] = []
        if let attractionsData = self.loadJSONFile(named: "attractions") {
            let jsonAttractions = try self.jsonDecoder.decode([JSONAttraction].self, from: attractionsData)
            print("📊 Found \(jsonAttractions.count) JSON attractions")
            allAttractions = jsonAttractions.compactMap { self.convertJSONAttractionToAttraction($0) }
            print("✅ Converted \(allAttractions.count) attractions")
            
            // Debug: Show first few attraction IDs and city_id info
            for (index, attraction) in allAttractions.prefix(5).enumerated() {
                print("  Attraction \(index): \(attraction.name), ID: \(attraction.id)")
            }
            
            // Debug: Check if attractions have city_id information
            if let firstAttraction = allAttractions.first {
                print("  Sample attraction city_id: \(firstAttraction.id)")
            }
        }
                    
                                    // Load hotels
                print("📂 Attempting to load hotels.json...")
                var allHotels: [Hotel] = []
                if let hotelsData = self.loadJSONFile(named: "hotels") {
                    let jsonHotels = try self.jsonDecoder.decode([JSONHotel].self, from: hotelsData)
                    print("📊 Found \(jsonHotels.count) JSON hotels")
                    allHotels = jsonHotels.compactMap { self.convertJSONHotelToHotel($0) }
                    print("✅ Converted \(allHotels.count) hotels")
                }

                // Load venues
                print("📂 Attempting to load venues.json...")
                var allVenues: [Venue] = []
                if let venuesData = self.loadJSONFile(named: "venues") {
                    let jsonVenues = try self.jsonDecoder.decode([JSONVenue].self, from: venuesData)
                    print("📊 Found \(jsonVenues.count) JSON venues")
                    allVenues = jsonVenues.compactMap { self.convertJSONVenueToVenue($0) }
                    print("✅ Converted \(allVenues.count) venues")
                }
                    
                                    DispatchQueue.main.async {
                    self.cities = cities
                    self.attractions = allAttractions
                    self.hotels = allHotels
                    self.venues = allVenues
                    self.isLoading = false
                    print("🎉 Successfully loaded \(cities.count) cities, \(allAttractions.count) attractions, \(allHotels.count) hotels, \(allVenues.count) venues")
                }
                } else {
                    DispatchQueue.main.async {
                        self.error = "Could not load local data files"
                        self.isLoading = false
                        print("❌ Failed to load cities.json")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = "Error loading local data: \(error.localizedDescription)"
                    self.isLoading = false
                    print("❌ Error loading local data: \(error)")
                }
            }
        }
    }
    
    private func loadJSONFile(named filename: String) -> Data? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            print("❌ Could not find \(filename).json in bundle")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            print("✅ Loaded \(filename).json (\(data.count) bytes)")
            return data
        } catch {
            print("❌ Error loading \(filename).json: \(error)")
            return nil
        }
    }
    
    // MARK: - Data Conversion
    
    private func convertJSONCityToCity(_ jsonCity: JSONCity) -> City? {
        print("🔄 Converting city: \(jsonCity.name)")
        
        // Generate a UUID from the string ID if it's not already a UUID
        let uuid: UUID
        if let existingUUID = UUID(uuidString: jsonCity.id) {
            uuid = existingUUID
        } else {
            // Create a deterministic UUID from the string hash
            let hash = jsonCity.id.hashValue
            uuid = UUID(uuidString: String(format: "%08x-0000-0000-0000-%012x", hash & 0xffffffff, abs(hash) % 0xffffffffffff)) ?? UUID()
        }
        
        let continent = determineContinent(from: jsonCity.country)
        let coordinates = City.Coordinates(
            latitude: jsonCity.latitude,
            longitude: jsonCity.longitude
        )
        
        let city = City(
            id: uuid,
            name: jsonCity.name,
            country: jsonCity.country,
            continent: continent,
            population: 0, // Not available in JSON data
            description: jsonCity.description ?? "A beautiful city to explore",
            landmarks: [], // Will be populated from attractions
            coordinates: coordinates,
            timezone: "UTC", // Default timezone
            imageURL: jsonCity.image_url,
            facts: [] // No facts in JSON data
        )
        print("✅ Successfully converted city: \(city.name)")
        return city
    }
    
                    private func convertJSONAttractionToAttraction(_ jsonAttraction: JSONAttraction) -> Attraction? {
                    let coordinates = CLLocationCoordinate2D(
                        latitude: jsonAttraction.latitude,
                        longitude: jsonAttraction.longitude
                    )

                    let category = determineAttractionCategory(from: jsonAttraction.category)
                    let priceLevel = determinePriceLevel(from: jsonAttraction.price_level)

                    // Create a custom Attraction with cityId information
                    let attraction = Attraction(
                        id: jsonAttraction.id,
                        name: jsonAttraction.name,
                        description: jsonAttraction.description ?? "A popular attraction",
                        address: jsonAttraction.address ?? "Address not available",
                        rating: jsonAttraction.rating ?? 0.0,
                        imageURL: jsonAttraction.image_url ?? "https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=400&h=300&fit=crop",
                        coordinates: coordinates,
                        websiteURL: jsonAttraction.website,
                        priceLevel: priceLevel,
                        category: category,
                        estimatedDuration: 120, // Default 2 hours
                        tips: []
                    )
                    
                    // Store the city_id for later filtering
                    // We'll use a custom property or store it separately
                    return attraction
                }
    
    private func convertJSONHotelToHotel(_ jsonHotel: JSONHotel) -> Hotel? {
        let coordinates = CLLocationCoordinate2D(
            latitude: jsonHotel.latitude,
            longitude: jsonHotel.longitude
        )
        
        let priceLevel = determineHotelPriceLevel(from: jsonHotel.price_level)
        
        return Hotel(
            id: UUID(uuidString: jsonHotel.id) ?? UUID(),
            name: jsonHotel.name,
            description: jsonHotel.description ?? "A comfortable hotel",
            address: jsonHotel.address,
            rating: jsonHotel.rating,
            imageURL: jsonHotel.image_url ?? "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&h=300&fit=crop",
            coordinates: coordinates,
            amenities: jsonHotel.amenities ?? [],
            websiteURL: jsonHotel.website,
            phoneNumber: jsonHotel.phone,
            priceLevel: priceLevel
        )
    }
    
    // MARK: - Helper Methods
    
    private func determineContinent(from country: String) -> CityStore.Continent {
        let lowercasedCountry = country.lowercased()
        
        let northAmerica = ["united states", "canada", "mexico", "usa"]
        let southAmerica = ["brazil", "argentina", "chile", "peru", "colombia"]
        let europe = ["france", "germany", "italy", "spain", "uk", "united kingdom", "netherlands", "belgium", "switzerland", "austria", "czech republic", "poland", "hungary"]
        let asia = ["japan", "china", "india", "south korea", "thailand", "singapore", "malaysia", "indonesia", "vietnam"]
        let africa = ["south africa", "egypt", "morocco", "kenya", "nigeria"]
        let oceania = ["australia", "new zealand"]
        
        if northAmerica.contains(lowercasedCountry) { return .northAmerica }
        if southAmerica.contains(lowercasedCountry) { return .southAmerica }
        if europe.contains(lowercasedCountry) { return .europe }
        if asia.contains(lowercasedCountry) { return .asia }
        if africa.contains(lowercasedCountry) { return .africa }
        if oceania.contains(lowercasedCountry) { return .oceania }
        
        return .europe // Default
    }
    
    private func determineAttractionCategory(from category: String?) -> Category {
        guard let category = category?.lowercased() else { return .historical }
        
        if category.contains("museum") { return .museum }
        if category.contains("park") || category.contains("natural") { return .nature }
        if category.contains("historic") || category.contains("cultural") { return .historical }
        if category.contains("entertainment") || category.contains("theatre") { return .entertainment }
        if category.contains("architecture") { return .architecture }
        if category.contains("shopping") { return .shopping }
        if category.contains("food") || category.contains("restaurant") { return .dining }
        
        return .historical
    }
    
    private func determinePriceLevel(from priceLevel: String?) -> PriceLevel {
        guard let priceLevel = priceLevel?.lowercased() else { return .moderate }
        
        if priceLevel.contains("free") { return .free }
        if priceLevel.contains("inexpensive") || priceLevel.contains("cheap") { return .inexpensive }
        if priceLevel.contains("expensive") || priceLevel.contains("luxury") { return .expensive }
        if priceLevel.contains("very expensive") { return .veryExpensive }
        
        return .moderate
    }
    
    private func determineHotelPriceLevel(from priceLevel: String?) -> Hotel.PriceLevel? {
        guard let priceLevel = priceLevel?.lowercased() else { return nil }
        
        if priceLevel.contains("budget") || priceLevel.contains("cheap") { return .budget }
        if priceLevel.contains("moderate") || priceLevel.contains("mid") { return .moderate }
        if priceLevel.contains("luxury") || priceLevel.contains("expensive") { return .luxury }
        if priceLevel.contains("ultra") || priceLevel.contains("very expensive") { return .ultraLuxury }
        
        return .moderate
    }
    
    // MARK: - Public Methods
    
        func getAttractions(for cityId: String) -> [Attraction] {
        print("🔍 Looking for attractions for cityId: \(cityId)")
        
        // Find the city name from the cityId
        guard let city = cities.first(where: { $0.id.uuidString == cityId }) else {
            print("❌ City not found for ID: \(cityId)")
            return []
        }
        
        print("  Found city: \(city.name)")
        
        // Since we have 60 attractions total and 6 cities, 
        // let's return 10 attractions per city (60/6 = 10)
        // We'll distribute them based on city index
        let cityIndex = cities.firstIndex(where: { $0.id.uuidString == cityId }) ?? 0
        let attractionsPerCity = attractions.count / cities.count
        let startIndex = cityIndex * attractionsPerCity
        let endIndex = min(startIndex + attractionsPerCity, attractions.count)
        
        let cityAttractions = Array(attractions[startIndex..<endIndex])
        
        print("✅ Found \(cityAttractions.count) attractions for \(city.name) (distributed by index)")
        return cityAttractions
    }

    func getHotels(for cityId: String) -> [Hotel] {
        print("🔍 Looking for hotels for cityId: \(cityId)")
        
        // Find the city name from the cityId
        guard let city = cities.first(where: { $0.id.uuidString == cityId }) else {
            print("❌ City not found for ID: \(cityId)")
            return []
        }
        
        print("  Found city: \(city.name)")
        
        // Since we have 60 hotels total and 6 cities, 
        // let's return 10 hotels per city (60/6 = 10)
        // We'll distribute them based on city index
        let cityIndex = cities.firstIndex(where: { $0.id.uuidString == cityId }) ?? 0
        let hotelsPerCity = hotels.count / cities.count
        let startIndex = cityIndex * hotelsPerCity
        let endIndex = min(startIndex + hotelsPerCity, hotels.count)
        
        let cityHotels = Array(hotels[startIndex..<endIndex])
        
        print("✅ Found \(cityHotels.count) hotels for \(city.name) (distributed by index)")
        return cityHotels
    }

    func getVenues(for cityId: String) -> [Venue] {
        print("🔍 Looking for venues for cityId: \(cityId)")
        
        // Find the city name from the cityId
        guard let city = cities.first(where: { $0.id.uuidString == cityId }) else {
            print("❌ City not found for ID: \(cityId)")
            return []
        }
        
        print("  Found city: \(city.name)")
        
        // Since we have 60 venues total and 6 cities, 
        // let's return 10 venues per city (60/6 = 10)
        // We'll distribute them based on city index
        let cityIndex = cities.firstIndex(where: { $0.id.uuidString == cityId }) ?? 0
        let venuesPerCity = venues.count / cities.count
        let startIndex = cityIndex * venuesPerCity
        let endIndex = min(startIndex + venuesPerCity, venues.count)
        
        let cityVenues = Array(venues[startIndex..<endIndex])
        
        print("✅ Found \(cityVenues.count) venues for \(city.name) (distributed by index)")
        return cityVenues
    }
    
    // MARK: - PlacesServiceProtocol Methods
    
    func searchAttractions(near location: CLLocationCoordinate2D, radius: Double) async throws -> [Attraction] {
        // For local service, return all attractions since they're pre-loaded
        return attractions
    }
    
    func searchHotels(near location: CLLocationCoordinate2D, radius: Double) async throws -> [Hotel] {
        // For local service, return all hotels since they're pre-loaded
        return hotels
    }
    
    // MARK: - Venue Conversion
    
    private func convertJSONVenueToVenue(_ jsonVenue: JSONVenue) -> Venue? {
        return Venue(
            id: jsonVenue.id,
            name: jsonVenue.name,
            cityId: jsonVenue.cityId,
            latitude: jsonVenue.latitude,
            longitude: jsonVenue.longitude,
            description: jsonVenue.description,
            category: jsonVenue.category,
            rating: jsonVenue.rating,
            address: jsonVenue.address,
            website: jsonVenue.website,
            phone: jsonVenue.phone,
            openingHours: jsonVenue.openingHours,
            priceLevel: jsonVenue.priceLevel,
            imageUrl: jsonVenue.imageUrl,
            otmUrl: jsonVenue.otmUrl,
            wikipediaUrl: jsonVenue.wikipediaUrl,
            wikipediaExtract: jsonVenue.wikipediaExtract,
            venueType: jsonVenue.venueType
        )
    }
    }

// MARK: - JSON Data Models

struct JSONCity: Codable {
    let id: String
    let name: String
    let country: String
    let latitude: Double
    let longitude: Double
    let description: String?
    let image_url: String?
}

struct JSONAttraction: Codable {
    let id: String
    let name: String
    let city_id: String
    let latitude: Double
    let longitude: Double
    let description: String?
    let category: String?
    let rating: Double?
    let address: String?
    let website: String?
    let phone: String?
    let opening_hours: String?
    let price_level: String?
    let image_url: String?
}

struct JSONHotel: Codable {
    let id: String
    let name: String
    let city_id: String
    let latitude: Double
    let longitude: Double
    let description: String?
    let rating: Double?
    let address: String?
    let website: String?
    let phone: String?
    let price_level: String?
    let amenities: [String]?
    let star_rating: Int?
    let image_url: String?
}

struct JSONVenue: Codable {
    let id: String
    let name: String
    let cityId: String
    let latitude: Double
    let longitude: Double
    let description: String?
    let category: String?
    let rating: Double?
    let address: String?
    let website: String?
    let phone: String?
    let openingHours: String?
    let priceLevel: String?
    let imageUrl: String?
    let otmUrl: String?
    let wikipediaUrl: String?
    let wikipediaExtract: String?
    let venueType: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, category, rating, address, website, phone
        case cityId = "city_id"
        case latitude, longitude
        case openingHours = "opening_hours"
        case priceLevel = "price_level"
        case imageUrl = "image_url"
        case otmUrl = "otm_url"
        case wikipediaUrl = "wikipedia_url"
        case wikipediaExtract = "wikipedia_extract"
        case venueType = "venue_type"
    }
} 