import Foundation

enum GooglePlacesConfig {
    // Replace this with your actual Google Places API key
    static let apiKey = "AIzaSyAv1bAb_cMz8JAxhWsnedOPv3dBq7N7M3o"
    
    // Base URL for Google Places API (New)
    static let baseURL = "https://places.googleapis.com/v1"
    
    // Endpoints
    static let searchEndpoint = "/places:searchText"
    static let detailsEndpoint = "/places"
    static let nearbyEndpoint = "/places:searchNearby"
    
    // Helper function to build URLs with API key
    static func buildURL(endpoint: String, parameters: [String: String] = [:]) -> URL? {
        let urlString = baseURL + endpoint
        guard let url = URL(string: urlString) else {
            print("❌ Failed to create URL from string: \(urlString)")
            return nil
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let finalURL = components?.url else {
            print("❌ Failed to create final URL with components")
            return nil
        }
        
        print("✅ Built URL: \(finalURL.absoluteString)")
        return finalURL
    }
    
    // Common headers for Places API requests
    static let commonHeaders: [String: String] = [
        "Content-Type": "application/json",
        "X-Goog-Api-Key": apiKey,
        "X-Goog-FieldMask": "places.id,places.displayName,places.formattedAddress,places.location,places.types,places.photos.name,places.photos.uri,places.photos.widthPx,places.photos.heightPx,places.primaryType,places.primaryTypeDisplayName"
    ]
    
    // Helper function to build photo URL
    static func buildPhotoURL(photoReference: String, maxWidth: Int = 800) -> URL? {
        let baseURL = "https://maps.googleapis.com/maps/api/place/photo"
        guard let url = URL(string: baseURL) else {
            print("❌ Failed to create base URL for photo")
            return nil
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.queryItems = [
            URLQueryItem(name: "photo_reference", value: photoReference),
            URLQueryItem(name: "maxwidth", value: String(maxWidth)),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let finalURL = components?.url else {
            print("❌ Failed to create final URL for photo")
            return nil
        }
        
        print("✅ Built photo URL: \(finalURL.absoluteString)")
        return finalURL
    }
} 
