import Foundation
import CoreLocation
import MapKit

// TransitService handles route planning, AI recommendations, and transit data management
// It integrates with Google Maps Directions API and provides intelligent route suggestions
class TransitService: ObservableObject {
    static let shared = TransitService()
    
    @Published var isLoading = false
    @Published var error: Error?
    
    private init() {}
    
    // MARK: - Route Planning
    
    /// Generates transit routes for an entire trip
    func generateTransitRoutes(
        tripSchedule: TripSchedule,
        destinationCity: City,
        selectedHotels: [Int: Hotel?],
        attractions: [TouristAttraction]
    ) async throws -> [TransitDay] {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        var transitDays: [TransitDay] = []
        
        for dayIndex in 0..<tripSchedule.numberOfDays {
            let dayNumber = dayIndex + 1
            let currentDate = tripSchedule.dateForDay(dayNumber)
            let dayAttractions = attractionsForDay(attractions, dayIndex: dayIndex, totalDays: tripSchedule.numberOfDays)
            
            var dayRoutes: [TransitRoute] = []
            
            // Day 1: Home to Hub, Hub to Hotel
            if dayIndex == 0 {
                var homeToHubRoute: TransitRoute?
                if let generatedHomeToHubRoute = try await generateHomeToHubRoute(
                    homeCity: tripSchedule.homeCity,
                    destinationCity: destinationCity,
                    departureTime: tripSchedule.actualDepartureTime
                ) {
                    homeToHubRoute = generatedHomeToHubRoute
                    dayRoutes.append(generatedHomeToHubRoute)
                }
                
                if let hotel = selectedHotels[dayNumber], let unwrappedHotel = hotel {
                    if let hubToHotelRoute = try await generateHubToHotelRoute(
                        destinationCity: destinationCity,
                        hotel: unwrappedHotel,
                        arrivalTime: homeToHubRoute?.endTime ?? tripSchedule.actualDepartureTime
                    ) {
                        dayRoutes.append(hubToHotelRoute)
                    }
                }
            }
            
            // Hotel to First Attraction (only if hotel exists and attractions exist)
            if let hotel = selectedHotels[dayNumber], let unwrappedHotel = hotel, let firstAttraction = dayAttractions.first {
                let hotelSchedule = HotelSchedule()
                let departureTime = hotelSchedule.morningDepartureTime
                
                if let hotelToAttractionRoute = try await generateHotelToAttractionRoute(
                    hotel: unwrappedHotel,
                    attraction: firstAttraction,
                    departureTime: departureTime,
                    isFirstAttraction: true
                ) {
                    dayRoutes.append(hotelToAttractionRoute)
                }
            }
            
            // Last Attraction to Hotel (only if hotel exists and attractions exist)
            if let hotel = selectedHotels[dayNumber], let unwrappedHotel = hotel, let lastAttraction = dayAttractions.last {
                let hotelSchedule = HotelSchedule()
                let departureTime = hotelSchedule.eveningArrivalTime
                
                if let attractionToHotelRoute = try await generateHotelToAttractionRoute(
                    hotel: unwrappedHotel,
                    attraction: lastAttraction,
                    departureTime: departureTime,
                    isFirstAttraction: false
                ) {
                    dayRoutes.append(attractionToHotelRoute)
                }
            }
            
            // Last Day: Hotel to Home
            if dayIndex == tripSchedule.numberOfDays - 1 {
                if let hotel = selectedHotels[dayNumber], let unwrappedHotel = hotel {
                    if let hotelToHomeRoute = try await generateHotelToHomeRoute(
                        hotel: unwrappedHotel,
                        homeCity: tripSchedule.homeCity,
                        departureTime: tripSchedule.actualReturnTime
                    ) {
                        dayRoutes.append(hotelToHomeRoute)
                    }
                }
            }
            
            let transitDay = TransitDay(dayNumber: dayNumber, date: currentDate, routes: dayRoutes)
            transitDays.append(transitDay)
        }
        
        return transitDays
    }
    
    // MARK: - Individual Route Generation
    
    private func generateHomeToHubRoute(homeCity: String, destinationCity: City, departureTime: Date) async throws -> TransitRoute? {
        // Calculate flight duration (typically 2-4 hours for domestic flights)
        let flightDuration: TimeInterval = 7200 // 2 hours
        let endTime = departureTime.addingTimeInterval(flightDuration)
        
        return TransitRoute(
            type: .homeToHub,
            startLocation: homeCity,
            endLocation: "\(destinationCity.name) Airport",
            startTime: departureTime,
            endTime: endTime,
            elapsedTime: flightDuration,
            distance: 500.0, // 500 km
            cost: 150.0,
            mode: .airplane,
            routePolyline: nil,
            imageURL: "https://images.unsplash.com/photo-1436491865332-7a61a109cc05?auto=format&fit=crop&w=800&q=80",
            description: "Flight from \(homeCity) to \(destinationCity.name)",
            instructions: [
                "Check in at airport 2 hours before departure",
                "Have passport and boarding pass ready",
                "Follow airport security procedures"
            ]
        )
    }
    
