import SwiftUI
import MapKit

// CitySearchView provides a search interface for users to find cities.
// It displays a list of cities matching the search query and allows users to select a city.
// The view integrates with the CityStore to fetch and display city data.
struct CitySearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cityStore = CityStore(isPremiumUser: false)
    @State private var searchText = ""
    @State private var selectedCity: City?
    @State private var showingCityDetail = false
    @Binding var selectedCityBinding: City?
    
    init(selectedCity: Binding<City?>) {
        self._selectedCityBinding = selectedCity
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search for any city...", text: $searchText)
                        .autocorrectionDisabled()
                    
                                            if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Results list
                let filteredCities = searchText.isEmpty ? cityStore.cities : cityStore.cities.filter { city in
                    city.name.localizedCaseInsensitiveContains(searchText) ||
                    city.country.localizedCaseInsensitiveContains(searchText)
                }
                
                if filteredCities.isEmpty && !searchText.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No cities found")
                            .font(.headline)
                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredCities) { city in
                            Button {
                                selectedCityBinding = city
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(city.name)
                                            .font(.headline)
                                        Text(city.country)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search Cities")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
    }
}

// CitySearchViewModel manages the state and logic for city search functionality.
// It handles searching for cities using the CityStore and manages loading states.
// The view model provides search results and error handling for the CitySearchView.
@MainActor
class CitySearchViewModel: ObservableObject {
    @Published var searchResults: [City] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let cityStore = CityStore()
    
    func searchCities(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Use CityStore's filtered cities functionality
        cityStore.searchText = query
        searchResults = cityStore.filteredCities
        isLoading = false
    }
}

#Preview {
    CitySearchView(selectedCity: .constant(nil))
} 