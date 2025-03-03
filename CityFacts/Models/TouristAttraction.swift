import Foundation
import CoreLocation

struct TouristAttraction: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let category: Category
    let estimatedDuration: TimeInterval // in minutes
    let coordinates: Coordinates
    let imageURL: String
    let tips: [String]
    let websiteURL: String?
    
    struct Coordinates: Codable {
        let latitude: Double
        let longitude: Double
        
        var locationCoordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    enum Category: String, Codable, CaseIterable {
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
}

// Extension to generate attractions for a city
extension TouristAttraction {
    static func generateAttractions(for city: City) -> [TouristAttraction] {
        var attractions: [TouristAttraction] = []
        
        // Get city-specific landmarks
        let cityLandmarks = city.landmarks
        
        // Add city's actual landmarks first
        for landmark in cityLandmarks {
            attractions.append(TouristAttraction(
                id: UUID(),
                name: landmark.name,
                description: landmark.description,
                category: .historical,
                estimatedDuration: 120,
                coordinates: Coordinates(
                    latitude: city.coordinates.latitude + Double.random(in: -0.01...0.01),
                    longitude: city.coordinates.longitude + Double.random(in: -0.01...0.01)
                ),
                imageURL: landmark.imageURL,
                tips: ["Best time to visit: Early morning", "Photography allowed"],
                websiteURL: nil
            ))
        }
        
        // Generate 20 major attractions based on city characteristics
        let attractionTemplates = generateAttractionTemplates(for: city)
        
        // Add attractions until we have 20 total
        while attractions.count < 20 {
            if let template = attractionTemplates.randomElement() {
                attractions.append(createAttraction(from: template, for: city))
            }
        }
        
        return attractions
    }
    
    private static func generateAttractionTemplates(for city: City) -> [AttractionTemplate] {
        var templates: [AttractionTemplate] = []
        
        // Historical attractions
        templates.append(AttractionTemplate(
            name: "Historic District",
            description: "Preserved historic area showcasing \(city.name)'s rich heritage.",
            category: .historical,
            baseDuration: 180,
            imageURL: "https://images.unsplash.com/photo-1511818966892-d7d671e672a2",
            tips: ["Take a guided tour", "Visit early morning"],
            websiteURL: nil
        ))
        
        templates.append(AttractionTemplate(
            name: "Ancient Ruins",
            description: "Archaeological site with remains from \(city.name)'s past.",
            category: .historical,
            baseDuration: 120,
            imageURL: "https://images.unsplash.com/photo-1552832230-c0197dd311b5",
            tips: ["Wear comfortable shoes", "Bring water"],
            websiteURL: nil
        ))
        
        // Cultural attractions
        templates.append(AttractionTemplate(
            name: "Cultural Center",
            description: "Hub of \(city.name)'s cultural activities and performances.",
            category: .cultural,
            baseDuration: 90,
            imageURL: "https://images.unsplash.com/photo-1511818966892-d7d671e672a2",
            tips: ["Check performance schedule", "Free entry on certain days"],
            websiteURL: nil
        ))
        
        templates.append(AttractionTemplate(
            name: "Art Gallery",
            description: "Contemporary art gallery featuring local and international artists.",
            category: .cultural,
            baseDuration: 120,
            imageURL: "https://images.unsplash.com/photo-1532094349884-543bc11b234d",
            tips: ["Free entry on certain days", "Guided tours available"],
            websiteURL: nil
        ))
        
        // Nature attractions
        templates.append(AttractionTemplate(
            name: "City Park",
            description: "Beautiful green space in the heart of \(city.name).",
            category: .nature,
            baseDuration: 60,
            imageURL: "https://images.unsplash.com/photo-1501854140801-50d01698950b",
            tips: ["Great for picnics", "Walking trails available"],
            websiteURL: nil
        ))
        
        templates.append(AttractionTemplate(
            name: "Botanical Gardens",
            description: "Garden showcasing local and exotic plant species.",
            category: .nature,
            baseDuration: 90,
            imageURL: "https://images.unsplash.com/photo-1501854140801-50d01698950b",
            tips: ["Visit in spring", "Guided tours available"],
            websiteURL: nil
        ))
        
        // Entertainment attractions
        templates.append(AttractionTemplate(
            name: "Entertainment District",
            description: "Vibrant area with theaters, restaurants, and nightlife.",
            category: .entertainment,
            baseDuration: 180,
            imageURL: "https://images.unsplash.com/photo-1511818966892-d7d671e672a2",
            tips: ["Visit in the evening", "Many restaurants nearby"],
            websiteURL: nil
        ))
        
        templates.append(AttractionTemplate(
            name: "Sports Stadium",
            description: "Major sports venue hosting various events.",
            category: .entertainment,
            baseDuration: 120,
            imageURL: "https://images.unsplash.com/photo-1511818966892-d7d671e672a2",
            tips: ["Book tickets in advance", "Arrive early"],
            websiteURL: nil
        ))
        
        // Shopping attractions
        templates.append(AttractionTemplate(
            name: "Shopping Mall",
            description: "Modern shopping complex with local and international brands.",
            category: .shopping,
            baseDuration: 120,
            imageURL: "https://images.unsplash.com/photo-1441986300917-64674bd600d8",
            tips: ["Tax-free shopping available", "Food court on top floor"],
            websiteURL: nil
        ))
        
        templates.append(AttractionTemplate(
            name: "Local Market",
            description: "Traditional market with local produce and crafts.",
            category: .shopping,
            baseDuration: 90,
            imageURL: "https://images.unsplash.com/photo-1441986300917-64674bd600d8",
            tips: ["Visit early morning", "Bargain for better prices"],
            websiteURL: nil
        ))
        
        // Dining attractions
        templates.append(AttractionTemplate(
            name: "Food Market",
            description: "Local food market with traditional cuisine.",
            category: .dining,
            baseDuration: 90,
            imageURL: "https://images.unsplash.com/photo-1504674900247-0877df9cc836",
            tips: ["Try local specialties", "Best visited during lunch"],
            websiteURL: nil
        ))
        
        templates.append(AttractionTemplate(
            name: "Restaurant District",
            description: "Area known for its diverse dining options.",
            category: .dining,
            baseDuration: 120,
            imageURL: "https://images.unsplash.com/photo-1504674900247-0877df9cc836",
            tips: ["Book in advance", "Try local specialties"],
            websiteURL: nil
        ))
        
        // Religious attractions
        templates.append(AttractionTemplate(
            name: "Historic Temple",
            description: "Ancient religious site with cultural significance.",
            category: .religious,
            baseDuration: 60,
            imageURL: "https://images.unsplash.com/photo-1511818966892-d7d671e672a2",
            tips: ["Dress modestly", "Remove shoes before entering"],
            websiteURL: nil
        ))
        
        templates.append(AttractionTemplate(
            name: "Cathedral",
            description: "Historic religious building with stunning architecture.",
            category: .religious,
            baseDuration: 90,
            imageURL: "https://images.unsplash.com/photo-1511818966892-d7d671e672a2",
            tips: ["Dress code required", "Free entry"],
            websiteURL: nil
        ))
        
        // Museum attractions
        templates.append(AttractionTemplate(
            name: "History Museum",
            description: "Museum showcasing \(city.name)'s rich history.",
            category: .museum,
            baseDuration: 120,
            imageURL: "https://images.unsplash.com/photo-1532094349884-543bc11b234d",
            tips: ["Free entry on certain days", "Audio guide available"],
            websiteURL: nil
        ))
        
        templates.append(AttractionTemplate(
            name: "Science Museum",
            description: "Interactive museum with scientific exhibits.",
            category: .museum,
            baseDuration: 150,
            imageURL: "https://images.unsplash.com/photo-1532094349884-543bc11b234d",
            tips: ["Great for families", "Interactive exhibits"],
            websiteURL: nil
        ))
        
        // Architecture attractions
        templates.append(AttractionTemplate(
            name: "Modern Architecture Tour",
            description: "Guided tour of the city's modern architectural landmarks.",
            category: .architecture,
            baseDuration: 180,
            imageURL: "https://images.unsplash.com/photo-1511818966892-d7d671e672a2",
            tips: ["Book in advance", "Wear comfortable shoes"],
            websiteURL: nil
        ))
        
        templates.append(AttractionTemplate(
            name: "Historic Buildings",
            description: "Collection of historic buildings with guided tours.",
            category: .architecture,
            baseDuration: 120,
            imageURL: "https://images.unsplash.com/photo-1511818966892-d7d671e672a2",
            tips: ["Take photos", "Visit during golden hour"],
            websiteURL: nil
        ))
        
        // Add continent-specific templates
        switch city.continent {
        case .europe:
            templates.append(AttractionTemplate(
                name: "Medieval Castle",
                description: "Historic castle with guided tours.",
                category: .historical,
                baseDuration: 150,
                imageURL: "https://images.unsplash.com/photo-1511818966892-d7d671e672a2",
                tips: ["Book tickets online", "Great photo opportunities"],
                websiteURL: nil
            ))
        case .asia:
            templates.append(AttractionTemplate(
                name: "Buddhist Temple",
                description: "Ancient temple with cultural significance.",
                category: .religious,
                baseDuration: 90,
                imageURL: "https://images.unsplash.com/photo-1511818966892-d7d671e672a2",
                tips: ["Remove shoes before entering", "Respect local customs"],
                websiteURL: nil
            ))
        case .northAmerica:
            templates.append(AttractionTemplate(
                name: "Observation Deck",
                description: "Tall building with panoramic city views.",
                category: .architecture,
                baseDuration: 60,
                imageURL: "https://images.unsplash.com/photo-1511818966892-d7d671e672a2",
                tips: ["Visit at sunset", "Book in advance"],
                websiteURL: nil
            ))
        case .southAmerica:
            templates.append(AttractionTemplate(
                name: "Historic Plaza",
                description: "Central plaza with colonial architecture.",
                category: .cultural,
                baseDuration: 90,
                imageURL: "https://images.unsplash.com/photo-1511818966892-d7d671e672a2",
                tips: ["Visit during festivals", "Local crafts available"],
                websiteURL: nil
            ))
        case .africa:
            templates.append(AttractionTemplate(
                name: "Cultural Village",
                description: "Traditional village showcasing local culture.",
                category: .cultural,
                baseDuration: 120,
                imageURL: "https://images.unsplash.com/photo-1511818966892-d7d671e672a2",
                tips: ["Support local artisans", "Traditional performances"],
                websiteURL: nil
            ))
        case .oceania:
            templates.append(AttractionTemplate(
                name: "Beach",
                description: "Beautiful beach with water activities.",
                category: .nature,
                baseDuration: 180,
                imageURL: "https://images.unsplash.com/photo-1501854140801-50d01698950b",
                tips: ["Bring sunscreen", "Best at sunset"],
                websiteURL: nil
            ))
        }
        
        return templates
    }
    
    private static func createAttraction(from template: AttractionTemplate, for city: City) -> TouristAttraction {
        // Generate random coordinates near the city center
        let latitude = city.coordinates.latitude + Double.random(in: -0.01...0.01)
        let longitude = city.coordinates.longitude + Double.random(in: -0.01...0.01)
        
        // Add some variation to the duration
        let duration = template.baseDuration + Double.random(in: -30...30)
        
        return TouristAttraction(
            id: UUID(),
            name: "\(city.name) \(template.name)",
            description: template.description,
            category: template.category,
            estimatedDuration: duration,
            coordinates: Coordinates(latitude: latitude, longitude: longitude),
            imageURL: template.imageURL,
            tips: template.tips,
            websiteURL: template.websiteURL
        )
    }
}

// Template structure for generating attractions
private struct AttractionTemplate {
    let name: String
    let description: String
    let category: TouristAttraction.Category
    let baseDuration: TimeInterval
    let imageURL: String
    let tips: [String]
    let websiteURL: String?
} 