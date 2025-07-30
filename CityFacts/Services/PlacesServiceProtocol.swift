// MARK: - PlacesServiceProtocol
// Description: Protocol defining the interface for places data services (local and premium).
// Version: 0.0.1
// Modification Date: 2024-06-09
// Author: Cursor

import Foundation
import CoreLocation

protocol PlacesServiceProtocol: ObservableObject {
    var isLoading: Bool { get }
    var error: String? { get }
    
    func searchAttractions(near location: CLLocationCoordinate2D, radius: Double) async throws -> [Attraction]
    func searchHotels(near location: CLLocationCoordinate2D, radius: Double) async throws -> [Hotel]
    func getAttractions(for cityId: String) -> [Attraction]
    func getHotels(for cityId: String) -> [Hotel]
}

enum PlacesServiceType {
    case local
    case premium
}

class PlacesServiceFactory {
    static func createService(type: PlacesServiceType, apiKey: String? = nil) -> any PlacesServiceProtocol {
        print("🏭 PlacesServiceFactory creating service for type: \(type)")
        switch type {
        case .local:
            print("📁 Creating LocalDataService")
            return LocalDataService()
        case .premium:
            print("💰 Creating GooglePlacesService")
            return GooglePlacesService.shared
        }
    }
} 