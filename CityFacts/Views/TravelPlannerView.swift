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
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: TouristAttraction.Category?
    
    var attractions: [TouristAttraction] {
        TouristAttraction.generateAttractions(for: city)
    }
    
    var dailyItineraries: [[TouristAttraction]] {
        // Group attractions into daily itineraries
        let attractionsPerDay = max(1, attractions.count / numberOfDays)
        
        return stride(from: 0, to: attractions.count, by: attractionsPerDay).map {
            Array(attractions[$0..<min($0 + attractionsPerDay, attractions.count)])
        }
    }
    
    var filteredAttractions: [TouristAttraction] {
        if let category = selectedCategory {
            return attractions.filter { $0.category == category }
        }
        return attractions
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryButton(title: "All", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }
                            
                            ForEach(TouristAttraction.Category.allCases, id: \.self) { category in
                                CategoryButton(
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Daily itineraries
                    ForEach(Array(dailyItineraries.enumerated()), id: \.offset) { index, attractions in
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Day \(index + 1)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            ForEach(attractions) { attraction in
                                AttractionCard(attraction: attraction)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("\(city.name) Itinerary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
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

struct AttractionCard: View {
    let attraction: TouristAttraction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: attraction.imageURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(attraction.name)
                    .font(.headline)
                
                Text(attraction.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Label("\(Int(attraction.estimatedDuration)) min", systemImage: "clock")
                    Spacer()
                    Text(attraction.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                if !attraction.tips.isEmpty {
                    Text("Tips:")
                        .font(.caption)
                        .fontWeight(.medium)
                    ForEach(attraction.tips, id: \.self) { tip in
                        Text("• \(tip)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal)
        }
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        TravelPlannerView()
            .environmentObject(CityStore())
    }
} 