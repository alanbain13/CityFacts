import SwiftUI

// CitiesListView displays a list of cities available in the app.
// It allows users to search for cities and filter them by continent or country.
// Users can select a city to view its details or plan a route.
struct CitiesListView: View {
    @EnvironmentObject private var cityStore: CityStore
    @State private var showingFilters = false
    @State private var selectedCity: City?
    @State private var showingCitySearch = false
    
    var body: some View {
        List {
            ForEach(cityStore.filteredCities) { city in
                NavigationLink {
                    CityDetailView(city: city)
                } label: {
                    CityRowView(city: city)
                }
                .contextMenu {
                    Button {
                        selectedCity = city
                    } label: {
                        Label("Show on Map", systemImage: "map")
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Cities")
        .searchable(text: $cityStore.searchText, prompt: "Search cities...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingFilters.toggle()
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .symbolVariant(cityStore.selectedContinent != nil || cityStore.selectedPopulationRange != nil ? .fill : .none)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCitySearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                }
            }
            
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink {
                    MapView()
                } label: {
                    Image(systemName: "map")
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterView()
                .presentationDetents([.medium])
        }
        .sheet(item: $selectedCity) { city in
            NavigationStack {
                MapView(initialCity: city)
            }
        }
        .sheet(isPresented: $showingCitySearch) {
            CitySearchView(selectedCity: $selectedCity)
        }
    }
}

// CityRowView displays a single city in a list format.
// It shows the city name, country, and a star icon if the city is marked as favorite.
// The view is used in lists and search results throughout the app.
struct CityRowView: View {
    let city: City
    @EnvironmentObject private var cityStore: CityStore
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(city.name)
                    .font(.headline)
                Text(city.country)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if cityStore.isFavorite(city) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FilterView: View {
    @EnvironmentObject private var cityStore: CityStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Continent") {
                    Picker("Select Continent", selection: $cityStore.selectedContinent) {
                        Text("Any").tag(Optional<CityStore.Continent>.none)
                        ForEach(CityStore.Continent.allCases, id: \.self) { continent in
                            Text(continent.rawValue).tag(Optional(continent))
                        }
                    }
                }
                
                Section("Population") {
                    Picker("Select Population Range", selection: $cityStore.selectedPopulationRange) {
                        Text("Any").tag(Optional<CityStore.PopulationRange>.none)
                        ForEach(CityStore.PopulationRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(Optional(range))
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        cityStore.selectedContinent = nil
                        cityStore.selectedPopulationRange = nil
                    }
                    .disabled(cityStore.selectedContinent == nil && cityStore.selectedPopulationRange == nil)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CitiesListView()
            .environmentObject(CityStore())
    }
} 