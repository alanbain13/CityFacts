import Foundation

// Enhanced Trip Timeline with dependency management
struct TripTimeline: Codable, Identifiable {
    let id: UUID
    let tripInfo: TripInfo
    var timelineEvents: [TimelineEvent]
    
    init(tripInfo: TripInfo, timelineEvents: [TimelineEvent] = []) {
        self.id = UUID()
        self.tripInfo = tripInfo
        self.timelineEvents = timelineEvents
    }
    
    // Trip information
    struct TripInfo: Codable {
        let originCity: String
        let destinationCity: String
        let startDate: Date
        let endDate: Date
        let startTime: Date // Trip departure time
        let endTime: Date   // Trip return time
        let homeCity: City
        let destinationCityData: City
    }
    
    // Individual timeline event with dependency tracking
    struct TimelineEvent: Codable, Identifiable, Equatable {
        let id: UUID
        let dayNumber: Int
        let sequence: Int
        let dependencies: [UUID] // IDs of events that must complete first
        let eventType: EventType
        let startTime: Date
        let endTime: Date
        let data: EventData
        
        init(dayNumber: Int, sequence: Int, dependencies: [UUID] = [], eventType: EventType, startTime: Date, endTime: Date, data: EventData) {
            self.id = UUID()
            self.dayNumber = dayNumber
            self.sequence = sequence
            self.dependencies = dependencies
            self.eventType = eventType
            self.startTime = startTime
            self.endTime = endTime
            self.data = data
        }
        
        static func == (lhs: TimelineEvent, rhs: TimelineEvent) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    // Event types with associated data
    enum EventType: String, Codable, CaseIterable {
        case transit = "transit"
        case attraction = "attraction"
        case hotel = "hotel"
        case meal = "meal"
        case sleep = "sleep"
        
        var icon: String {
            switch self {
            case .transit: return "car.fill"
            case .attraction: return "building.2.fill"
            case .hotel: return "bed.double.fill"
            case .meal: return "fork.knife"
            case .sleep: return "moon.fill"
            }
        }
        
        var color: String {
            switch self {
            case .transit: return "blue"
            case .attraction: return "green"
            case .hotel: return "purple"
            case .meal: return "orange"
            case .sleep: return "indigo"
            }
        }
    }
    
    // Event data for different types
    enum EventData: Codable {
        case transit(TransitRoute)
        case attraction(TouristAttraction)
        case hotel(Hotel)
        case meal(String) // meal type
        case sleep
        
        var displayTitle: String {
            switch self {
            case .transit(let route):
                return "\(route.startLocation) → \(route.endLocation)"
            case .attraction(let attraction):
                return attraction.name
            case .hotel(let hotel):
                return "Check-in: \(hotel.name)"
            case .meal(let mealType):
                return mealType.capitalized
            case .sleep:
                return "Sleep"
            }
        }
        
        var displaySubtitle: String {
            switch self {
            case .transit(let route):
                return "\(route.mode.rawValue) • \(Int(route.elapsedTime / 60)) min"
            case .attraction(let attraction):
                return attraction.category.rawValue
            case .hotel(let hotel):
                return hotel.address ?? "Hotel"
            case .meal:
                return "Meal time"
            case .sleep:
                return "Rest time"
            }
        }
    }
}

// Timeline Dependency Resolver
class TimelineDependencyResolver {
    
    // Resolve dependencies and ensure proper sequencing
    static func resolveDependencies(events: [TripTimeline.TimelineEvent]) -> [TripTimeline.TimelineEvent] {
        var resolvedEvents: [TripTimeline.TimelineEvent] = []
        var remainingEvents = events
        var completedEventIds: Set<UUID> = []
        
        // First pass: Add events with no dependencies
        while let event = remainingEvents.first(where: { event in
            event.dependencies.allSatisfy { completedEventIds.contains($0) }
        }) {
            resolvedEvents.append(event)
            completedEventIds.insert(event.id)
            remainingEvents.removeAll { $0.id == event.id }
        }
        
        // Second pass: Add remaining events (should be empty if no circular dependencies)
        resolvedEvents.append(contentsOf: remainingEvents)
        
        return resolvedEvents.sorted { $0.startTime < $1.startTime }
    }
    
