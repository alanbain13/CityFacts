// MARK: - LocalAttractionDetailView
// Description: Detailed view for attractions with rich UI including images and information.
// Version: 0.0.1
// Modification Date: 2024-06-09
// Author: Cursor

import SwiftUI
import MapKit

struct LocalAttractionDetailView: View {
    let attraction: Attraction
    @Environment(\.dismiss) private var dismiss
    @State private var region: MKCoordinateRegion
    
    init(attraction: Attraction) {
        self.attraction = attraction
        self._region = State(initialValue: MKCoordinateRegion(
            center: attraction.coordinates,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Hero Image
                    AsyncImage(url: URL(string: attraction.imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 250)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(1.5)
                            )
                    }
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Title and Rating
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(attraction.name)
                                    .font(.title2)
                                    .bold()
                                
                                Text(attraction.category.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            Spacer()
                            
                            if attraction.rating > 0 {
                                VStack(alignment: .trailing, spacing: 4) {
                                    HStack {
                                        ForEach(0..<min(Int(attraction.rating), 5), id: \.self) { _ in
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                                .font(.caption)
                                        }
                                    }
                                    Text("\(attraction.rating, specifier: "%.1f")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        // Description
                        Text(attraction.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        // Details
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(icon: "mappin.circle.fill", title: "Address", value: attraction.address)
                            
                            DetailRow(icon: "clock.fill", title: "Duration", value: "\(attraction.estimatedDuration / 60) hours")
                            
                            DetailRow(icon: "dollarsign.circle.fill", title: "Price Level", value: attraction.priceLevel.rawValue.capitalized)
                            
                            if let website = attraction.websiteURL {
                                DetailRow(icon: "globe", title: "Website", value: website)
                            }
                        }
                        
                        // Tips
                        if !attraction.tips.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tips")
                                    .font(.headline)
                                
                                ForEach(attraction.tips, id: \.self) { tip in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "lightbulb.fill")
                                            .foregroundColor(.yellow)
                                            .font(.caption)
                                        
                                        Text(tip)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        
                        // Map
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location")
                                .font(.headline)
                            
                            Map(coordinateRegion: $region, annotationItems: [attraction]) { attraction in
                                MapMarker(coordinate: attraction.coordinates, tint: .red)
                            }
                            .frame(height: 200)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Attraction Details")
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
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
            }
            
            Spacer()
        }
    }
}

#Preview {
    LocalAttractionDetailView(attraction: Attraction(
        id: "test",
        name: "Big Ben",
        description: "Iconic clock tower in London",
        address: "Westminster, London, UK",
        rating: 4.5,
        imageURL: "https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=400&h=300&fit=crop",
        coordinates: CLLocationCoordinate2D(latitude: 51.4994, longitude: -0.1245),
        websiteURL: "https://example.com",
        priceLevel: .moderate,
        category: .historical,
        estimatedDuration: 120,
        tips: ["Visit early morning", "Book tickets in advance"]
    ))
} 