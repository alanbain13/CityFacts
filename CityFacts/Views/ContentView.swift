import SwiftUI

struct ContentView: View {
    @StateObject private var cityStore = CityStore()
    
    var body: some View {
        TabView {
            CitiesListView()
                .tabItem {
                    Label("Cities", systemImage: "building.2")
                }
            
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "star.fill")
                }
            
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
        }
        .overlay {
            if cityStore.isLoading {
                ProgressView("Loading cities...")
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(8)
            }
        }
        .environmentObject(cityStore)
    }
}

#Preview {
    ContentView()
} 