import Foundation
import SwiftUI

@MainActor
class CityStore: ObservableObject {
    @Published var cities: [City] = []
    @Published var favoriteCityIds: Set<UUID> = {
        let savedIds = UserDefaults.standard.array(forKey: "FavoriteCities") as? [String] ?? []
        return Set(savedIds.compactMap { UUID(uuidString: $0) })
    }()
    
    @Published var searchText = ""
    @Published var selectedContinent: Continent?
    @Published var selectedPopulationRange: PopulationRange?
    @Published var isLoading = false
    
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
    
    func loadCities() {
        isLoading = true
        cities = Self.citiesData.sorted { $0.population > $1.population }
        isLoading = false
    }
    
    init() {
        loadCities()
    }
} 