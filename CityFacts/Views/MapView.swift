import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject private var cityStore: CityStore
    @State private var selectedCity: City?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 180)
    )
    
    var body: some View {
        NavigationStack {
            Map(coordinateRegion: $region, annotationItems: cityStore.filteredCities) { city in
                MapAnnotation(coordinate: city.location) {
                    CityAnnotation(city: city, isSelected: city == selectedCity)
                        .onTapGesture {
                            withAnimation {
                                selectedCity = city
                            }
                        }
                }
            }
            .sheet(item: $selectedCity) { city in
                NavigationStack {
                    CityDetailView(city: city)
                }
                .presentationDragIndicator(.visible)
            }
            .navigationTitle("Map")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            withAnimation {
                                region = MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                    span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 180)
                                )
                            }
                        } label: {
                            Label("Show All", systemImage: "globe")
                        }
                        
                        if let city = selectedCity {
                            Button {
                                withAnimation {
                                    region = MKCoordinateRegion(
                                        center: city.location,
                                        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                                    )
                                }
                            } label: {
                                Label("Focus Selected", systemImage: "location")
                            }
                        }
                    } label: {
                        Image(systemName: "map")
                    }
                }
            }
        }
    }
}

struct CityAnnotation: View {
    let city: City
    let isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            Text(city.name)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorScheme == .dark ? .black : .white)
                        .shadow(radius: 2)
                }
            
            Image(systemName: "mappin.circle.fill")
                .font(.title)
                .foregroundStyle(isSelected ? .red : .blue)
        }
    }
}

#Preview {
    MapView()
        .environmentObject(CityStore())
} 