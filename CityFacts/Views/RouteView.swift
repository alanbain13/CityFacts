import SwiftUI
import MapKit

struct RouteView: View {
    let origin: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    let city: City
    
    @State private var route: RouteService.Route?
    @State private var isLoading = false
    @State private var error: Error?
    @State private var region: MKCoordinateRegion
    
    init(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, city: City) {
        self.origin = origin
        self.destination = destination
        self.city = city
        
        // Initialize the map region to show both points
        let center = CLLocationCoordinate2D(
            latitude: (origin.latitude + destination.latitude) / 2,
            longitude: (origin.longitude + destination.longitude) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: abs(origin.latitude - destination.latitude) * 1.5,
            longitudeDelta: abs(origin.longitude - destination.longitude) * 1.5
        )
        _region = State(initialValue: MKCoordinateRegion(center: center, span: span))
    }
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading route...")
            } else if let error = error {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("Error loading route")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            } else if let route = route {
                VStack {
                    Map(coordinateRegion: $region, annotationItems: [
                        MapLocation(coordinate: origin, title: "Start", subtitle: "Your location"),
                        MapLocation(coordinate: destination, title: city.name, subtitle: city.country)
                    ]) { location in
                        MapMarker(coordinate: location.coordinate, tint: location.title == "Start" ? .blue : .red)
                    }
                    .frame(height: 300)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            RouteInfoCard(
                                title: "Distance",
                                value: formatDistance(route.distanceMeters),
                                icon: "arrow.left.and.right"
                            )
                            
                            RouteInfoCard(
                                title: "Duration",
                                value: route.duration,
                                icon: "clock"
                            )
                            
                            Text("Directions")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(route.legs.first?.steps ?? [], id: \.navigationInstruction.instructions) { step in
                                DirectionStepView(step: step)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Route to \(city.name)")
        .task {
            await loadRoute()
        }
    }
    
    private func loadRoute() async {
        isLoading = true
        error = nil
        
        do {
            route = try await RouteService.shared.getRoute(from: origin, to: destination)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    private func formatDistance(_ meters: Int) -> String {
        let kilometers = Double(meters) / 1000.0
        return String(format: "%.1f km", kilometers)
    }
}

struct RouteInfoCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct DirectionStepView: View {
    let step: RouteService.Step
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "arrow.right.circle.fill")
                .foregroundColor(.blue)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(step.navigationInstruction.instructions)
                    .font(.subheadline)
                
                Text("\(formatDistance(step.distanceMeters)) • \(step.duration)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }
    
    private func formatDistance(_ meters: Int) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", Double(meters) / 1000.0)
        } else {
            return "\(meters) m"
        }
    }
}

struct MapLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let subtitle: String
}

#Preview {
    NavigationView {
        RouteView(
            origin: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
            destination: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
            city: City(
                id: UUID(),
                name: "Paris",
                country: "France",
                continent: .europe,
                population: 2148000,
                description: "The City of Light",
                landmarks: [],
                coordinates: City.Coordinates(latitude: 48.8566, longitude: 2.3522),
                timezone: "Europe/Paris",
                imageURLs: [],
                facts: []
            )
        )
    }
} 