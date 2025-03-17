import Foundation
import CoreLocation

struct Hotel: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let description: String
    let address: String
    let rating: Double
    let imageURL: String
    let coordinates: CLLocationCoordinate2D
    let amenities: [String]
    let websiteURL: String?
    let phoneNumber: String?
    let priceLevel: PriceLevel
    
    static func == (lhs: Hotel, rhs: Hotel) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.description == rhs.description &&
        lhs.address == rhs.address &&
        lhs.rating == rhs.rating &&
        lhs.imageURL == rhs.imageURL &&
        lhs.coordinates.latitude == rhs.coordinates.latitude &&
        lhs.coordinates.longitude == rhs.coordinates.longitude &&
        lhs.amenities == rhs.amenities &&
        lhs.websiteURL == rhs.websiteURL &&
        lhs.phoneNumber == rhs.phoneNumber &&
        lhs.priceLevel == rhs.priceLevel
    }
    
    enum PriceLevel: String, Codable {
        case budget = "€"
        case moderate = "€€"
        case luxury = "€€€"
        case ultraLuxury = "€€€€"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case address
        case rating
        case imageURL
        case coordinates
        case latitude
        case longitude
        case amenities
        case websiteURL
        case phoneNumber
        case priceLevel
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        address = try container.decode(String.self, forKey: .address)
        rating = try container.decode(Double.self, forKey: .rating)
        imageURL = try container.decode(String.self, forKey: .imageURL)
        amenities = try container.decode([String].self, forKey: .amenities)
        websiteURL = try container.decodeIfPresent(String.self, forKey: .websiteURL)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        priceLevel = try container.decode(PriceLevel.self, forKey: .priceLevel)
        
        // Handle coordinates
        if let coordinatesContainer = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .coordinates) {
            let latitude = try coordinatesContainer.decode(Double.self, forKey: .latitude)
            let longitude = try coordinatesContainer.decode(Double.self, forKey: .longitude)
            coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        } else {
            // Fallback for flat structure
            let latitude = try container.decode(Double.self, forKey: .latitude)
            let longitude = try container.decode(Double.self, forKey: .longitude)
            coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(address, forKey: .address)
        try container.encode(rating, forKey: .rating)
        try container.encode(imageURL, forKey: .imageURL)
        try container.encode(amenities, forKey: .amenities)
        try container.encodeIfPresent(websiteURL, forKey: .websiteURL)
        try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        try container.encode(priceLevel, forKey: .priceLevel)
        
        // Encode coordinates as nested container
        var coordinatesContainer = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .coordinates)
        try coordinatesContainer.encode(coordinates.latitude, forKey: .latitude)
        try coordinatesContainer.encode(coordinates.longitude, forKey: .longitude)
    }
    
    init(id: UUID = UUID(),
         name: String,
         description: String,
         address: String,
         rating: Double,
         imageURL: String,
         coordinates: CLLocationCoordinate2D,
         amenities: [String],
         websiteURL: String?,
         phoneNumber: String?,
         priceLevel: PriceLevel) {
        self.id = id
        self.name = name
        self.description = description
        self.address = address
        self.rating = rating
        self.imageURL = imageURL
        self.coordinates = coordinates
        self.amenities = amenities
        self.websiteURL = websiteURL
        self.phoneNumber = phoneNumber
        self.priceLevel = priceLevel
    }
} 