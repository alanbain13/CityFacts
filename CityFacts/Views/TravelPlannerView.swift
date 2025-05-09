import SwiftUI
import MapKit

struct TravelPlannerView: View {
    @StateObject private var viewModel = TravelPlannerViewModel()
    @State private var selectedCity: City?
    @State private var showingCitySearch = false
    @State private var showingItinerary = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // City selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select a City")
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
            .sheet(isPresented: $showingItinerary) {
                if let city = selectedCity {
                    NavigationStack {
                        ItineraryView(city: city, startDate: viewModel.startDate, endDate: viewModel.endDate)
                    }
                }
            }
        }
    }
}

class TravelPlannerViewModel: ObservableObject {
    @Published var startDate = Date()
    @Published var endDate = Date().addingTimeInterval(86400 * 3) // 3 days later
}

#Preview {
    TravelPlannerView()
} 
