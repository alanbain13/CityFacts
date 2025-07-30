import SwiftUI

// ContentView is the main entry point of the app.
// It provides navigation to browse cities and plan travel, and displays a welcoming background.
// The view sets up the main navigation structure and environment objects.
struct ContentView: View {
    @StateObject private var cityStore = CityStore(isPremiumUser: false)
    @State private var showingCitiesList = false
    @State private var showingMap = false
    
    init() {
        print("📱 ContentView initialized")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background image
                AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1513635269975-59663e0ac1ad")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                        .overlay {
                            // Dark overlay for better text visibility
                            Color.black.opacity(0.3)
                        }
                } placeholder: {
                    Color.gray
                }
                
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 60)
                    
                                                VStack(spacing: 8) {
                                Text("City Facts")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                                    .onAppear {
                                        print("🎯 City Facts title appeared!")
                                    }
                        
                        Text("Discover amazing cities around the world")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        // Service Mode Indicator
                        HStack {
                            Text("Mode:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(cityStore.isPremiumUser ? "Premium" : "Local")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(cityStore.isPremiumUser ? .yellow : .green)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        NavigationLink(destination: CitiesListView()) {
                            HStack {
                                Image(systemName: "building.2")
                                    .font(.title2)
                                Text("Browse Cities")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                                                            NavigationLink(destination: TravelPlannerView()) {
                                        HStack {
                                            Image(systemName: "airplane")
                                                .font(.title2)
                                            Text("Travel Planning")
                                                .font(.headline)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                    }
                        
                        NavigationLink(destination: LocalDataTestView()) {
                            HStack {
                                Image(systemName: "database")
                                    .font(.title2)
                                Text("Test Local Data")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        NavigationLink(destination: JSONTestView()) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .font(.title2)
                                Text("Test JSON Files")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .environmentObject(cityStore)
    }
}

#Preview {
    ContentView()
} 