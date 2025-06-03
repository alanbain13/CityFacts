import SwiftUI
import MapKit

// CitySearchView provides a search interface for users to find cities.
// It displays a list of cities matching the search query and allows users to select a city.
// The view integrates with the CityStore to fetch and display city data.
struct CitySearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CitySearchViewModel()
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
                        .onChange(of: searchText) { newValue in
                            if !newValue.isEmpty {
                                Task {
                                    await viewModel.searchCities(query: newValue)
                                }
                            } else {
                                viewModel.searchResults = []
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            viewModel.searchResults = []
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
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                } else if viewModel.searchResults.isEmpty && !searchText.isEmpty {
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
                        ForEach(viewModel.searchResults) { city in
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
// It handles searching for cities using the Google Places service and manages loading states.
// The view model provides search results and error handling for the CitySearchView.
class CitySearchViewModel: ObservableObject {
    @Published var searchResults: [City] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let placesService = GooglePlacesService.shared
    
    func searchCities(query: String) async {
        guard !query.isEmpty else {
            await MainActor.run {
                searchResults = []
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let cities = try await placesService.searchCities(query: query)
            
            await MainActor.run {
                searchResults = cities
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

#Preview {
    CitySearchView(selectedCity: .constant(nil))
} 