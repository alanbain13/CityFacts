import SwiftUI

@main
struct CityFactsApp: App {
    @StateObject private var cityStore = CityStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cityStore)
        }
    }
} 