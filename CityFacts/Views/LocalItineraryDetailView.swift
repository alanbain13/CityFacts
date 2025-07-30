// MARK: - LocalItineraryDetailView
// Description: View for displaying local itinerary details with the same UI as premium version.
// Version: 0.0.1
// Modification Date: 2024-06-09
// Author: Cursor

import SwiftUI

struct LocalItineraryDetailView: View {
    let itinerary: LocalTripSchedule
    @Environment(\.dismiss) private var dismiss
    
        var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // City Header with Image
                    VStack(alignment: .leading, spacing: 12) {
                        // City Image - Use JSON image_url or fallback to hardcoded
                        AsyncImage(url: URL(string: getCityImageURL(for: itinerary.city))) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                                .clipped()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(1.5)
                                )
                        }
                        .cornerRadius(12)
                        .onAppear {
                            print("🏙️ Loading city image for \(itinerary.city.name): \(getCityImageURL(for: itinerary.city))")
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(itinerary.city.name) Itinerary")
                                .font(.title)
                                .bold()
                            
                            Text("\(itinerary.days.count) Days • \(formatDateRange())")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.red)
                                Text(itinerary.city.country)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }
                    
                    // Days
                    ForEach(itinerary.days) { day in
                        LocalDayView(day: day)
                    }
                }
                .padding(.horizontal, 20)
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
    
    private func formatDateRange() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: itinerary.startDate)) - \(formatter.string(from: itinerary.endDate))"
    }
    
    private func getCityImageURL(for city: City) -> String {
        // First try to use the JSON image_url if available
        if let imageURL = city.imageURL, !imageURL.isEmpty {
            return imageURL
        }
        
        // Fallback to hardcoded URLs if JSON image_url is null or empty
        switch city.name.lowercased() {
        case "london":
            return "https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/London_Bridge_from_Butler%27s_Wharf%2C_London_UK_-_Diliff.jpg/1200px-London_Bridge_from_Butler%27s_Wharf%2C_London_UK_-_Diliff.jpg"
        case "paris":
            return "https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/Tour_Eiffel_Wikimedia_Commons.jpg/1200px-Tour_Eiffel_Wikimedia_Commons.jpg"
        case "new york":
            return "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7a/View_of_Empire_State_Building_from_Rockefeller_Center_New_York_City_dllu.jpg/1200px-View_of_Empire_State_Building_from_Rockefeller_Center_New_York_City_dllu.jpg"
        case "tokyo":
            return "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b2/Skyscrapers_of_Shinjuku_2009-01.jpg/1200px-Skyscrapers_of_Shinjuku_2009-01.jpg"
        case "sydney":
            return "https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Sydney_Opera_House_and_Harbour_Bridge_Dusk_%282%29_%2836959380763%29.jpg/1200px-Sydney_Opera_House_and_Harbour_Bridge_Dusk_%282%29_%2836959380763%29.jpg"
        case "rome":
            return "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7e/Trevi_Fountain%2C_Rome%2C_Italy_2_-_May_2007.jpg/1200px-Trevi_Fountain%2C_Rome%2C_Italy_2_-_May_2007.jpg"
        case "barcelona":
            return "https://upload.wikimedia.org/wikipedia/commons/thumb/9/9d/Sagrada_Familia_08.jpg/1200px-Sagrada_Familia_08.jpg"
        case "amsterdam":
            return "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Amsterdam_-_Rijksmuseum_-_1909.jpg/1200px-Amsterdam_-_Rijksmuseum_-_1909.jpg"
        case "berlin":
            return "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/Brandenburger_Tor_abends.jpg/1200px-Brandenburger_Tor_abends.jpg"
        case "prague":
            return "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5d/Prague_Castle_from_Charles_Bridge.jpg/1200px-Prague_Castle_from_Charles_Bridge.jpg"
        default:
            return "https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/London_Bridge_from_Butler%27s_Wharf%2C_London_UK_-_Diliff.jpg/1200px-London_Bridge_from_Butler%27s_Wharf%2C_London_UK_-_Diliff.jpg"
        }
    }
    

}

struct LocalDayView: View {
    let day: LocalTripDay
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
            
            // Time Slots
            VStack(spacing: 12) {
                ForEach(day.timeSlots) { slot in
                    LocalTimeSlotView(slot: slot)
                }
            }
            
            // Hotel Info
            LocalHotelInfoView(hotel: day.hotel)
        }
        .padding(.bottom, 24)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct LocalTimeSlotView: View {
    let slot: LocalTimeSlot
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            HStack(spacing: 16) {
                // Large Activity Image (more prominent)
                AsyncImage(url: URL(string: slot.activity.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                                .font(.title2)
                        )
                }
                .cornerRadius(12)
                .onAppear {
                    print("🖼️ Loading image for \(slot.activity.name): \(slot.activity.imageURL)")
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // Title and Time
                    HStack(alignment: .top, spacing: 8) {
                        Text(slot.activity.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatTime(slot.startTime))
                                .font(.caption)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            
                            Text(formatTime(slot.endTime))
                                .font(.caption)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                        .frame(minWidth: 50)
                    }
                    
                    // Description
                    Text(slot.activity.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    // Rating and Tips
                    VStack(alignment: .leading, spacing: 4) {
                        if slot.activity.rating > 0 {
                            HStack(spacing: 4) {
                                ForEach(0..<min(Int(slot.activity.rating), 5), id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption2)
                                }
                                Text("\(slot.activity.rating, specifier: "%.1f")")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        if !slot.notes.isEmpty {
                            Text(slot.notes)
                                .font(.caption)
                                .foregroundColor(.orange)
                                .italic()
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            LocalAttractionDetailView(attraction: slot.activity)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct LocalHotelInfoView: View {
    let hotel: Hotel
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            HStack(spacing: 16) {
                // Large Hotel Image (more prominent)
                AsyncImage(url: URL(string: hotel.imageURL ?? "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&h=300&fit=crop")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "bed.double")
                                .foregroundColor(.gray)
                                .font(.title2)
                        )
                }
                .cornerRadius(12)
                .onAppear {
                    print("🏨 Loading image for \(hotel.name): \(hotel.imageURL ?? "No image")")
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // Title and Rating
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(hotel.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .truncationMode(.tail)
                            
                            Text(hotel.address ?? "Address not available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if let rating = hotel.rating {
                            VStack(alignment: .trailing, spacing: 2) {
                                HStack(spacing: 2) {
                                    ForEach(0..<min(Int(rating), 5), id: \.self) { _ in
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                            .font(.caption2)
                                    }
                                }
                                Text("\(rating, specifier: "%.1f")")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.medium)
                            }
                            .frame(minWidth: 50)
                        }
                    }
                    
                    // Amenities
                    if !hotel.amenities.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(hotel.amenities.prefix(3), id: \.self) { amenity in
                                Text(amenity)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.1))
                                    .foregroundColor(.green)
                                    .cornerRadius(4)
                            }
                            
                            if hotel.amenities.count > 3 {
                                Text("+\(hotel.amenities.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.green.opacity(0.05))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            LocalHotelDetailView(hotel: hotel)
        }
    }
}

#Preview {
    LocalItineraryDetailView(itinerary: LocalTripSchedule(
        id: UUID(),
        city: City(
            id: UUID(),
            name: "London",
            country: "UK",
            continent: .europe,
            population: 8900000,
            description: "Capital of England",
            landmarks: [],
            coordinates: City.Coordinates(latitude: 51.5074, longitude: -0.1278),
            timezone: "UTC",
            imageURL: nil,
            facts: []
        ),
        startDate: Date(),
        endDate: Date(),
        days: []
    ))
} 