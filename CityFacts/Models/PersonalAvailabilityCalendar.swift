import Foundation

struct AvailabilitySlot: Identifiable, Codable {
    let id = UUID()
    let name: String
    let startTime: DateComponents // Only hour/minute
    let endTime: DateComponents
    let type: SlotType
    
    enum SlotType: String, Codable {
        case meal, sleep, available
    }
}

struct PersonalAvailabilityCalendar: Codable {
    let slots: [AvailabilitySlot]
    
    static func defaultCalendar() -> PersonalAvailabilityCalendar {
        return PersonalAvailabilityCalendar(slots: [
            AvailabilitySlot(name: "Sleep", startTime: DateComponents(hour: 22, minute: 0), endTime: DateComponents(hour: 7, minute: 0), type: .sleep),
            AvailabilitySlot(name: "Breakfast", startTime: DateComponents(hour: 8, minute: 0), endTime: DateComponents(hour: 9, minute: 0), type: .meal),
            AvailabilitySlot(name: "Morning Available", startTime: DateComponents(hour: 9, minute: 0), endTime: DateComponents(hour: 12, minute: 0), type: .available),
            AvailabilitySlot(name: "Lunch", startTime: DateComponents(hour: 12, minute: 0), endTime: DateComponents(hour: 13, minute: 0), type: .meal),
            AvailabilitySlot(name: "Afternoon Available", startTime: DateComponents(hour: 13, minute: 0), endTime: DateComponents(hour: 17, minute: 0), type: .available),
            AvailabilitySlot(name: "Dinner", startTime: DateComponents(hour: 19, minute: 0), endTime: DateComponents(hour: 20, minute: 0), type: .meal)
        ])
    }

    // Unified timeline generator for a day
    static func generateChronologicalTimeline(
        dayDate: Date,
        attractions: [TouristAttraction],
        transitRoutes: [TransitRoute],
        hotel: Hotel?,
        calendar: PersonalAvailabilityCalendar = PersonalAvailabilityCalendar.defaultCalendar()
    ) -> [UnifiedTimelineItem] {
        let cal = Calendar.current
        var items: [UnifiedTimelineItem] = []
        var remainingAttractions = attractions
        // Meals and sleep
        for slot in calendar.slots {
            let slotStart = cal.date(bySettingHour: slot.startTime.hour ?? 0, minute: slot.startTime.minute ?? 0, second: 0, of: dayDate) ?? dayDate
            let slotEnd = cal.date(bySettingHour: slot.endTime.hour ?? 0, minute: slot.endTime.minute ?? 0, second: 0, of: dayDate) ?? dayDate.addingTimeInterval(3600)
            switch slot.type {
            case .meal:
                items.append(.meal(name: slot.name, start: slotStart, end: slotEnd))
            case .sleep:
                items.append(.sleep(start: slotStart, end: slotEnd))
            case .available:
                var slotTime = slotStart
                while !remainingAttractions.isEmpty && slotTime < slotEnd {
                    let attraction = remainingAttractions.removeFirst()
                    let duration = attraction.estimatedDuration * 60
                    let attractionEnd = min(slotTime.addingTimeInterval(duration), slotEnd)
                    items.append(.attraction(attraction: attraction, start: slotTime, end: attractionEnd))
                    slotTime = attractionEnd
                }
            }
        }
        // Hotel check-in/out (optional)
        if let hotel = hotel {
            let checkIn = cal.date(bySettingHour: 15, minute: 0, second: 0, of: dayDate) ?? dayDate
            let checkOut = cal.date(bySettingHour: 9, minute: 0, second: 0, of: dayDate.addingTimeInterval(86400)) ?? dayDate.addingTimeInterval(86400)
            items.append(.hotel(hotel: hotel, start: checkIn, end: checkOut))
        }
        // Transit events
        for route in transitRoutes {
            items.append(.transit(route: route, start: route.startTime, end: route.endTime))
        }
        // Sort all by start time
        return items.sorted { $0.start < $1.start }
    }
}

// Unified timeline item for all event types
enum UnifiedTimelineItem: Identifiable {
    case attraction(attraction: TouristAttraction, start: Date, end: Date)
    case hotel(hotel: Hotel, start: Date, end: Date)
    case transit(route: TransitRoute, start: Date, end: Date)
    case meal(name: String, start: Date, end: Date)
    case sleep(start: Date, end: Date)
    
    var id: UUID {
        switch self {
        case .attraction(let a, _, _): return a.id
        case .hotel(let h, _, _): return h.id
        case .transit(let r, _, _): return r.id
        case .meal(_, let start, _): return UUID(uuidString: "meal-\(start.timeIntervalSince1970)") ?? UUID()
        case .sleep(let start, _): return UUID(uuidString: "sleep-\(start.timeIntervalSince1970)") ?? UUID()
        }
    }
    var start: Date {
        switch self {
        case .attraction(_, let s, _): return s
        case .hotel(_, let s, _): return s
        case .transit(_, let s, _): return s
        case .meal(_, let s, _): return s
        case .sleep(let s, _): return s
        }
    }
    var end: Date {
        switch self {
        case .attraction(_, _, let e): return e
        case .hotel(_, _, let e): return e
        case .transit(_, _, let e): return e
        case .meal(_, _, let e): return e
        case .sleep(_, let e): return e
        }
    }
} 