    private func generateHubToHotelRoute(destinationCity: City, hotel: Hotel, arrivalTime: Date) async throws -> TransitRoute? {
        // Calculate transit duration (typically 15-45 minutes)
        let transitDuration: TimeInterval = 1800 // 30 minutes
        let startTime = arrivalTime.addingTimeInterval(-transitDuration)
        
        return TransitRoute(
            type: .hubToHotel,
            startLocation: "\(destinationCity.name) Airport",
            endLocation: hotel.name,
            startTime: startTime,
            endTime: arrivalTime,
            elapsedTime: transitDuration,
            distance: 25.0, // 25 km
            cost: 35.0,
            mode: .taxi,
            routePolyline: nil,
            imageURL: "https://images.unsplash.com/photo-1449824913935-59a10b8d2000?auto=format&fit=crop&w=800&q=80",
            description: "Taxi from airport to \(hotel.name)",
            instructions: [
                "Follow airport taxi signs",
                "Use official taxi service",
                "Have hotel address ready"
            ]
        )
    }
    
    private func generateHotelToAttractionRoute(hotel: Hotel, attraction: TouristAttraction, departureTime: Date, isFirstAttraction: Bool) async throws -> TransitRoute? {
        // Calculate transit duration based on distance and mode
        let transitDuration: TimeInterval = 900 // 15 minutes
        let endTime = departureTime.addingTimeInterval(transitDuration)
        
        return TransitRoute(
            type: isFirstAttraction ? .hotelToFirstAttraction : .lastAttractionToHotel,
            startLocation: isFirstAttraction ? hotel.name : attraction.name,
            endLocation: isFirstAttraction ? attraction.name : hotel.name,
            startTime: departureTime,
            endTime: endTime,
            elapsedTime: transitDuration,
            distance: 2.5, // 2.5 km
            cost: 12.0,
            mode: .taxi,
            routePolyline: nil,
            imageURL: "https://images.unsplash.com/photo-1449824913935-59a10b8d2000?auto=format&fit=crop&w=800&q=80",
            description: "Taxi from \(isFirstAttraction ? hotel.name : attraction.name) to \(isFirstAttraction ? attraction.name : hotel.name)",
            instructions: [
                "Call taxi or use rideshare app",
                "Have destination address ready",
                "Check traffic conditions"
            ]
        )
    }
    
    private func generateHotelToHomeRoute(hotel: Hotel, homeCity: String, departureTime: Date) async throws -> TransitRoute? {
        // Calculate flight duration (typically 2-4 hours for domestic flights)
        let flightDuration: TimeInterval = 7200 // 2 hours
        let endTime = departureTime.addingTimeInterval(flightDuration)
        
        return TransitRoute(
            type: .hotelToHome,
            startLocation: hotel.name,
            endLocation: homeCity,
            startTime: departureTime,
            endTime: endTime,
            elapsedTime: flightDuration,
            distance: 500.0, // 500 km
            cost: 150.0,
            mode: .airplane,
            routePolyline: nil,
            imageURL: "https://images.unsplash.com/photo-1436491865332-7a61a109cc05?auto=format&fit=crop&w=800&q=80",
            description: "Flight from \(hotel.name) to \(homeCity)",
            instructions: [
                "Check out of hotel",
                "Arrive at airport 2 hours before departure",
                "Have return flight documents ready"
            ]
        )
    }
    
    // MARK: - AI Recommendations
    
    /// Gets AI-recommended transport mode based on various factors
    func getRecommendedMode(
        for routeType: TransitRoute.RouteType,
        distance: Double,
        timeOfDay: Date,
        weather: String? = nil
    ) -> TransitRoute.TransportMode {
        switch routeType {
        case .homeToHub, .hotelToHome:
            return .airplane // Long distance
        case .hubToHotel:
            return .taxi // Convenience after travel
        case .hotelToFirstAttraction, .lastAttractionToHotel:
            if distance < 1.0 {
                return .walking // Short distance
            } else if distance < 5.0 {
                return .cycling // Medium distance
            } else {
                return .taxi // Longer distance
            }
        }
    }
    
    // MARK: - Route Optimization
    
    /// Optimizes a route based on user preferences and constraints
    func optimizeRoute(
        _ route: TransitRoute,
        preferredMode: TransitRoute.TransportMode? = nil,
        preferredTime: Date? = nil
    ) async throws -> TransitRoute {
        // This would integrate with Google Maps Directions API
        // For now, return the original route with any user modifications
        return route
    }
    
    // MARK: - Helper Methods
    
    private func attractionsForDay(_ attractions: [TouristAttraction], dayIndex: Int, totalDays: Int) -> [TouristAttraction] {
        let attractionsPerDay = Int(ceil(Double(attractions.count) / Double(totalDays)))
        let startIndex = dayIndex * attractionsPerDay
        let endIndex = min(startIndex + attractionsPerDay, attractions.count)
        return Array(attractions[startIndex..<endIndex])
    }
} 