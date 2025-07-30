// MARK: - CityBrowserView
// Description: View for browsing cities in alphabetical order with search functionality.
// Version: 0.0.1
// Modification Date: 2024-06-09
// Author: Cursor

import SwiftUI

struct CityBrowserView: View {
    @StateObject private var cityStore = CityStore(isPremiumUser: false)
    @State private var searchText = ""
    @State private var selectedCity: City?
    @State private var showingItinerary = false
    @State private var itineraryService: LocalItineraryService?
    @State private var currentItinerary: LocalTripSchedule?
    
    private var filteredCities: [City] {
        let sortedCities = cityStore.cities.sorted { $0.name < $1.name }
        
        if searchText.isEmpty {
            return sortedCities
        } else {
            return sortedCities.filter { city in
                city.name.localizedCaseInsensitiveContains(searchText) ||
                city.country.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search cities...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button("Clear") {
                            searchText = ""
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                // City List
                List {
                    ForEach(filteredCities) { city in
                        CityBrowserRowView(city: city) {
                            selectedCity = city
                            generateItinerary(for: city)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                // Summary
                VStack {
                    Text("Found \(filteredCities.count) cities")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !searchText.isEmpty {
                        Text("Filtered by: \"\(searchText)\"")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("Browse Cities")
            .sheet(isPresented: $showingItinerary) {
                if let itinerary = currentItinerary {
                    ItineraryDetailView(itinerary: itinerary)
                }
            }
        }
    }
    
    private func generateItinerary(for city: City) {
        guard let localService = cityStore.localDataService else {
            print("❌ LocalDataService not available")
            return
        }
        
        itineraryService = LocalItineraryService(localDataService: localService)
        
        Task {
            if let service = itineraryService {
                let itinerary = await service.generateItinerary(for: city, days: 3)
                
                await MainActor.run {
                    currentItinerary = itinerary
                    showingItinerary = true
                }
            }
        }
    }
}

struct CityBrowserRowView: View {
    let city: City
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(city.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(city.country)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if !city.description.isEmpty {
                        Text(city.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "arrow.right.circle")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    Text("Generate Itinerary")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ItineraryDetailView: View {
    let itinerary: LocalTripSchedule
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(itinerary.city.name) Itinerary")
                            .font(.title)
                            .bold()
                        
                        Text("\(itinerary.days.count) Days • \(formatDateRange())")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // Days
                    ForEach(itinerary.days) { day in
                        DayView(day: day)
                    }
                }
            }
            .navigationTitle("Itinerary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDateRange() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: itinerary.startDate)) - \(formatter.string(from: itinerary.endDate))"
    }
}

struct DayView: View {
    let day: LocalTripDay
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Day Header
            HStack {
                Text("Day \(day.dayNumber)")
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                Text(formatDate(day.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Time Slots
            ForEach(day.timeSlots) { slot in
                TimeSlotView(slot: slot)
            }
            
            // Hotel Info
            HotelInfoView(hotel: day.hotel)
        }
        .padding(.bottom)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct TimeSlotView: View {
    let slot: LocalTimeSlot
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formatTime(slot.startTime))
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("-")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatTime(slot.endTime))
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(slot.activity.name)
                    .font(.headline)
                
                Text(slot.activity.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !slot.notes.isEmpty {
                    Text(slot.notes)
                        .font(.caption)
                        .foregroundColor(.orange)
                        .italic()
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct HotelInfoView: View {
    let hotel: Hotel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bed.double")
                    .foregroundColor(.green)
                
                Text("Accommodation")
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(hotel.name)
                    .font(.subheadline)
                    .bold()
                
                Text(hotel.address ?? "Address not available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let rating = hotel.rating {
                    HStack {
                        ForEach(0..<Int(rating), id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

#Preview {
    CityBrowserView()
} 