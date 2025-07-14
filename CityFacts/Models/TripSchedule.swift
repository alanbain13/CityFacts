import Foundation

// TripSchedule manages the overall trip timeline and coordinates all elements
// It ensures proper chronological ordering of transits, attractions, and hotels
struct TripSchedule: Codable {
    let id = UUID()
    
    // Source city departure and arrival
    let homeCity: String
    let departureDate: Date
    let departureTime: Date // Time component only
    let returnDate: Date
    let returnTime: Date // Time component only
    
    // Computed properties for actual departure/arrival times
    var actualDepartureTime: Date {
        Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: departureTime),
                             minute: Calendar.current.component(.minute, from: departureTime),
                             second: 0, of: departureDate) ?? departureDate
    }
    
    var actualReturnTime: Date {
        Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: returnTime),
                             minute: Calendar.current.component(.minute, from: returnTime),
                             second: 0, of: returnDate) ?? returnDate
    }
    
    // Trip duration
    var numberOfDays: Int {
        Calendar.current.dateComponents([.day], from: departureDate, to: returnDate).day ?? 0 + 1
    }
    
    // Date for specific day
    func dateForDay(_ dayNumber: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: dayNumber - 1, to: departureDate) ?? departureDate
    }
    
    // Time formatting helpers
    var formattedDepartureTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: departureTime)
    }
    
    var formattedReturnTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: returnTime)
    }
    
    var formattedDepartureDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: departureDate)
    }
    
    var formattedReturnDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: returnDate)
    }
}

// HotelSchedule manages hotel-specific timing
struct HotelSchedule: Codable {
    let checkInTime: Date // Default 18:00
    let checkOutTime: Date // Default 09:00
    let eveningArrivalTime: Date // Default 18:00
    let morningDepartureTime: Date // Default 09:00
    
    init(checkInTime: Date? = nil, checkOutTime: Date? = nil) {
        let calendar = Calendar.current
        
        // Default check-in time: 18:00
        self.checkInTime = checkInTime ?? calendar.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
        
        // Default check-out time: 09:00
        self.checkOutTime = checkOutTime ?? calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        
        // Evening arrival time (same as check-in)
        self.eveningArrivalTime = self.checkInTime
        
        // Morning departure time (same as check-out)
        self.morningDepartureTime = self.checkOutTime
    }
    
    // Time formatting helpers
    var formattedCheckInTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: checkInTime)
    }
    
    var formattedCheckOutTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: checkOutTime)
    }
    
    var formattedEveningArrivalTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: eveningArrivalTime)
    }
    
    var formattedMorningDepartureTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: morningDepartureTime)
    }
}

// ItineraryItem represents any item in the chronological timeline
enum ItineraryItem: Identifiable, Codable {
    case transit(TransitRoute)
    case attraction(TouristAttraction, TimeSlot)
    case hotel(Hotel, HotelSchedule)
    
    var id: UUID {
        switch self {
        case .transit(let route):
            return route.id
        case .attraction(let attraction, _):
            return attraction.id
        case .hotel(let hotel, _):
            return hotel.id
        }
    }
    
    var startTime: Date {
        switch self {
        case .transit(let route):
            return route.startTime
        case .attraction(_, let timeSlot):
            return timeSlot.startTime
        case .hotel(let hotel, let schedule):
            // Hotel start time is check-in time
            return schedule.checkInTime
        }
    }
    
    var endTime: Date {
        switch self {
        case .transit(let route):
            return route.endTime
        case .attraction(_, let timeSlot):
            return timeSlot.endTime
        case .hotel(let hotel, let schedule):
            // Hotel end time is check-out time
            return schedule.checkOutTime
        }
    }
    
    var title: String {
        switch self {
        case .transit(let route):
            return route.type.rawValue
        case .attraction(let attraction, _):
            return attraction.name
        case .hotel(let hotel, _):
            return hotel.name
        }
    }
    
    var icon: String {
        switch self {
        case .transit(let route):
            return route.mode.icon
        case .attraction(let attraction, _):
            return "star"
        case .hotel(let hotel, _):
            return "bed.double"
        }
    }
    
    // MARK: - Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case type
        case transitRoute
        case attraction
        case timeSlot
        case hotel
        case hotelSchedule
    }
    
    private enum ItemType: String, Codable {
        case transit
        case attraction
        case hotel
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ItemType.self, forKey: .type)
        
        switch type {
        case .transit:
            let route = try container.decode(TransitRoute.self, forKey: .transitRoute)
            self = .transit(route)
        case .attraction:
            let attraction = try container.decode(TouristAttraction.self, forKey: .attraction)
            let timeSlot = try container.decode(TimeSlot.self, forKey: .timeSlot)
            self = .attraction(attraction, timeSlot)
        case .hotel:
            let hotel = try container.decode(Hotel.self, forKey: .hotel)
            let schedule = try container.decode(HotelSchedule.self, forKey: .hotelSchedule)
            self = .hotel(hotel, schedule)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .transit(let route):
            try container.encode(ItemType.transit, forKey: .type)
            try container.encode(route, forKey: .transitRoute)
        case .attraction(let attraction, let timeSlot):
            try container.encode(ItemType.attraction, forKey: .type)
            try container.encode(attraction, forKey: .attraction)
            try container.encode(timeSlot, forKey: .timeSlot)
        case .hotel(let hotel, let schedule):
            try container.encode(ItemType.hotel, forKey: .type)
            try container.encode(hotel, forKey: .hotel)
            try container.encode(schedule, forKey: .hotelSchedule)
        }
    }
}

// DaySchedule represents a complete day's chronological schedule
struct DaySchedule: Identifiable, Codable {
    let id = UUID()
    let dayNumber: Int
    let date: Date
    var items: [ItineraryItem] // Chronologically ordered
    
    // Helper computed properties
    var transitItems: [ItineraryItem] {
        items.filter { if case .transit = $0 { return true }; return false }
    }
    
    var attractionItems: [ItineraryItem] {
        items.filter { if case .attraction = $0 { return true }; return false }
    }
    
    var hotelItem: ItineraryItem? {
        items.first { if case .hotel = $0 { return true }; return false }
    }
    
    // Sort items chronologically
    mutating func sortChronologically() {
        items.sort { $0.startTime < $1.startTime }
    }
    
    // Add item and maintain chronological order
    mutating func addItem(_ item: ItineraryItem) {
        items.append(item)
        sortChronologically()
    }
} 