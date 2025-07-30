// MARK: - CityFactsModels
// Description: Additional data models for CityFacts app integration.
// Version: 0.0.1
// Modification Date: 2024-06-09
// Author: Cursor

import Foundation

// MARK: - Venue Model
struct Venue: Codable, Identifiable {
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

// MARK: - Data Manager for JSON Integration
class CityFactsDataManager: ObservableObject {
    @Published var cities: [City] = []
    @Published var venues: [Venue] = []
    @Published var attractions: [Attraction] = []
    @Published var hotels: [Hotel] = []
    
    private let jsonDecoder = JSONDecoder()
    
    init() {
        loadData()
    }
    
    func loadData() {
        loadCities()
        loadVenues()
        loadAttractions()
        loadHotels()
    }
    
    private func loadCities() {
        guard let url = Bundle.main.url(forResource: "cities", withExtension: "json") else {
            print("Could not find cities.json in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            cities = try jsonDecoder.decode([City].self, from: data)
        } catch {
            print("Error loading cities: \(error)")
        }
    }
    
    private func loadVenues() {
        guard let url = Bundle.main.url(forResource: "venues", withExtension: "json") else {
            print("Could not find venues.json in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            venues = try jsonDecoder.decode([Venue].self, from: data)
        } catch {
            print("Error loading venues: \(error)")
        }
    }
    
    private func loadAttractions() {
        guard let url = Bundle.main.url(forResource: "attractions", withExtension: "json") else {
            print("Could not find attractions.json in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            attractions = try jsonDecoder.decode([Attraction].self, from: data)
        } catch {
            print("Error loading attractions: \(error)")
        }
    }
    
    private func loadHotels() {
        guard let url = Bundle.main.url(forResource: "hotels", withExtension: "json") else {
            print("Could not find hotels.json in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            hotels = try jsonDecoder.decode([Hotel].self, from: data)
        } catch {
            print("Error loading hotels: \(error)")
        }
    }
} 