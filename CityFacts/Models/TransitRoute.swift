import SwiftUI
import MapKit

// TransitRoute represents a transportation route between two locations
// It includes route details, timing, cost, and transport mode information
struct TransitRoute: Identifiable, Codable {
    let id = UUID()
    let type: RouteType
    let startLocation: String
    let endLocation: String
    let startTime: Date
    let endTime: Date
    let elapsedTime: TimeInterval
    let distance: Double // in kilometers
    let cost: Double // in local currency
    let mode: TransportMode
    let routePolyline: String? // Google Maps polyline data
    let imageURL: String?
    let description: String
    let instructions: [String]
    
    enum RouteType: String, CaseIterable, Codable {
        case homeToHub = "Home to Hub"
        case hubToHotel = "Hub to Hotel"
        case hotelToFirstAttraction = "Hotel to First Attraction"
        case lastAttractionToHotel = "Last Attraction to Hotel"
        case hotelToHome = "Hotel to Home"
        
        var icon: String {
            switch self {
            case .homeToHub, .hotelToHome:
                return "airplane"
            case .hubToHotel, .hotelToFirstAttraction, .lastAttractionToHotel:
                return "car"
            }
        }
    }
    
    enum TransportMode: String, CaseIterable, Codable {
        case airplane = "Airplane"
        case train = "Train"
        case bus = "Bus"
        case subway = "Subway"
        case taxi = "Taxi"
        case rideshare = "Rideshare"
        case walking = "Walking"
        case cycling = "Cycling"
        case car = "Car"
        case ferry = "Ferry"
        
        var icon: String {
            switch self {
            case .airplane: return "airplane"
            case .train: return "train.side.front.car"
            case .bus: return "bus"
            case .subway: return "tram"
            case .taxi: return "car.fill"
            case .rideshare: return "car.circle"
            case .walking: return "figure.walk"
            case .cycling: return "bicycle"
            case .car: return "car"
            case .ferry: return "ferry"
            }
        }
        
        var color: Color {
            switch self {
            case .airplane: return .blue
            case .train: return .green
            case .bus: return .orange
            case .subway: return .purple
            case .taxi: return .yellow
            case .rideshare: return .pink
            case .walking: return .gray
            case .cycling: return .mint
            case .car: return .red
            case .ferry: return .cyan
            }
        }
    }
    
    var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = Int(elapsedTime) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var formattedDistance: String {
        if distance >= 1.0 {
            return String(format: "%.1f km", distance)
        } else {
            return String(format: "%.0f m", distance * 1000)
        }
    }
    
    var formattedCost: String {
        return String(format: "$%.2f", cost)
    }
    
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
    
    var formattedEndTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: endTime)
    }
}

// TransitDay represents all transit routes for a single day
struct TransitDay: Identifiable {
    let id = UUID()
    let dayNumber: Int
    let date: Date
    var routes: [TransitRoute]
    
    var hubToHotelRoute: TransitRoute? {
        routes.first { $0.type == .hubToHotel }
    }
    
    var hotelToFirstAttractionRoute: TransitRoute? {
        routes.first { $0.type == .hotelToFirstAttraction }
    }
    
    var lastAttractionToHotelRoute: TransitRoute? {
        routes.first { $0.type == .lastAttractionToHotel }
    }
} 