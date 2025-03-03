import Foundation
import CoreLocation

struct City: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let country: String
    let continent: CityStore.Continent
    let population: Int
    let description: String
    let landmarks: [Landmark]
    let coordinates: Coordinates
    let timezone: String
    let imageURLs: [String]
    let facts: [String]
    
    struct Coordinates: Codable, Hashable {
        let latitude: Double
        let longitude: Double
        
        var locationCoordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    var location: CLLocationCoordinate2D {
        coordinates.locationCoordinate
    }
}

extension City {
    static let preview = City(
        id: UUID(),
        name: "Paris",
        country: "France",
        continent: .europe,
        population: 2161000,
        description: "Paris is the capital and largest city of France, known for its art, culture, and historic landmarks.",
        landmarks: [
            Landmark(name: "Eiffel Tower", description: "Iconic iron lattice tower on the Champ de Mars", imageURL: "eiffel_tower"),
            Landmark(name: "Louvre Museum", description: "World's largest art museum and historic monument", imageURL: "louvre")
        ],
        coordinates: Coordinates(latitude: 48.8566, longitude: 2.3522),
        timezone: "Europe/Paris",
        imageURLs: ["paris_1", "paris_2", "paris_3"],
        facts: [
            "Paris is often called the City of Light (la Ville Lumière)",
            "The Louvre is the world's largest art museum",
            "Paris hosts one of the world's major fashion weeks"
        ]
    )
} 