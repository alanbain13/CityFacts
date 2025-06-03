import SwiftUI
import MapKit

// CityDetailView displays detailed information about a selected city.
// It shows the city's name, country, population, description, and a list of landmarks.
// Users can view images of the city and access additional facts.
struct CityDetailView: View {
    let city: City
    @EnvironmentObject private var cityStore: CityStore
    @State private var selectedTab = 0
    @State private var region: MKCoordinateRegion
    @State private var showingMap = false
    @State private var showingRoute = false
    @State private var userLocation: CLLocationCoordinate2D?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    init(city: City) {
        self.city = city
        _region = State(initialValue: MKCoordinateRegion(
            center: city.location,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ))
    }
    
    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                ScrollView {
                    VStack(spacing: 20) {
                        imageGallery
                        
                        VStack(spacing: 16) {
                            infoSection
                            factsSection
                            landmarksSection
                        }
                        .padding()
                        
                        // Add Route Button
                        Button(action: {
                            showingRoute = true
                        }) {
                            HStack {
                                Image(systemName: "map.fill")
                                Text("Show Route")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .disabled(userLocation == nil)
                        .opacity(userLocation == nil ? 0.6 : 1)
                    }
                }
            } else {
                HStack {
                    ScrollView {
                        VStack(spacing: 16) {
                            infoSection
                            factsSection
                            landmarksSection
                        }
                        .padding()
                    }
                    .frame(width: 400)
                    
                    TabView(selection: $selectedTab) {
                        imageGallery
                            .tag(0)
                        
                        Map(coordinateRegion: $region, annotationItems: [city]) { city in
                            MapMarker(coordinate: city.location)
                        }
                        .tag(1)
                    }
                    .tabViewStyle(.page)
                }
            }
        }
        .navigationTitle(city.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingMap = true
                } label: {
                    Image(systemName: "map")
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    cityStore.toggleFavorite(for: city)
                } label: {
                    Image(systemName: cityStore.isFavorite(city) ? "star.fill" : "star")
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: "Check out \(city.name)!", subject: Text("City Facts: \(city.name)"))
            }
        }
        .sheet(isPresented: $showingMap) {
            NavigationStack {
                Map(coordinateRegion: $region, annotationItems: [city]) { city in
                    MapMarker(coordinate: city.location)
                }
                .edgesIgnoringSafeArea(.all)
                .navigationTitle("\(city.name) Map")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            showingMap = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingRoute) {
            if let userLocation = userLocation {
                NavigationView {
                    RouteView(
                        origin: userLocation,
                        destination: CLLocationCoordinate2D(
                            latitude: city.coordinates.latitude,
                            longitude: city.coordinates.longitude
                        ),
                        city: city
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
    
    private var imageGallery: some View {
        TabView {
            ForEach(city.imageURLs, id: \.self) { url in
                AsyncImage(url: URL(string: url)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
            }
        }
        .tabViewStyle(.page)
        .frame(height: 300)
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Information")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "Country", value: city.country)
                InfoRow(label: "Continent", value: city.continent.rawValue)
                InfoRow(label: "Population", value: city.population.formatted())
                InfoRow(label: "Time Zone", value: city.timezone)
            }
            
            Text(city.description)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var factsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Interesting Facts")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(city.facts, id: \.self) { fact in
                    HStack(alignment: .top) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .padding(.top, 6)
                        
                        Text(fact)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var landmarksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Famous Landmarks")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                ForEach(city.landmarks) { landmark in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(landmark.name)
                            .font(.headline)
                        Text(landmark.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationStack {
        CityDetailView(city: .preview)
            .environmentObject(CityStore())
    }
} 