// MARK: - LocalItineraryService
// Description: Service for generating travel itineraries using local data.
// Version: 0.0.1
// Modification Date: 2024-06-09
// Author: Cursor

import Foundation
import CoreLocation

class LocalItineraryService: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    
    private let localDataService: LocalDataService
    
    init(localDataService: LocalDataService) {
        self.localDataService = localDataService
    }
    
    // MARK: - Itinerary Generation
    
    func generateItinerary(for city: City, days: Int = 3) async -> LocalTripSchedule {
        isLoading = true
        error = nil
        
        print("🗺️ Generating itinerary for \(city.name) (\(days) days)")
        
        do {
            let attractions = localDataService.getAttractions(for: city.id.uuidString)
            let hotels = localDataService.getHotels(for: city.id.uuidString)
            let venues = localDataService.getVenues(for: city.id.uuidString)
            
            print("📊 Found \(attractions.count) attractions, \(hotels.count) hotels, \(venues.count) venues")
            
            let schedule = LocalTripSchedule(
                id: UUID(),
                city: city,
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date(),
                days: generateDays(for: city, attractions: attractions, hotels: hotels, venues: venues, days: days)
            )
            
            isLoading = false
            print("✅ Generated itinerary with \(schedule.days.count) days")
            return schedule
            
        } catch {
            self.error = "Failed to generate itinerary: \(error.localizedDescription)"
            isLoading = false
            print("❌ Error generating itinerary: \(error)")
            return LocalTripSchedule(id: UUID(), city: city, startDate: Date(), endDate: Date(), days: [])
        }
    }
    
    private func generateDays(for city: City, attractions: [Attraction], hotels: [Hotel], venues: [Venue], days: Int) -> [LocalTripDay] {
        var tripDays: [LocalTripDay] = []
        
        // Select a hotel for the trip
        let selectedHotel = hotels.first ?? Hotel(
            id: UUID(),
            name: "Default Hotel",
            description: "Comfortable accommodation",
            address: "City Center",
            rating: 4.0,
            imageURL: "",
            coordinates: CLLocationCoordinate2D(latitude: city.coordinates.latitude, longitude: city.coordinates.longitude),
            amenities: ["WiFi", "Breakfast"],
            websiteURL: nil,
            phoneNumber: nil,
            priceLevel: .moderate
        )
        
        // Distribute attractions and venues across days
        let allPlaces = attractions + venues.map { venue in
            Attraction(
                id: venue.id,
                name: venue.name,
                description: venue.description ?? "Interesting venue",
                address: venue.address ?? "City location",
                rating: venue.rating ?? 4.0,
                imageURL: venue.imageUrl ?? "https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=400&h=300&fit=crop",
                coordinates: CLLocationCoordinate2D(latitude: venue.latitude, longitude: venue.longitude),
                websiteURL: venue.website,
                priceLevel: .moderate,
                category: .entertainment,
                estimatedDuration: 120,
                tips: []
            )
        }
        
        print("🖼️ Using actual JSON images for \(allPlaces.count) places")
        for place in allPlaces.prefix(3) {
            print("   📸 \(place.name): \(place.imageURL)")
        }
        
        // Shuffle places for variety
        let shuffledPlaces = allPlaces.shuffled()
        
        for dayIndex in 0..<days {
            let dayNumber = dayIndex + 1
            let startTime = Calendar.current.date(byAdding: .day, value: dayIndex, to: Date()) ?? Date()
            
            // Select 3-4 places per day
            let placesPerDay = min(4, shuffledPlaces.count / days)
            let startIdx = dayIndex * placesPerDay
            let endIdx = min(startIdx + placesPerDay, shuffledPlaces.count)
            let dayPlaces = Array(shuffledPlaces[startIdx..<endIdx])
            
            let timeSlots = generateTimeSlots(for: dayPlaces, day: dayNumber)
            
            let tripDay = LocalTripDay(
                id: UUID(),
                dayNumber: dayNumber,
                date: startTime,
                timeSlots: timeSlots,
                hotel: selectedHotel
            )
            
            tripDays.append(tripDay)
        }
        
        return tripDays
    }
    
    private func generateTimeSlots(for places: [Attraction], day: Int) -> [LocalTimeSlot] {
        var timeSlots: [LocalTimeSlot] = []
        var currentTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        
        for (index, place) in places.enumerated() {
            let duration = place.estimatedDuration
            let endTime = Calendar.current.date(byAdding: .minute, value: Int(duration), to: currentTime) ?? currentTime
            
            let timeSlot = LocalTimeSlot(
                id: UUID(),
                startTime: currentTime,
                endTime: endTime,
                activity: place,
                location: place.coordinates,
                notes: generateNotes(for: place, day: day, slot: index + 1)
            )
            
            timeSlots.append(timeSlot)
            
            // Add travel time and break
            currentTime = Calendar.current.date(byAdding: .minute, value: 30, to: endTime) ?? endTime
        }
        
        return timeSlots
    }
    
    private func generateNotes(for place: Attraction, day: Int, slot: Int) -> String {
        let tips = [
            "Best time to visit: Morning",
            "Don't forget your camera",
            "Consider guided tours",
            "Check opening hours",
            "Bring comfortable shoes"
        ]
        
        return tips.randomElement() ?? "Enjoy your visit!"
    }
}

// MARK: - Supporting Models

struct LocalTripSchedule: Identifiable {
    let id: UUID
    let city: City
    let startDate: Date
    let endDate: Date
    let days: [LocalTripDay]
}

struct LocalTripDay: Identifiable {
    let id: UUID
    let dayNumber: Int
    let date: Date
    let timeSlots: [LocalTimeSlot]
    let hotel: Hotel
}

struct LocalTimeSlot: Identifiable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let activity: Attraction
    let location: CLLocationCoordinate2D
    let notes: String
} 