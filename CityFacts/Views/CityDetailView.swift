import SwiftUI
import MapKit

struct CityDetailView: View {
    let city: City
    @EnvironmentObject private var cityStore: CityStore
    @State private var selectedTab = 0
    @State private var region: MKCoordinateRegion
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
                    cityStore.toggleFavorite(for: city)
                } label: {
                    Image(systemName: cityStore.isFavorite(city) ? "star.fill" : "star")
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: "Check out \(city.name)!", subject: Text("City Facts: \(city.name)"))
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