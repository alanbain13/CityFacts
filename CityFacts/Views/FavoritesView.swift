import SwiftUI

// EmptyStateView displays a customizable empty state message with an icon.
// It is used to show when there is no content to display, such as no favorites or search results.
// The view includes a title, system image, and description text.
struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let description: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

// FavoritesView displays a list of cities marked as favorites by the user.
// Users can view their favorite cities and navigate to detailed city information.
// If there are no favorites, an empty state view is shown.
struct FavoritesView: View {
    @EnvironmentObject private var cityStore: CityStore
    
    var favoriteCities: [City] {
        cityStore.cities.filter { cityStore.isFavorite($0) }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if favoriteCities.isEmpty {
                    EmptyStateView(
                        title: "No Favorites",
                        systemImage: "star",
                        description: "Your favorite cities will appear here"
                    )
                } else {
                    List(favoriteCities) { city in
                        NavigationLink(destination: CityDetailView(city: city)) {
                            CityRowView(city: city)
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
        }
    }
}

#Preview {
    FavoritesView()
        .environmentObject(CityStore())
} 