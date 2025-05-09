import SwiftUI

struct ItineraryView: View {
    let city: City
    let startDate: Date
    let endDate: Date
    @State private var attractions: [TouristAttraction] = []
    @State private var selectedHotel: Hotel?
    @State private var isLoading = true
    @State private var error: Error?
    @Environment(\.dismiss) private var dismiss
    
    private var numberOfDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
    }
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading attractions...")
            } else if let error = error {
                VStack {
                    Text("Error loading attractions")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            } else if let hotel = selectedHotel {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(0..<numberOfDays, id: \.self) { day in
                            DayItineraryView(
                                dayNumber: day + 1,
                                attractions: attractionsForDay(day),
                                city: city,
                                selectedHotel: $selectedHotel
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("\(city.name) Itinerary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") {
                    dismiss()
                }
            }
        }
        .task {
            await loadData()
        }
    }
    
    private func loadData() async {
        isLoading = true
        error = nil
        
        do {
            async let attractionsTask = GooglePlacesService.shared.fetchTouristAttractions(for: city)
            async let hotelTask = GooglePlacesService.shared.findBestHotel(in: city)
            
            let (fetchedAttractions, fetchedHotel) = try await (attractionsTask, hotelTask)
            self.attractions = fetchedAttractions
            self.selectedHotel = fetchedHotel
        } catch {
            self.error = error
            print("Error loading data: \(error)")
        }
        
        isLoading = false
    }
    
    private func attractionsForDay(_ day: Int) -> [TouristAttraction] {
        let attractionsPerDay = max(1, attractions.count / numberOfDays)
        let startIndex = day * attractionsPerDay
        let endIndex = min(startIndex + attractionsPerDay, attractions.count)
        return Array(attractions[startIndex..<endIndex])
    }
}

struct DayItineraryView: View {
    let dayNumber: Int
    let attractions: [TouristAttraction]
    let city: City
    @Binding var selectedHotel: Hotel?
    @State private var showingHotelDetails = false
    
    private var morningAttractions: [TouristAttraction] {
        var remainingTime = TimeSlot.morningSlot.duration
        var selected: [TouristAttraction] = []
        
        for attraction in attractions {
            if remainingTime >= attraction.estimatedDuration {
                selected.append(attraction)
                remainingTime -= attraction.estimatedDuration
            }
        }
        
        return selected
    }
    
    private var afternoonAttractions: [TouristAttraction] {
        var remainingTime = TimeSlot.afternoonSlot.duration
        var selected: [TouristAttraction] = []
        
        for attraction in attractions where !morningAttractions.contains(where: { $0.id == attraction.id }) {
            if remainingTime >= attraction.estimatedDuration {
                selected.append(attraction)
                remainingTime -= attraction.estimatedDuration
            }
        }
        
        return selected
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Day \(dayNumber)")
                .font(.title2)
                .fontWeight(.bold)
            
            // Morning Slot
            VStack(alignment: .leading, spacing: 8) {
                Text("Morning (09:00 - 12:00)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                ForEach(morningAttractions) { attraction in
                    AttractionCard(attraction: attraction)
                }
            }
            
            // Afternoon Slot
            VStack(alignment: .leading, spacing: 8) {
                Text("Afternoon (14:00 - 17:00)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                ForEach(afternoonAttractions) { attraction in
                    AttractionCard(attraction: attraction)
                }
            }
            
            if let hotel = selectedHotel {
                // Hotel Card
                Button {
                    showingHotelDetails = true
                } label: {
                    HStack(spacing: 16) {
                        AsyncImage(url: URL(string: hotel.imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Hotel")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(hotel.name)
                                .font(.headline)
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                Text(String(format: "%.1f", hotel.rating))
                                Text("•")
                                Text(hotel.priceLevel.rawValue)
                            }
                            .font(.subheadline)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 2)
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showingHotelDetails) {
                    NavigationStack {
                        HotelDetailView(
                            hotel: hotel,
                            city: city,
                            selectedHotel: $selectedHotel
                        )
                    }
                }
            }
        }
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
