import Foundation
import SwiftUI

@MainActor
class CityStore: ObservableObject {
    @Published var cities: [City] = []
    @Published var venues: [Venue] = []
    @Published var favoriteCityIds: Set<UUID> = {
        let savedIds = UserDefaults.standard.array(forKey: "FavoriteCities") as? [String] ?? []
        return Set(savedIds.compactMap { UUID(uuidString: $0) })
    }()

    @Published var searchText = ""
    @Published var selectedContinent: Continent?
    @Published var selectedPopulationRange: PopulationRange?
    @Published var isLoading = false
    
    // Service abstraction
    private var placesService: any PlacesServiceProtocol
    @Published var isPremiumUser: Bool
    
    // Public access to LocalDataService
    var localDataService: LocalDataService? {
        return placesService as? LocalDataService
    }
    
    init(isPremiumUser: Bool = false) {
        print("🏙️ CityStore initialized with isPremiumUser: \(isPremiumUser)")
        self.isPremiumUser = isPremiumUser
        self.placesService = PlacesServiceFactory.createService(
            type: isPremiumUser ? .premium : .local
        )
        
        // Load initial data
        if isPremiumUser {
            print("💰 Using premium data")
            cities = Self.citiesData.sorted { $0.population > $1.population }
        } else {
            print("📁 Using local data")
            // For local data, cities will be loaded by the LocalDataService
            cities = []
            
            // Observe local data service for cities
            if let localService = placesService as? LocalDataService {
                print("🔗 Connected to LocalDataService")
                // Start observing the local service
                Task { @MainActor in
                    await observeLocalData(localService)
                }
            } else {
                print("❌ Failed to connect to LocalDataService")
            }
        }
    }
    
    private func observeLocalData(_ localService: LocalDataService) async {
        print("👀 Starting to observe LocalDataService...")
        
        // Wait for local data to load
        var attempts = 0
        while localService.cities.isEmpty && attempts < 50 { // Wait up to 5 seconds
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            attempts += 1
            print("⏳ Waiting for local data... attempt \(attempts)")
        }
        
        // Update cities when data is loaded
        self.cities = localService.cities
        self.venues = localService.venues
        print("✅ Loaded \(localService.cities.count) cities and \(localService.venues.count) venues from local data")
        
        // Also check for errors
        if let error = localService.error {
            print("❌ LocalDataService error: \(error)")
        }
    }
    
    enum Continent: String, CaseIterable, Codable {
        case northAmerica = "North America"
        case southAmerica = "South America"
        case europe = "Europe"
        case asia = "Asia"
        case africa = "Africa"
        case oceania = "Oceania"
    }
    
    enum PopulationRange: String, CaseIterable {
        case small = "< 1M"
        case medium = "1M - 5M"
        case large = "5M - 10M"
        case megacity = "> 10M"
        
        func matches(_ population: Int) -> Bool {
            switch self {
            case .small: return population < 1_000_000
            case .medium: return population >= 1_000_000 && population < 5_000_000
            case .large: return population >= 5_000_000 && population < 10_000_000
            case .megacity: return population >= 10_000_000
            }
        }
    }
    
    var filteredCities: [City] {
        cities.filter { city in
            let matchesSearch = searchText.isEmpty || 
                city.name.localizedCaseInsensitiveContains(searchText) ||
                city.country.localizedCaseInsensitiveContains(searchText)
            
            let matchesContinent = selectedContinent == nil || city.continent == selectedContinent
            let matchesPopulation = selectedPopulationRange == nil || 
                selectedPopulationRange?.matches(city.population) == true
            
            return matchesSearch && matchesContinent && matchesPopulation
        }
    }
    
    func toggleFavorite(for city: City) {
        if favoriteCityIds.contains(city.id) {
            favoriteCityIds.remove(city.id)
        } else {
            favoriteCityIds.insert(city.id)
        }
        saveFavorites()
    }
    
    func isFavorite(_ city: City) -> Bool {
        favoriteCityIds.contains(city.id)
    }
    
    private func saveFavorites() {
        let favoriteIds = favoriteCityIds.map { $0.uuidString }
        UserDefaults.standard.set(favoriteIds, forKey: "FavoriteCities")
    }
    
    // MARK: - Data Access Methods
    
    func getAttractions(for city: City) async -> [Attraction] {
        if isPremiumUser {
            do {
                return try await placesService.searchAttractions(
                    near: city.location,
                    radius: 5000
                )
            } catch {
                print("Error fetching attractions: \(error)")
                return []
            }
        } else {
            return placesService.getAttractions(for: city.id.uuidString)
        }
    }
    
                    func getHotels(for city: City) async -> [Hotel] {
                    if isPremiumUser {
                        do {
                            return try await placesService.searchHotels(
                                near: city.location,
                                radius: 5000
                            )
                        } catch {
                            print("Error fetching hotels: \(error)")
                            return []
                        }
                    } else {
                        return placesService.getHotels(for: city.id.uuidString)
                    }
                }

                func getVenues(for city: City) async -> [Venue] {
                    if isPremiumUser {
                        // For premium mode, venues would come from Google Places API
                        return []
                    } else {
                        if let localService = placesService as? LocalDataService {
                            return localService.getVenues(for: city.id.uuidString)
                        }
                        return []
                    }
                }
    
    func switchToPremium() {
        isPremiumUser = true
        placesService = PlacesServiceFactory.createService(type: .premium)
        cities = Self.citiesData.sorted { $0.population > $1.population }
    }
    
    func switchToLocal() {
        isPremiumUser = false
        placesService = PlacesServiceFactory.createService(type: .local)
        cities = []
    }
} 