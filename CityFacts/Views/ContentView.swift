import SwiftUI

struct ContentView: View {
    @StateObject private var cityStore = CityStore()
    @State private var showingCitiesList = false
    @State private var showingMap = false
    
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
                        
                        Text("Discover amazing cities around the world")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
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