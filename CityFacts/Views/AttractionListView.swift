/// AttractionListView.swift
/// A view that displays a list of attractions for a given city.
/// This view handles loading, displaying, and selecting attractions,
/// as well as showing detailed information about each attraction.

import SwiftUI
import CoreLocation

/// AttractionListView displays a list of attractions for a selected city.
/// It allows users to filter attractions by category or search for specific attractions.
/// Users can select an attraction to view its details or add it to their itinerary.
struct AttractionListView: View {
    /// Dismiss action for the view
    @Environment(\.dismiss) private var dismiss
    
    /// The currently selected attraction, bound to the parent view
    @Binding var selectedAttraction: Attraction?
    
    /// The city for which to display attractions
    let city: City
    
    /// Array of loaded attractions
    @State private var attractions: [Attraction] = []
    
    /// Loading state indicator
    @State private var isLoading = true
    
    /// Error state for attraction loading failures
    @State private var error: Error?
    
    /// The attraction selected for detailed view
    @State private var selectedAttractionForDetails: Attraction?
    
    /// Controls the presentation of the attraction details sheet
    @State private var showingAttractionDetails = false
    
    /// The main view body displaying a list of attractions with loading, error,
    /// and empty states handled appropriately.
    /// 
    /// This view provides:
    /// - Loading indicator while fetching attractions
    /// - Error view with retry option if loading fails
    /// - Empty state message if no attractions found
    /// - Scrollable list of attractions when loaded
    /// - Navigation title showing the city name
    /// - Cancel button to dismiss the view
    /// - Detail view presentation when an attraction is selected
    var body: some View {
        NavigationView {
            mainContent
                .navigationTitle("Attractions in \(city.name)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .sheet(isPresented: $showingAttractionDetails) {
                    if let attraction = selectedAttractionForDetails {
                        attractionDetailsSheet(for: attraction)
                    }
                }
        }
        .task {
            await loadAttractions()
        }
    }
    
    private var mainContent: some View {
        Group {
            if isLoading {
                loadingView
            } else if let error = error {
                errorView(error: error)
            } else if attractions.isEmpty {
                emptyView
            } else {
                attractionsList
            }
        }
    }
    
    private var loadingView: some View {
        ProgressView("Loading attractions...")
    }
    
    private var emptyView: some View {
        Text("No attractions found")
            .foregroundStyle(.secondary)
    }
    
    private func errorView(error: Error) -> some View {
        VStack(spacing: 16) {
            Text("Error loading attractions")
                .font(.headline)
                .foregroundStyle(.red)
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task {
                    await loadAttractions()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    private var attractionsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(attractions) { attraction in
                    attractionRow(for: attraction)
                }
            }
            .padding()
        }
    }
    
    private func attractionRow(for attraction: Attraction) -> some View {
        AttractionRow(
            attraction: attraction,
            isSelected: attraction.id == selectedAttraction?.id,
            onSelect: {
                selectedAttractionForDetails = attraction
                showingAttractionDetails = true
            }
        )
    }
    
    private func attractionDetailsSheet(for attraction: Attraction) -> some View {
        NavigationView {
            AttractionDetailView(attraction: attraction)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingAttractionDetails = false
                        }
                    }
                }
        }
    }
    
    /// Asynchronously loads attractions for the current city using the Google Places API.
    /// 
    /// This function:
    /// - Sets loading state to true and clears any previous errors
    /// - Converts city coordinates to CLLocationCoordinate2D format
    /// - Fetches nearby tourist attractions using the Google Places API
    /// - Maps the API response to Attraction models
    /// - Updates the attractions array with the results
    /// - Handles any errors that occur during the process
    /// - Sets loading state to false when complete
    ///
    /// The function uses default values for rating (0.0) and price level (moderate)
    /// when this information is not available from the Places API.
    private func loadAttractions() async {
        print("Starting to load attractions for \(city.name)")
        isLoading = true
        error = nil
        
        do {
            print("Fetching tourist attractions from Google Places API")
            let fetchedAttractions = try await GooglePlacesService.shared.fetchTouristAttractions(for: city)
            print("Found \(fetchedAttractions.count) attractions")
            
            attractions = fetchedAttractions.map { ta in
                Attraction(
                    id: ta.id.uuidString,
                    name: ta.name,
                    description: ta.description,
                    address: ta.description, // fallback, as TouristAttraction may not have address
                    rating: 0.0,
                    imageURL: ta.imageURL,
                    coordinates: CLLocationCoordinate2D(latitude: ta.coordinates.latitude, longitude: ta.coordinates.longitude),
                    websiteURL: ta.websiteURL,
                    priceLevel: .moderate
                )
            }
            print("Total attractions loaded: \(attractions.count)")
        } catch {
            print("Error loading attractions: \(error.localizedDescription)")
            self.error = error
        }
        
        isLoading = false
        print("Finished loading attractions")
    }
} 