import SwiftUI

struct CitiesListView: View {
    @EnvironmentObject private var cityStore: CityStore
    @State private var showingFilters = false
    
    var body: some View {
        List {
            ForEach(cityStore.filteredCities) { city in
                NavigationLink {
                    CityDetailView(city: city)
                } label: {
                    CityRowView(city: city)
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
        }
        .sheet(isPresented: $showingFilters) {
            FilterView()
                .presentationDetents([.medium])
        }
    }
}

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