import SwiftUI

@main
struct CityFactsApp: App {
    @StateObject private var cityStore = CityStore()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(cityStore)
        }
    }
} 