    // Generate timeline with proper dependencies and constraints
    static func generateTimeline(
        tripInfo: TripTimeline.TripInfo,
        attractions: [TouristAttraction],
        transitDays: [TransitDay],
        selectedHotels: [Int: Hotel?],
        availabilityCalendar: PersonalAvailabilityCalendar = PersonalAvailabilityCalendar.defaultCalendar()
    ) -> TripTimeline {
        
        var allEvents: [TripTimeline.TimelineEvent] = []
        let calendar = Calendar.current
        let numberOfDays = calendar.dateComponents([.day], from: tripInfo.startDate, to: tripInfo.endDate).day ?? 0 + 1
        
        // Rule 1 & 2: All events must be within trip start/end times
        let tripStartTime = tripInfo.startTime
        let tripEndTime = tripInfo.endTime
        
        // Rule 3: First event must be transit from home to destination
        var firstTransitEvent: TripTimeline.TimelineEvent?
        if let homeToHubTransit = findTransitRoute(transitDays: transitDays, routeType: .homeToHub, dayDate: tripInfo.startDate) {
            firstTransitEvent = TripTimeline.TimelineEvent(
                dayNumber: 1,
                sequence: 1,
                dependencies: [],
                eventType: .transit,
                startTime: max(homeToHubTransit.startTime, tripStartTime),
                endTime: min(homeToHubTransit.endTime, tripEndTime),
                data: .transit(homeToHubTransit)
            )
            if let event = firstTransitEvent {
                allEvents.append(event)
            }
        }
        
        // Track dependencies and current location
        var currentLocation: String = tripInfo.originCity
        var lastEventId: UUID? = firstTransitEvent?.id
        
        // Process each day
        for dayIndex in 0..<numberOfDays {
            let dayNumber = dayIndex + 1
            let dayDate = calendar.date(byAdding: .day, value: dayIndex, to: tripInfo.startDate) ?? tripInfo.startDate
            var dayDependencies: [UUID] = []
            
            // Add dependency on previous day's last event
            if let lastEvent = lastEventId {
                dayDependencies.append(lastEvent)
            }
            
            // Rule 6: Add transit to hotel if hotel is selected for this day
            if let hotelOpt = selectedHotels[dayNumber], let hotel = hotelOpt {
                // Transit to hotel
                if let hotelTransit = findTransitRoute(transitDays: transitDays, routeType: .hubToHotel, dayDate: dayDate) {
                    let hotelTransitEvent = TripTimeline.TimelineEvent(
                        dayNumber: dayNumber,
                        sequence: dayDependencies.count + 1,
                        dependencies: dayDependencies,
                        eventType: .transit,
                        startTime: max(hotelTransit.startTime, tripStartTime),
                        endTime: min(hotelTransit.endTime, tripEndTime),
                        data: .transit(hotelTransit)
                    )
                    allEvents.append(hotelTransitEvent)
                    dayDependencies.append(hotelTransitEvent.id)
                    currentLocation = hotel.name
                }
                
                // Hotel check-in
                let checkInTime = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: dayDate) ?? dayDate
                let checkOutTime = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: dayDate.addingTimeInterval(86400)) ?? dayDate.addingTimeInterval(86400)
                
                let hotelEvent = TripTimeline.TimelineEvent(
                    dayNumber: dayNumber,
                    sequence: dayDependencies.count + 1,
                    dependencies: dayDependencies,
                    eventType: .hotel,
                    startTime: max(checkInTime, tripStartTime),
                    endTime: min(checkOutTime, tripEndTime),
                    data: .hotel(hotel)
                )
                allEvents.append(hotelEvent)
                dayDependencies.append(hotelEvent.id)
                lastEventId = hotelEvent.id
            }
            
            // Add availability-based events (meals, sleep, attractions)
            var remainingAttractions = attractionsForDay(dayIndex, totalAttractions: attractions, numberOfDays: numberOfDays)
            var eventSequence = dayDependencies.count + 1
            
