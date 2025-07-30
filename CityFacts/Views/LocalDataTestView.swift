// MARK: - LocalDataTestView
// Description: Test view for demonstrating local data loading and service abstraction functionality.
// Version: 0.0.1
// Modification Date: 2024-06-09
// Author: Cursor

import SwiftUI

struct LocalDataTestView: View {
    @StateObject private var cityStore = CityStore(isPremiumUser: false)
    @State private var selectedCity: City?
    @State private var attractions: [Attraction] = []
    @State private var hotels: [Hotel] = []
    @State private var venues: [Venue] = []
    @State private var isLoading = false
    
    init() {
        print("📱 LocalDataTestView initialized")
    }
    
    var body: some View {
        NavigationView {
            VStack {
                                            // Debug Info
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Debug Info:")
                                    .font(.headline)
                                Text("Cities loaded: \(cityStore.cities.count)")
                                    .font(.caption)
                                Text("Premium mode: \(cityStore.isPremiumUser ? "Yes" : "No")")
                                    .font(.caption)
                                Text("Venues loaded: \(cityStore.venues.count)")
                                    .font(.caption)
                            }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // Service Mode Toggle
                HStack {
                    Text("Service Mode:")
                        .font(.headline)
                    
                    Button("Local") {
                        print("🔄 Switching to Local mode")
                        cityStore.switchToLocal()
                    }
                    .buttonStyle(.bordered)
                    .background(cityStore.isPremiumUser ? Color.clear : Color.blue)
                    .foregroundColor(cityStore.isPremiumUser ? .primary : .white)
                    
                    Button("Premium") {
                        print("🔄 Switching to Premium mode")
                        cityStore.switchToPremium()
                    }
                    .buttonStyle(.bordered)
                    .background(cityStore.isPremiumUser ? Color.blue : Color.clear)
                    .foregroundColor(cityStore.isPremiumUser ? .white : .primary)
                }
                .padding()
                
                // Cities List
                List {
                    ForEach(cityStore.cities) { city in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(city.name)
                                .font(.headline)
                            Text(city.country)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(city.coordinates.latitude), \(city.coordinates.longitude)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Population: \(city.population)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if !city.description.isEmpty {
                                Text(city.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 4)
                        .onTapGesture {
                            selectedCity = city
                            loadCityData(for: city)
                        }
                    }
                }
                
                                            // Selected City Details
                            if let city = selectedCity {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Selected: \(city.name)")
                                        .font(.title2)
                                        .bold()

                                    HStack {
                                        VStack {
                                            Text("\(attractions.count)")
                                                .font(.title)
                                                .bold()
                                            Text("Attractions")
                                                .font(.caption)
                                        }
                                        .frame(maxWidth: .infinity)

                                        VStack {
                                            Text("\(hotels.count)")
                                                .font(.title)
                                                .bold()
                                            Text("Hotels")
                                                .font(.caption)
                                        }
                                        .frame(maxWidth: .infinity)
                                        
                                        VStack {
                                            Text("\(venues.count)")
                                                .font(.title)
                                                .bold()
                                            Text("Venues")
                                                .font(.caption)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(10)

                                    if isLoading {
                                        ProgressView("Loading data...")
                                            .frame(maxWidth: .infinity)
                                    }
                                    
                                    // Show first few attractions, hotels, and venues in a compact layout
                                    if !attractions.isEmpty || !hotels.isEmpty || !venues.isEmpty {
                                        VStack(alignment: .leading, spacing: 6) {
                                            if !attractions.isEmpty {
                                                HStack {
                                                    Text("Attractions:")
                                                        .font(.caption)
                                                        .fontWeight(.semibold)
                                                    Spacer()
                                                    Text("\(attractions.count)")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                                ForEach(attractions.prefix(2), id: \.id) { attraction in
                                                    Text("• \(attraction.name)")
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            if !hotels.isEmpty {
                                                HStack {
                                                    Text("Hotels:")
                                                        .font(.caption)
                                                        .fontWeight(.semibold)
                                                    Spacer()
                                                    Text("\(hotels.count)")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                                ForEach(hotels.prefix(2), id: \.id) { hotel in
                                                    Text("• \(hotel.name)")
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            if !venues.isEmpty {
                                                HStack {
                                                    Text("Venues:")
                                                        .font(.caption)
                                                        .fontWeight(.semibold)
                                                    Spacer()
                                                    Text("\(venues.count)")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                                ForEach(venues.prefix(2), id: \.id) { venue in
                                                    Text("• \(venue.name)")
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                        .padding(.top, 8)
                                    }
                                }
                                .padding()
                            }
                
                Spacer()
            }
            .navigationTitle("Local Data Test")
            .onAppear {
                // Load initial data
                if cityStore.cities.isEmpty {
                    // For local mode, we need to wait for the LocalDataService to load
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        // This would need to be updated to actually load from LocalDataService
                        print("Local data should be loaded by now")
                    }
                }
            }
        }
    }
    
                    private func loadCityData(for city: City) {
                    isLoading = true

                    Task {
                        let cityAttractions = await cityStore.getAttractions(for: city)
                        let cityHotels = await cityStore.getHotels(for: city)
                        let cityVenues = await cityStore.getVenues(for: city)

                        await MainActor.run {
                            self.attractions = cityAttractions
                            self.hotels = cityHotels
                            self.venues = cityVenues
                            self.isLoading = false
                        }
                    }
                }
}

#Preview {
    LocalDataTestView()
} 