import Foundation
import CoreLocation

struct Attraction: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let address: String
    let rating: Double
    let imageURL: String
    let coordinates: CLLocationCoordinate2D
    let websiteURL: String?
    let priceLevel: PriceLevel
    let category: Category
    let estimatedDuration: TimeInterval
    let tips: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case address
        case rating
        case imageURL
        case coordinates
        case websiteURL
        case priceLevel
        case category
        case estimatedDuration
        case tips
    }
    
    init(id: String, name: String, description: String, address: String, rating: Double, imageURL: String, coordinates: CLLocationCoordinate2D, websiteURL: String?, priceLevel: PriceLevel, category: Category = .historical, estimatedDuration: TimeInterval = 120, tips: [String] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.address = address
        self.rating = rating
        self.imageURL = imageURL
        self.coordinates = coordinates
        self.websiteURL = websiteURL
        self.priceLevel = priceLevel
        self.category = category
        self.estimatedDuration = estimatedDuration
        self.tips = tips
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        address = try container.decode(String.self, forKey: .address)
        rating = try container.decode(Double.self, forKey: .rating)
        imageURL = try container.decode(String.self, forKey: .imageURL)
        websiteURL = try container.decodeIfPresent(String.self, forKey: .websiteURL)
        priceLevel = try container.decode(PriceLevel.self, forKey: .priceLevel)
        category = try container.decode(Category.self, forKey: .category)
        estimatedDuration = try container.decode(TimeInterval.self, forKey: .estimatedDuration)
        tips = try container.decode([String].self, forKey: .tips)
        
        // Decode coordinates
        let coordinatesContainer = try container.nestedContainer(keyedBy: CoordinateCodingKeys.self, forKey: .coordinates)
        let latitude = try coordinatesContainer.decode(Double.self, forKey: .latitude)
        let longitude = try coordinatesContainer.decode(Double.self, forKey: .longitude)
        coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(address, forKey: .address)
        try container.encode(rating, forKey: .rating)
        try container.encode(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(websiteURL, forKey: .websiteURL)
        try container.encode(priceLevel, forKey: .priceLevel)
        try container.encode(category, forKey: .category)
        try container.encode(estimatedDuration, forKey: .estimatedDuration)
        try container.encode(tips, forKey: .tips)
        
        // Encode coordinates
        var coordinatesContainer = container.nestedContainer(keyedBy: CoordinateCodingKeys.self, forKey: .coordinates)
        try coordinatesContainer.encode(coordinates.latitude, forKey: .latitude)
        try coordinatesContainer.encode(coordinates.longitude, forKey: .longitude)
    }
    
    private enum CoordinateCodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
}

enum PriceLevel: String, Codable {
    case free = "Free"
    case inexpensive = "Inexpensive"
    case moderate = "Moderate"
    case expensive = "Expensive"
    case veryExpensive = "Very Expensive"
}

enum Category: String, Codable {
    case historical = "Historical"
    case cultural = "Cultural"
    case nature = "Nature"
    case entertainment = "Entertainment"
    case shopping = "Shopping"
    case dining = "Dining"
    case religious = "Religious"
    case museum = "Museum"
    case park = "Park"
    case architecture = "Architecture"
} 