            for slot in availabilityCalendar.slots {
                let slotStart = calendar.date(bySettingHour: slot.startTime.hour ?? 0, minute: slot.startTime.minute ?? 0, second: 0, of: dayDate) ?? dayDate
                let slotEnd = calendar.date(bySettingHour: slot.endTime.hour ?? 0, minute: slot.endTime.minute ?? 0, second: 0, of: dayDate) ?? dayDate.addingTimeInterval(3600)
                
                // Ensure slot is within trip bounds
                let adjustedSlotStart = max(slotStart, tripStartTime)
                let adjustedSlotEnd = min(slotEnd, tripEndTime)
                
                if adjustedSlotStart >= adjustedSlotEnd {
                    continue // Skip if slot is outside trip bounds
                }
                
                switch slot.type {
                case .meal:
                    let mealEvent = TripTimeline.TimelineEvent(
                        dayNumber: dayNumber,
                        sequence: eventSequence,
                        dependencies: dayDependencies,
                        eventType: .meal,
                        startTime: adjustedSlotStart,
                        endTime: adjustedSlotEnd,
                        data: .meal(slot.name)
                    )
                    allEvents.append(mealEvent)
                    eventSequence += 1
                    
                case .sleep:
                    let sleepEvent = TripTimeline.TimelineEvent(
                        dayNumber: dayNumber,
                        sequence: eventSequence,
                        dependencies: dayDependencies,
                        eventType: .sleep,
                        startTime: adjustedSlotStart,
                        endTime: adjustedSlotEnd,
                        data: .sleep
                    )
                    allEvents.append(sleepEvent)
                    eventSequence += 1
                    
                case .available:
                    var slotTime = adjustedSlotStart
                    while !remainingAttractions.isEmpty && slotTime < adjustedSlotEnd {
                        let attraction = remainingAttractions.removeFirst()
                        let duration = attraction.estimatedDuration * 60
                        let attractionEnd = min(slotTime.addingTimeInterval(duration), adjustedSlotEnd)
                        
                        // Rule 5: Add transit TO attraction
                        if let transitToAttraction = findTransitRoute(transitDays: transitDays, routeType: .hotelToFirstAttraction, dayDate: dayDate) {
                            let transitEvent = TripTimeline.TimelineEvent(
                                dayNumber: dayNumber,
                                sequence: eventSequence,
                                dependencies: dayDependencies,
                                eventType: .transit,
                                startTime: max(slotTime, tripStartTime),
                                endTime: min(slotTime.addingTimeInterval(transitToAttraction.elapsedTime), tripEndTime),
                                data: .transit(transitToAttraction)
                            )
                            allEvents.append(transitEvent)
                            dayDependencies.append(transitEvent.id)
                            eventSequence += 1
                            slotTime = slotTime.addingTimeInterval(transitToAttraction.elapsedTime)
                        }
                        
                        // Attraction visit
                        let attractionEvent = TripTimeline.TimelineEvent(
                            dayNumber: dayNumber,
                            sequence: eventSequence,
                            dependencies: dayDependencies,
                            eventType: .attraction,
                            startTime: max(slotTime, tripStartTime),
                            endTime: min(attractionEnd, tripEndTime),
                            data: .attraction(attraction)
                        )
                        allEvents.append(attractionEvent)
                        dayDependencies.append(attractionEvent.id)
                        eventSequence += 1
                        slotTime = attractionEnd
                        
                        // Rule 5: Add transit FROM attraction
                        if let transitFromAttraction = findTransitRoute(transitDays: transitDays, routeType: .lastAttractionToHotel, dayDate: dayDate) {
                            let transitEvent = TripTimeline.TimelineEvent(
                                dayNumber: dayNumber,
                                sequence: eventSequence,
                                dependencies: dayDependencies,
                                eventType: .transit,
                                startTime: max(slotTime, tripStartTime),
                                endTime: min(slotTime.addingTimeInterval(transitFromAttraction.elapsedTime), tripEndTime),
                                data: .transit(transitFromAttraction)
                            )
                            allEvents.append(transitEvent)
                            dayDependencies.append(transitEvent.id)
                            eventSequence += 1
                            slotTime = slotTime.addingTimeInterval(transitFromAttraction.elapsedTime)
                        }
                    }
                }
            }
            
            // Rule 4: Add return transit on last day
            if dayNumber == numberOfDays {
                if let returnTransit = findTransitRoute(transitDays: transitDays, routeType: .hotelToHome, dayDate: dayDate) {
                    let returnEvent = TripTimeline.TimelineEvent(
                        dayNumber: dayNumber,
                        sequence: eventSequence,
                        dependencies: dayDependencies,
                        eventType: .transit,
                        startTime: max(returnTransit.startTime, tripStartTime),
                        endTime: min(returnTransit.endTime, tripEndTime),
                        data: .transit(returnTransit)
                    )
                    allEvents.append(returnEvent)
                    lastEventId = returnEvent.id
                }
            }
        }
        
