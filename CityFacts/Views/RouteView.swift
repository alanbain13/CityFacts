import SwiftUI
import MapKit

// RouteView displays a map with a route between two locations (origin and destination).
// It fetches the route data from the RouteService and renders the route as a polyline on the map.
// The view also shows route details such as distance, duration, and step-by-step directions.
struct RouteView: View {
    let origin: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    let city: City
    
    @State private var route: RouteService.Route?
    @State private var isLoading = false
    @State private var error: Error?
    @State private var region: MKCoordinateRegion
    @State private var selectedTransportMode: RouteService.TravelMode = .driving
    @State private var routeOverlay: MKPolyline?
    
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
                    MapViewRepresentable(
                        region: $region,
                        routeOverlay: routeOverlay,
                        origin: origin,
                        destination: destination,
                        city: city
                    )
                    .frame(height: 300)
                    
                    Picker("Transport Mode", selection: $selectedTransportMode) {
                        Text("Driving").tag(RouteService.TravelMode.driving)
                        Text("Walking").tag(RouteService.TravelMode.walking)
                        Text("Bicycling").tag(RouteService.TravelMode.bicycling)
                        Text("Transit").tag(RouteService.TravelMode.transit)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .onChange(of: selectedTransportMode) { _ in
                        Task {
                            await loadRoute()
                        }
                    }
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            RouteInfoCard(
                                title: "Distance",
                                value: formatDistance(route.distanceMeters),
                                icon: "arrow.left.and.right"
                            )
                            
                            RouteInfoCard(
                                title: "Duration",
                                value: formatDuration(route.duration),
                                icon: "clock"
                            )
                            
                            Text("Directions")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(route.legs.first?.steps ?? [], id: \.polyline.encodedPolyline) { step in
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
            route = try await RouteService.shared.getRoute(from: origin, to: destination, travelMode: selectedTransportMode)
            if let route = route {
                routeOverlay = decodePolyline(route.polyline.encodedPolyline)
            }
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    private func formatDistance(_ meters: Int) -> String {
        let kilometers = Double(meters) / 1000.0
        return String(format: "%.1f km", kilometers)
    }
    
    private func formatDuration(_ duration: String) -> String {
        // Parse the duration string (format: "1234s" or "1234")
        let seconds = Int(duration.replacingOccurrences(of: "s", with: "")) ?? 0
        
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        
        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, remainingSeconds)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, remainingSeconds)
        } else {
            return String(format: "%ds", remainingSeconds)
        }
    }
    
    private func decodePolyline(_ encodedPolyline: String) -> MKPolyline {
        var coordinates: [CLLocationCoordinate2D] = []
        var index = encodedPolyline.startIndex
        var lat = 0.0
        var lng = 0.0
        
        while index < encodedPolyline.endIndex {
            // Decode latitude
            var shift = 0
            var result = 0
            
            while index < encodedPolyline.endIndex {
                guard let byte = encodedPolyline[index].asciiValue else { break }
                let value = Int(byte) - 63
                result |= (value & 0x1F) << shift
                shift += 5
                index = encodedPolyline.index(after: index)
                
                if value < 0x20 { break }
            }
            
            let latValue = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
            lat += Double(latValue)
            
            // Decode longitude
            shift = 0
            result = 0
            
            while index < encodedPolyline.endIndex {
                guard let byte = encodedPolyline[index].asciiValue else { break }
                let value = Int(byte) - 63
                result |= (value & 0x1F) << shift
                shift += 5
                index = encodedPolyline.index(after: index)
                
                if value < 0x20 { break }
            }
            
            let lngValue = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
            lng += Double(lngValue)
            
            coordinates.append(CLLocationCoordinate2D(latitude: lat * 1e-5, longitude: lng * 1e-5))
        }
        
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
}

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let routeOverlay: MKPolyline?
    let origin: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    let city: City
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        
        // Remove existing overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        // Add route overlay if available
        if let routeOverlay = routeOverlay {
            mapView.addOverlay(routeOverlay)
        }
        
        // Add origin and destination annotations
        let originAnnotation = MKPointAnnotation()
        originAnnotation.coordinate = origin
        originAnnotation.title = "Start"
        originAnnotation.subtitle = "Your location"
        
        let destinationAnnotation = MKPointAnnotation()
        destinationAnnotation.coordinate = destination
        destinationAnnotation.title = city.name
        destinationAnnotation.subtitle = city.country
        
        mapView.addAnnotations([originAnnotation, destinationAnnotation])
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !annotation.isKind(of: MKUserLocation.self) else { return nil }
            
            let identifier = "LocationPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            if let markerView = annotationView as? MKMarkerAnnotationView {
                markerView.markerTintColor = annotation.title == "Start" ? .blue : .red
            }
            
            return annotationView
        }
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
                if let instruction = step.navigationInstruction {
                    Text(instruction.instructions)
                        .font(.subheadline)
                } else {
                    Text("Continue")
                        .font(.subheadline)
                }
                
                Text("\(formatDistance(step.distanceMeters)) • \(formatDuration(step.staticDuration))")
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
    
    private func formatDuration(_ duration: String) -> String {
        // Parse the duration string (format: "1234s" or "1234")
        let seconds = Int(duration.replacingOccurrences(of: "s", with: "")) ?? 0
        
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        
        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, remainingSeconds)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, remainingSeconds)
        } else {
            return String(format: "%ds", remainingSeconds)
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
                imageURL: nil,
                facts: []
            )
        )
    }
} 