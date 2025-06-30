import SwiftUI

// ItineraryView allows users to create and manage their travel itinerary.
// It displays a list of planned activities, attractions, and events for a selected city.
// Users can add, edit, or remove items from their itinerary.
struct ItineraryView: View {
    let city: City
    let startDate: Date
    let endDate: Date
    @State private var attractions: [TouristAttraction] = []
    @State private var selectedHotels: [Int: Hotel?] = [:] // Map of day number to optional hotel
    @State private var isLoading = true
    @State private var error: Error?
    @State private var showingHotelList = false
    @State private var selectedDayForHotel: Int? = nil
    @State private var showingHotelDetail = false
    @State private var selectedHotelForDetail: Hotel? = nil
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
                            
                            DayItineraryView(
                                dayNumber: day,
                                date: dateForDay(dayIndex),
                                attractions: attractionsForDay(dayIndex),
                                city: city,
                                selectedHotel: hotelBinding,
                                onHotelSelect: { day in
                                    selectedDayForHotel = day
                                    showingHotelList = true
                                },
                                onHotelImageTap: { hotel in
                                    selectedHotelForDetail = hotel
                                    showingHotelDetail = true
                                }
                            )
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
        return Array(attractions[startIndex..<endIndex])
    }
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
    let onHotelSelect: (Int) -> Void
    let onHotelImageTap: (Hotel) -> Void
    
    // Cache the calculated attractions
    private let morningAttractions: [(attraction: TouristAttraction, timeSlot: TimeSlot)]
    private let afternoonAttractions: [(attraction: TouristAttraction, timeSlot: TimeSlot)]
    
    init(dayNumber: Int, date: Date, attractions: [TouristAttraction], city: City, selectedHotel: Binding<Hotel?>, onHotelSelect: @escaping (Int) -> Void, onHotelImageTap: @escaping (Hotel) -> Void) {
        self.dayNumber = dayNumber
        self.date = date
        self.attractions = attractions
        self.city = city
        self._selectedHotel = selectedHotel
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
            endDate: Date().addingTimeInterval(86400 * 3)
        )
    }
} 





