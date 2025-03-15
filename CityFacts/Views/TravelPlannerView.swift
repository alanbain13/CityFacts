import SwiftUI

struct TravelPlannerView: View {
    @EnvironmentObject private var cityStore: CityStore
    @State private var selectedCity: City?
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var showingCityPicker = false
    @State private var showingItinerary = false
    
    var numberOfDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
    }
    
    var body: some View {
        Form {
            Section("Destination") {
                Button {
                    showingCityPicker = true
                } label: {
                    HStack {
                        Text(selectedCity?.name ?? "Select a city")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("Travel Dates") {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                DatePicker("End Date", selection: $endDate, displayedComponents: .date)
            }
            
            if let city = selectedCity {
                Section("Trip Duration") {
                    Text("\(numberOfDays) days")
                }
            }
            
            Section {
                Button("Generate Itinerary") {
                    showingItinerary = true
                }
                .disabled(selectedCity == nil)
                .frame(maxWidth: .infinity)
                .foregroundStyle(.white)
                .padding()
                .background(selectedCity == nil ? Color.gray : Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .navigationTitle("Travel Planner")
        .sheet(isPresented: $showingCityPicker) {
            CityPickerView(selectedCity: $selectedCity)
        }
        .sheet(isPresented: $showingItinerary) {
            if let city = selectedCity {
                ItineraryView(city: city, numberOfDays: numberOfDays)
            }
        }
    }
}

struct CityPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCity: City?
    @EnvironmentObject private var cityStore: CityStore
    
    var body: some View {
        NavigationStack {
            List(cityStore.cities) { city in
                Button {
                    selectedCity = city
                    dismiss()
                } label: {
                    HStack {
                        Text(city.name)
                        Spacer()
                        if selectedCity?.id == city.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ItineraryView: View {
    let city: City
    let numberOfDays: Int
    @State private var attractions: [TouristAttraction] = []
    @State private var isLoading = true
    @State private var error: Error?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading attractions...")
                } else if let error = error {
                    VStack {
                        Text("Error loading attractions")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(0..<numberOfDays, id: \.self) { day in
                                DayItineraryView(
                                    dayNumber: day + 1,
                                    attractions: attractionsForDay(day)
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
        }
        .task {
            await loadAttractions()
        }
    }
    
    private func loadAttractions() async {
        isLoading = true
        error = nil
        
        do {
            attractions = try await GooglePlacesService.shared.fetchTouristAttractions(for: city)
        } catch {
            self.error = error
            print("Error loading attractions: \(error)")
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Day \(dayNumber)")
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(attractions) { attraction in
                AttractionCard(attraction: attraction)
            }
        }
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    NavigationStack {
        TravelPlannerView()
            .environmentObject(CityStore())
    }
} 
