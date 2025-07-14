import SwiftUI

// ItineraryView allows users to create and manage their travel itinerary.
// It displays a list of planned activities, attractions, and events for a selected city.
// Users can add, edit, or remove items from their itinerary.
struct ItineraryView: View {
    let city: City
    let startDate: Date
    let endDate: Date
    let homeCity: City
    let tripSchedule: TripSchedule
    @State private var attractions: [TouristAttraction] = []
    @State private var selectedHotels: [Int: Hotel?] = [:] // Map of day number to optional hotel
    @State private var transitDays: [TransitDay] = [] // Transit routes for each day
    @State private var isLoading = true
    @State private var error: Error?
    @State private var showingHotelList = false
    @State private var selectedDayForHotel: Int? = nil
    @State private var showingHotelDetail = false
    @State private var selectedHotelForDetail: Hotel? = nil
    @State private var showingCalendarView = false
    @Environment(\.dismiss) private var dismiss
    
    private var numberOfDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return (components.day ?? 0) + 1 // Include both start and end dates
    }
    
    private func dateForDay(_ dayIndex: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: dayIndex, to: startDate) ?? startDate
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Loading attractions...")
                    } else if let error = error {
                        Text("Error: \(error.localizedDescription)")
                            .foregroundColor(.red)
                    } else if attractions.isEmpty {
                        Text("No attractions found")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(0..<numberOfDays, id: \.self) { dayIndex in
                            let day = dayIndex + 1
                            let hotelBinding = Binding<Hotel?>(
                                get: { self.selectedHotels[day] ?? nil },
                                set: { self.selectedHotels[day] = $0 }
                            )
                            let timelineItems = PersonalAvailabilityCalendar.generateChronologicalTimeline(
                                dayDate: dateForDay(dayIndex),
                                attractions: attractionsForDay(dayIndex),
                                transitRoutes: transitRoutesForDay(day),
                                hotel: self.selectedHotels[day] ?? nil
                            )
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Day \(day)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text(formatDate(dateForDay(dayIndex)))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                HStack {
                                    if let hotel = self.selectedHotels[day], let unwrappedHotel = hotel {
                                        Text("Hotel: \(unwrappedHotel.name)")
                                            .font(.subheadline)
                                    }
                                    Spacer()
                                    Button(action: {
                                        selectedDayForHotel = day
                                        showingHotelList = true
                                    }) {
                                        Text(self.selectedHotels[day] == nil ? "Select Hotel" : "Change Hotel")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                                ChronologicalDayView(timelineItems: timelineItems)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("\(city.name) Itinerary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCalendarView = true
                    } label: {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $showingHotelList) {
            if let day = selectedDayForHotel {
                NavigationStack {
                    HotelListView(
                        city: city,
                        selectedHotel: Binding(
                            get: { self.selectedHotels[day] ?? nil },
                            set: { self.selectedHotels[day] = $0 }
                        ),
                        onDone: { showingHotelList = false }
                    )
                }
            } else {
                // Handle the case where a day is not selected, for global hotel change
                let globalHotelBinding = Binding<Hotel?>(
                    get: { self.selectedHotels.values.first ?? nil },
                    set: { newHotel in
                        for day in 1...numberOfDays {
                            self.selectedHotels[day] = newHotel
                        }
                    }
                )
                NavigationStack {
                    HotelListView(
                        city: city, 
                        selectedHotel: globalHotelBinding,
                        onDone: { showingHotelList = false }
                    )
                }
            }
        }
        .sheet(isPresented: $showingHotelDetail) {
            if let hotel = selectedHotelForDetail {
                NavigationStack {
                    HotelDetailView(
                        hotel: hotel,
                        city: city,
                        selectedHotel: .constant(nil) // Not used for detail view
                    )
                }
            }
        }
        .sheet(isPresented: $showingCalendarView) {
            NavigationStack {
                ItineraryCalendarView(
                    city: city,
                    startDate: startDate,
                    endDate: endDate,
                    homeCity: homeCity,
                    tripSchedule: tripSchedule
                )
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            // Only load data once when the view first appears
            if attractions.isEmpty {
                Task {
                    await loadData()
                }
            }
        }
    }
    
    private func loadData() async {
        isLoading = true
        error = nil
        
        do {
            let fetchedAttractions = try await GooglePlacesService.shared.fetchTouristAttractions(for: city)
            Logger.success("Fetched \(fetchedAttractions.count) attractions")
            
            await MainActor.run {
                self.attractions = fetchedAttractions
            }
            
            do {
                Logger.info("Fetching default hotel for \(city.name)")
                let hotel = try await GooglePlacesService.shared.findBestHotel(in: city)
                await MainActor.run {
                    // Only set default hotel for days that don't already have a selected hotel
                    for day in 1...numberOfDays {
                        if self.selectedHotels[day] == nil {
                            self.selectedHotels[day] = hotel
                        }
                    }
                }
                if let hotel = hotel {
                    Logger.success("Fetched default hotel: \(hotel.name)")
                } else {
                    Logger.warning("No default hotel found")
                }
            } catch {
                Logger.error("Error fetching default hotel: \(error.localizedDescription)")
            }
            
            // Generate transit routes
            do {
                Logger.info("Generating transit routes for \(city.name)")
                
                let transitRoutes = try await TransitService.shared.generateTransitRoutes(
                    tripSchedule: tripSchedule,
                    destinationCity: city,
                    selectedHotels: selectedHotels,
                    attractions: fetchedAttractions
                )
                await MainActor.run {
                    self.transitDays = transitRoutes
                }
                Logger.success("Generated \(transitRoutes.count) transit days")
            } catch {
                Logger.error("Error generating transit routes: \(error.localizedDescription)")
            }
        } catch {
            Logger.error("Error loading attractions: \(error)")
            self.error = error
        }
        
        isLoading = false
    }
    
    private func attractionsForDay(_ dayIndex: Int) -> [TouristAttraction] {
        let attractionsPerDay = Int(ceil(Double(attractions.count) / Double(numberOfDays)))
        let startIndex = dayIndex * attractionsPerDay
        let endIndex = min(startIndex + attractionsPerDay, attractions.count)
        guard startIndex < attractions.count else { return [] }
        return Array(attractions[startIndex..<endIndex])
    }
    
    private func transitRoutesForDay(_ day: Int) -> [TransitRoute] {
        let calendar = Calendar.current
        let date = dateForDay(day - 1)
        return transitDays.first { calendar.isDate($0.date, inSameDayAs: date) }?.routes ?? []
    }
}

struct ChronologicalDayView: View {
    let timelineItems: [UnifiedTimelineItem]
    var body: some View {
        ForEach(timelineItems) { item in
            switch item {
            case .attraction(let attraction, let start, let end):
                AttractionCard(attraction: attraction, timeSlot: TimeSlot(startTime: start, endTime: end))
            case .hotel(let hotel, _, _):
                HotelCard(hotel: hotel, schedule: nil as HotelSchedule?, onHotelChange: nil, onImageTap: nil)
            case .transit(let route, _, _):
                TransitCard(route: route)
            case .meal(let name, let start, let end):
                HStack {
                    Image(systemName: name == "Breakfast" ? "sunrise.fill" : name == "Lunch" ? "fork.knife" : "moon.stars.fill")
                        .foregroundColor(.gray)
                        .font(.title2)
                    Text(name)
                        .font(.headline)
                    Spacer()
                    Text(formattedTimeRange(start, end))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            case .sleep(let start, let end):
                HStack {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(.blue.opacity(0.5))
                        .font(.title2)
                    Text("Sleep")
                        .font(.headline)
                    Spacer()
                    Text(formattedTimeRange(start, end))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(8)
                .background(Color(.systemGray5))
                .cornerRadius(10)
            }
        }
    }
}

private func formattedTimeRange(_ start: Date, _ end: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
}

// DayItineraryView displays a single day's itinerary with morning and afternoon activities.
// It shows the selected hotel and organizes attractions into time slots.
// The view allows users to view hotel details and manage their daily schedule.
struct DayItineraryView: View {
    let dayNumber: Int
    let date: Date
    let attractions: [TouristAttraction]
    let city: City
    @Binding var selectedHotel: Hotel?
    let transitRoutes: [TransitRoute]
    let onHotelSelect: (Int) -> Void
    let onHotelImageTap: (Hotel) -> Void
    
    // Cache the calculated attractions
    private let morningAttractions: [(attraction: TouristAttraction, timeSlot: TimeSlot)]
    private let afternoonAttractions: [(attraction: TouristAttraction, timeSlot: TimeSlot)]
    
    init(dayNumber: Int, date: Date, attractions: [TouristAttraction], city: City, selectedHotel: Binding<Hotel?>, transitRoutes: [TransitRoute], onHotelSelect: @escaping (Int) -> Void, onHotelImageTap: @escaping (Hotel) -> Void) {
        self.dayNumber = dayNumber
        self.date = date
        self.attractions = attractions
        self.city = city
        self._selectedHotel = selectedHotel
        self.transitRoutes = transitRoutes
        self.onHotelSelect = onHotelSelect
        self.onHotelImageTap = onHotelImageTap
        
        // Calculate morning attractions
        var scheduledMorning: [(TouristAttraction, TimeSlot)] = []
        var nextMorningStartTime = TimeSlot.morningSlot.startTime
        
        for attraction in attractions {
            let attractionDuration = attraction.estimatedDuration * 60
            let nextEndTime = nextMorningStartTime.addingTimeInterval(attractionDuration)
            
            if nextEndTime <= TimeSlot.morningSlot.endTime {
                let timeSlot = TimeSlot(startTime: nextMorningStartTime, endTime: nextEndTime)
                scheduledMorning.append((attraction, timeSlot))
                nextMorningStartTime = nextEndTime
                Logger.debug("Added to morning: \(attraction.name) from \(timeSlot.formattedTime)")
            }
        }
        self.morningAttractions = scheduledMorning
        
        // Calculate afternoon attractions
        let remainingAttractions = attractions.filter { attr in !scheduledMorning.contains(where: { $0.0.id == attr.id }) }
        var scheduledAfternoon: [(TouristAttraction, TimeSlot)] = []
        var nextAfternoonStartTime = TimeSlot.afternoonSlot.startTime

        for attraction in remainingAttractions {
            let attractionDuration = attraction.estimatedDuration * 60
            let nextEndTime = nextAfternoonStartTime.addingTimeInterval(attractionDuration)

            if nextEndTime <= TimeSlot.afternoonSlot.endTime {
                let timeSlot = TimeSlot(startTime: nextAfternoonStartTime, endTime: nextEndTime)
                scheduledAfternoon.append((attraction, timeSlot))
                nextAfternoonStartTime = nextEndTime
                Logger.debug("Added to afternoon: \(attraction.name) from \(timeSlot.formattedTime)")
            }
        }
        self.afternoonAttractions = scheduledAfternoon
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Day Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Day \(dayNumber)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(formatDate(date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Morning Section
            if !morningAttractions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Morning (09:00 - 12:00)")
                        .font(.headline)
                    
                    ForEach(morningAttractions, id: \.attraction.id) { scheduledAttraction in
                        NavigationLink(destination: AttractionDetailView(attraction: convertAttraction(scheduledAttraction.attraction))) {
                            AttractionCard(attraction: scheduledAttraction.attraction, timeSlot: scheduledAttraction.timeSlot)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Transit Routes Section
            if !transitRoutes.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Transportation")
                        .font(.headline)
                    
                    ForEach(transitRoutes, id: \.id) { route in
                        TransitCard(route: route)
                    }
                }
            }
            
            // Afternoon Section
            if !afternoonAttractions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Afternoon (13:00 - 17:00)")
                        .font(.headline)
                    
                    ForEach(afternoonAttractions, id: \.attraction.id) { scheduledAttraction in
                        NavigationLink(destination: AttractionDetailView(attraction: convertAttraction(scheduledAttraction.attraction))) {
                            AttractionCard(attraction: scheduledAttraction.attraction, timeSlot: scheduledAttraction.timeSlot)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Hotel Section at the end of the day
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Evening Accommodation")
                        .font(.headline)
                    Spacer()
                    Button(action: { onHotelSelect(dayNumber) }) {
                        Text(selectedHotel == nil ? "Select Hotel" : "Change Hotel")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                if let hotel = selectedHotel {
                    // Hotel card is tappable for hotel selection, image is tappable for details
                    Button(action: { onHotelSelect(dayNumber) }) {
                        HotelCard(
                            hotel: hotel,
                            schedule: nil as HotelSchedule?,
                            onHotelChange: { onHotelSelect(dayNumber) },
                            onImageTap: { onHotelImageTap(hotel) }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Button(action: { onHotelSelect(dayNumber) }) {
                        VStack {
                            Image(systemName: "bed.double")
                                .font(.largeTitle)
                            Text("Select a Hotel")
                                .font(.headline)
                        }
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(16)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func convertAttraction(_ touristAttraction: TouristAttraction) -> Attraction {
        return Attraction(
            id: touristAttraction.id.uuidString,
            name: touristAttraction.name,
            description: touristAttraction.description,
            address: "", // TouristAttraction doesn't have address
            rating: 0.0, // TouristAttraction doesn't have rating
            imageURL: touristAttraction.imageURL,
            coordinates: touristAttraction.coordinates.locationCoordinate,
            websiteURL: touristAttraction.websiteURL,
            priceLevel: .moderate, // Default to moderate
            category: Category(rawValue: touristAttraction.category.rawValue) ?? .historical,
            estimatedDuration: touristAttraction.estimatedDuration,
            tips: touristAttraction.tips
        )
    }
}

#Preview {
    NavigationStack {
        ItineraryView(
            city: City(
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
                coordinates: City.Coordinates(latitude: 48.8566, longitude: 2.3522),
                timezone: "Europe/Paris",
                imageURLs: ["paris_1", "paris_2", "paris_3"],
                facts: [
                    "Paris is often called the City of Light (la Ville Lumière)",
                    "The Louvre is the world's largest art museum",
                    "Paris hosts one of the world's major fashion weeks"
                ]
            ),
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 3),
            homeCity: City(
                id: UUID(),
                name: "New York",
                country: "USA",
                continent: .northAmerica,
                population: 8419000,
                description: "New York is the most populous city in the United States.",
                landmarks: [],
                coordinates: City.Coordinates(latitude: 40.7128, longitude: -74.0060),
                timezone: "America/New_York",
                imageURLs: [],
                facts: []
            ),
            tripSchedule: TripSchedule(
                homeCity: "New York",
                departureDate: Date(),
                departureTime: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date(),
                returnDate: Date().addingTimeInterval(86400 * 3),
                returnTime: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date().addingTimeInterval(86400 * 3)) ?? Date()
            )
        )
    }
} 





