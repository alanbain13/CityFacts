import SwiftUI
import MapKit

// TravelPlannerView allows users to plan their travel by selecting a destination city.
// It provides a search interface to find cities and displays a list of available cities.
// Users can select a city to view detailed information and plan their route.
struct TravelPlannerView: View {
    @StateObject private var viewModel = TravelPlannerViewModel()
    @State private var selectedCity: City?
    @State private var homeCity: City?
    @State private var showingCitySearch = false
    @State private var showingHomeCitySearch = false
    @State private var showingItinerary = false
    @State private var showingRoute = false
    @State private var userLocation: CLLocationCoordinate2D?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Home city selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Home City")
                        .font(.headline)
                    
                    Button {
                        showingHomeCitySearch = true
                    } label: {
                        HStack {
                            Text(homeCity?.name ?? "Select your home city...")
                                .foregroundColor(homeCity == nil ? .gray : .primary)
                            Spacer()
                            Image(systemName: "house.fill")
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                // Destination city selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Destination City")
                        .font(.headline)
                    
                    Button {
                        showingCitySearch = true
                    } label: {
                        HStack {
                            Text(selectedCity?.name ?? "Search for a city...")
                                .foregroundColor(selectedCity == nil ? .gray : .primary)
                            Spacer()
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                // Date selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Dates")
                        .font(.headline)
                    
                    HStack {
                        DatePicker("Start Date", selection: $viewModel.startDate, in: Date()..., displayedComponents: .date)
                            .labelsHidden()
                        
                        Text("to")
                            .foregroundColor(.gray)
                        
                        DatePicker("End Date", selection: $viewModel.endDate, in: viewModel.startDate..., displayedComponents: .date)
                            .labelsHidden()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Route button
                if let homeCity = homeCity, let selectedCity = selectedCity {
                    Button {
                        showingRoute = true
                    } label: {
                        HStack {
                            Image(systemName: "map.fill")
                            Text("Show Route")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                // Generate button
                Button {
                    showingItinerary = true
                } label: {
                    Text("Generate Itinerary")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedCity != nil ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(selectedCity == nil)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("Travel Planner")
            .sheet(isPresented: $showingCitySearch) {
                CitySearchView(selectedCity: $selectedCity)
            }
            .sheet(isPresented: $showingHomeCitySearch) {
                CitySearchView(selectedCity: $homeCity)
            }
            .sheet(isPresented: $showingItinerary) {
                if let city = selectedCity {
                    NavigationStack {
                        ItineraryView(city: city, startDate: viewModel.startDate, endDate: viewModel.endDate)
                            .onAppear {
                                print("[\(Date())] ItineraryView sheet appeared")
                            }
                    }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $showingRoute) {
                if let homeCity = homeCity, let selectedCity = selectedCity {
                    NavigationView {
                        RouteView(
                            origin: CLLocationCoordinate2D(
                                latitude: homeCity.coordinates.latitude,
                                longitude: homeCity.coordinates.longitude
                            ),
                            destination: CLLocationCoordinate2D(
                                latitude: selectedCity.coordinates.latitude,
                                longitude: selectedCity.coordinates.longitude
                            ),
                            city: selectedCity
                        )
                    }
                }
            }
            .task {
                // Request location permission and get user's location
                let locationManager = CLLocationManager()
                locationManager.requestWhenInUseAuthorization()
                
                if let location = locationManager.location?.coordinate {
                    userLocation = location
                }
            }
        }
    }
}

class TravelPlannerViewModel: ObservableObject {
    @Published var startDate: Date = {
        let calendar = Calendar.current
        let now = Date()
        return calendar.startOfDay(for: now)
    }()
    
    @Published var endDate: Date = {
        let calendar = Calendar.current
        let now = Date()
        let threeDaysLater = calendar.date(byAdding: .day, value: 3, to: now) ?? now
        return calendar.startOfDay(for: threeDaysLater)
    }()
    
    var numberOfDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return (components.day ?? 0) + 1 // Include both start and end dates
    }
}

#Preview {
    TravelPlannerView()
} 
