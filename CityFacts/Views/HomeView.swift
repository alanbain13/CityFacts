import SwiftUI

// HomeView serves as the main landing page of the app.
// It displays featured cities, recent searches, and quick access to travel planning tools.
// Users can navigate to other views like CitiesListView, TravelPlannerView, or FavoritesView.
struct HomeView: View {
    @State private var selectedTab = 0
    @State private var isAnimating = false
    @State private var showingCitySearch = false
    @State private var selectedCity: City?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background image
                AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1449824913935-59a10b8d2000?q=80&w=1920&auto=format&fit=crop")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                        .overlay {
                            LinearGradient(
                                colors: [
                                    .black.opacity(0.5),
                                    .black.opacity(0.2),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                } placeholder: {
                    Color.black
                }
                
                // Animated background elements
                GeometryReader { geometry in
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(.white.opacity(0.1))
                            .frame(width: 100, height: 100)
                            .blur(radius: 20)
                            .offset(x: isAnimating ? geometry.size.width * 0.8 : -100,
                                   y: isAnimating ? geometry.size.height * 0.6 : 100)
                            .animation(
                                Animation.easeInOut(duration: 3)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.5),
                                value: isAnimating
                            )
                    }
                }
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Title with animation
                    VStack(spacing: 8) {
                        Text("City Facts")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                            .scaleEffect(isAnimating ? 1.05 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 2)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                        
                        Text("Discover the world's most fascinating cities")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    
                    // Navigation buttons
                    VStack(spacing: 16) {
                        NavigationLink {
                            CitiesListView()
                        } label: {
                            NavigationButton(
                                title: "Browse Cities",
                                systemImage: "building.2.fill",
                                color: .blue
                            )
                        }
                        
                        Button {
                            showingCitySearch = true
                        } label: {
                            NavigationButton(
                                title: "Search Any City",
                                systemImage: "magnifyingglass",
                                color: .purple
                            )
                        }
                        
                        NavigationLink {
                            TravelPlannerView()
                        } label: {
                            NavigationButton(
                                title: "Plan Your Trip",
                                systemImage: "airplane",
                                color: .green
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Stats section
                    HStack(spacing: 30) {
                        StatView(number: "50+", label: "Cities")
                        StatView(number: "100+", label: "Landmarks")
                        StatView(number: "24/7", label: "Updates")
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                isAnimating = true
            }
            .sheet(isPresented: $showingCitySearch) {
                CitySearchView(selectedCity: $selectedCity)
            }
        }
    }
}

struct NavigationButton: View {
    let title: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .font(.title2)
            Text(title)
                .font(.headline)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// StatView displays a single statistic with a number and label.
// It uses a frosted glass effect background and is designed for displaying app statistics.
// The view is commonly used in the home screen to show key metrics.
struct StatView: View {
    let number: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(number)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HomeView()
} 