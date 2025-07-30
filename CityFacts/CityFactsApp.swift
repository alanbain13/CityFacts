import SwiftUI

@main
struct CityFactsApp: App {
    init() {
        print("🚀 CityFactsApp starting up!")
    }
    
    @StateObject private var cityStore = CityStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cityStore)
        }
    }
} 