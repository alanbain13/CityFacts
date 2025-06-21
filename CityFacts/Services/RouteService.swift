import Foundation
import CoreLocation

class RouteService {
    static let shared = RouteService()
    
    private init() {}
    
    // Add enum for travel modes
    enum TravelMode: String, Codable {
        case driving = "DRIVE"
        case walking = "WALK"
        case bicycling = "BICYCLE"
        case transit = "TRANSIT"
    }
    
    struct RouteResponse: Codable {
        let routes: [Route]
    }
    
    struct Route: Codable {
        let distanceMeters: Int
        let duration: String
        let polyline: Polyline
        let legs: [Leg]
    }
    
    struct Polyline: Codable {
        let encodedPolyline: String
    }
    
    struct Leg: Codable {
        let distanceMeters: Int
        let duration: String
        let startLocation: RouteLocation
        let endLocation: RouteLocation
        let steps: [Step]
    }
    
    struct RouteLocation: Codable {
        let latLng: LatLng
    }
    
    struct LatLng: Codable {
        let latitude: Double
        let longitude: Double
    }
    
    struct Step: Codable {
        let distanceMeters: Int
        let staticDuration: String
        let navigationInstruction: NavigationInstruction?
        let polyline: Polyline
    }
    
    struct NavigationInstruction: Codable {
        let maneuver: String
        let instructions: String
    }
    
    func getRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, travelMode: TravelMode = .driving) async throws -> Route {
        print("\n=== Getting Route ===")
        print("From: \(origin.latitude), \(origin.longitude)")
        print("To: \(destination.latitude), \(destination.longitude)")
        print("Travel Mode: \(travelMode.rawValue)")
        
        // Use the Routes API base URL
        let baseURL = "https://routes.googleapis.com/directions/v2:computeRoutes"
        guard var urlComponents = URLComponents(string: baseURL) else {
            print("❌ Failed to create URL components for endpoint: \(baseURL)")
            throw NetworkError.invalidURL
        }
        
        // Add the API key as a query parameter
        urlComponents.queryItems = [
            URLQueryItem(name: "key", value: GooglePlacesConfig.apiKey)
        ]
        
        guard let url = urlComponents.url else {
            print("❌ Failed to create URL from components")
            throw NetworkError.invalidURL
        }
        
        // Create request body
        var requestBody: [String: Any] = [
            "origin": [
                "location": [
                    "latLng": [
                        "latitude": origin.latitude,
                        "longitude": origin.longitude
                    ]
                ]
            ],
            "destination": [
                "location": [
                    "latLng": [
                        "latitude": destination.latitude,
                        "longitude": destination.longitude
                    ]
                ]
            ],
            "travelMode": travelMode.rawValue,
            "computeAlternativeRoutes": false,
            "routeModifiers": [
                "avoidTolls": false,
                "avoidHighways": false
            ],
            "languageCode": "en-US",
            "units": "METRIC"
        ]
        
        // Only add routingPreference for driving mode
        if travelMode == .driving {
            requestBody["routingPreference"] = "TRAFFIC_AWARE"
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(GooglePlacesConfig.apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline,routes.legs.distanceMeters,routes.legs.duration,routes.legs.startLocation,routes.legs.endLocation,routes.legs.steps.distanceMeters,routes.legs.steps.staticDuration,routes.legs.steps.polyline", forHTTPHeaderField: "X-Goog-FieldMask")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("❌ Failed to serialize request body: \(error)")
            throw NetworkError.apiError(message: "Failed to serialize request: \(error.localizedDescription)")
        }
        
        print("\n=== Making API Request ===")
        print("URL: \(url)")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let httpBody = request.httpBody {
            print("Body: \(String(decoding: httpBody, as: UTF8.self))")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("\n=== API Response ===")
                print("Status Code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    print("❌ API Error: HTTP \(httpResponse.statusCode)")
                    let errorString = String(decoding: data, as: UTF8.self)
                    print("Error details: \(errorString)")
                    throw NetworkError.apiError(message: "HTTP \(httpResponse.statusCode): \(errorString)")
                }
            }
            
            let decoder = JSONDecoder()
            let routeResponse = try decoder.decode(RouteResponse.self, from: data)
            
            guard let route = routeResponse.routes.first else {
                throw NetworkError.apiError(message: "No route found")
            }
            
            print("Successfully decoded route")
            print("Distance: \(route.distanceMeters) meters")
            print("Duration: \(route.duration)")
            
            return route
        } catch {
            print("❌ Error getting route: \(error)")
            throw error
        }
    }
} 