        // Resolve dependencies and sort
        let resolvedEvents = resolveDependencies(events: allEvents)
        return TripTimeline(tripInfo: tripInfo, timelineEvents: resolvedEvents)
    }
    
    // Helper function to find transit routes
    private static func findTransitRoute(transitDays: [TransitDay], routeType: TransitRoute.RouteType, dayDate: Date) -> TransitRoute? {
        let calendar = Calendar.current
        return transitDays.first { calendar.isDate($0.date, inSameDayAs: dayDate) }?.routes.first { $0.type == routeType }
    }
    
    private static func attractionsForDay(_ dayIndex: Int, totalAttractions: [TouristAttraction], numberOfDays: Int) -> [TouristAttraction] {
        let attractionsPerDay = Int(ceil(Double(totalAttractions.count) / Double(numberOfDays)))
        let startIndex = dayIndex * attractionsPerDay
        let endIndex = min(startIndex + attractionsPerDay, totalAttractions.count)
        return Array(totalAttractions[startIndex..<endIndex])
    }
}

// XML Serializer for Trip Timeline
protocol TimelineSerializer {
    func exportToXML(timeline: TripTimeline) -> String
    func importFromXML(xmlString: String) -> TripTimeline?
}

class XMLTimelineSerializer: TimelineSerializer {
    
    func exportToXML(timeline: TripTimeline) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <trip-timeline>
            <trip-info>
                <origin-city>\(timeline.tripInfo.originCity)</origin-city>
                <destination-city>\(timeline.tripInfo.destinationCity)</destination-city>
                <start-date>\(dateFormatter.string(from: timeline.tripInfo.startDate))</start-date>
                <end-date>\(dateFormatter.string(from: timeline.tripInfo.endDate))</end-date>
                <start-time>\(timeFormatter.string(from: timeline.tripInfo.startTime))</start-time>
                <end-time>\(timeFormatter.string(from: timeline.tripInfo.endTime))</end-time>
            </trip-info>
            
            <timeline-events>
        """
        
        // Group events by day
        let eventsByDay = Dictionary(grouping: timeline.timelineEvents) { $0.dayNumber }
        
        for dayNumber in eventsByDay.keys.sorted() {
            let dayEvents = eventsByDay[dayNumber] ?? []
            let dayDate = Calendar.current.date(byAdding: .day, value: dayNumber - 1, to: timeline.tripInfo.startDate) ?? timeline.tripInfo.startDate
            
            xml += """
            
                <day number="\(dayNumber)" date="\(dateFormatter.string(from: dayDate))">
            """
            
            for event in dayEvents.sorted(by: { $0.sequence < $1.sequence }) {
                xml += """
                
                    <event type="\(event.eventType.rawValue)" sequence="\(event.sequence)" dependencies="\(event.dependencies.map { $0.uuidString }.joined(separator: ","))">
                """
                
                switch event.data {
                case .transit(let route):
                    xml += """
                        <transit-route>
                            <from>\(route.startLocation)</from>
                            <to>\(route.endLocation)</to>
                            <mode>\(route.mode.rawValue)</mode>
                            <start-time>\(timeFormatter.string(from: event.startTime))</start-time>
                            <end-time>\(timeFormatter.string(from: event.endTime))</end-time>
                        </transit-route>
                    """
                case .attraction(let attraction):
                    xml += """
                        <attraction>
                            <name>\(attraction.name)</name>
                            <category>\(attraction.category.rawValue)</category>
                            <start-time>\(timeFormatter.string(from: event.startTime))</start-time>
                            <end-time>\(timeFormatter.string(from: event.endTime))</end-time>
                        </attraction>
                    """
                case .hotel(let hotel):
                    xml += """
                        <hotel>
                            <name>\(hotel.name)</name>
                            <address>\(hotel.address ?? "")</address>
                            <checkin-time>\(timeFormatter.string(from: event.startTime))</checkin-time>
                        </hotel>
                    """
                case .meal(let mealType):
                    xml += """
                        <meal>
                            <type>\(mealType)</type>
                            <start-time>\(timeFormatter.string(from: event.startTime))</start-time>
                            <end-time>\(timeFormatter.string(from: event.endTime))</end-time>
                        </meal>
                    """
                case .sleep:
                    xml += """
                        <sleep>
                            <start-time>\(timeFormatter.string(from: event.startTime))</start-time>
                            <end-time>\(timeFormatter.string(from: event.endTime))</end-time>
                        </sleep>
                    """
                }
                
                xml += """
                
                    </event>
                """
            }
            
            xml += """
            
                </day>
            """
        }
        
        xml += """
            
            </timeline-events>
        </trip-timeline>
        """
        
        return xml
    }
    
    func importFromXML(xmlString: String) -> TripTimeline? {
        // Basic XML parsing implementation
        // This would need a proper XML parser like XMLParser or a third-party library
        // For now, return nil as this is a placeholder
        return nil
    }
} 