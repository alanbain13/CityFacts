import SwiftUI
import MapKit

// AttractionCard displays a card view for a single attraction.
// It shows the attraction's image, name, and a brief description.
// Users can tap the card to view detailed information about the attraction.
struct AttractionCard: View {
    let attraction: TouristAttraction
    let timeSlot: TimeSlot
    @State private var isExpanded = false
    
    private var convertedAttraction: Attraction {
        Attraction(
            id: attraction.id.uuidString,
            name: attraction.name,
            description: attraction.description,
            address: "", // TouristAttraction doesn't have address
            rating: 0.0, // TouristAttraction doesn't have rating
            imageURL: attraction.imageURL,
            coordinates: attraction.coordinates.locationCoordinate,
            websiteURL: attraction.websiteURL,
            priceLevel: .moderate, // Default to moderate
            category: Category(rawValue: attraction.category.rawValue) ?? .historical,
            estimatedDuration: attraction.estimatedDuration,
            tips: attraction.tips
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image
            AsyncImage(url: URL(string: attraction.imageURL)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                case .failure:
                    // Fallback to a category-specific placeholder image
                    AsyncImage(url: URL(string: getFallbackImageURL(for: attraction.category))) { fallbackPhase in
                        switch fallbackPhase {
                        case .empty:
                            ProgressView()
                                .frame(height: 120)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.2))
                        case .success(let fallbackImage):
                            fallbackImage
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 120)
                                .clipped()
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 120)
                                .foregroundColor(.gray)
                                .background(Color.gray.opacity(0.2))
                        @unknown default:
                            EmptyView()
                        }
                    }
                @unknown default:
                    EmptyView()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onAppear {
                print("[AttractionCard] Loading image for: \(attraction.name) | URL: \(attraction.imageURL)")
            }
            .onChange(of: attraction.imageURL) { _, newURL in
                print("[AttractionCard] Image URL changed for: \(attraction.name) | New URL: \(newURL)")
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Title and Time
                HStack {
                    Text(attraction.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(timeSlot.formattedTime)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Category and Duration
                HStack {
                    Label(attraction.category.rawValue.capitalized, systemImage: categoryIcon)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label("\(Int(attraction.estimatedDuration)) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Description
                if isExpanded {
                    Text(attraction.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                        .padding(.top, 4)
                    
                    // Map Snapshot
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: attraction.coordinates.locationCoordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )), annotationItems: [attraction]) { attraction in
                        MapMarker(coordinate: attraction.coordinates.locationCoordinate)
                    }
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Tips
                    if !attraction.tips.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tips:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Text(attraction.tips.joined(separator: " • "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.top, 4)
                    }
                }
                
                // Expand Button
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text(isExpanded ? "Show Less" : "Show More")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var categoryIcon: String {
        switch attraction.category {
        case .historical:
            return "building.columns"
        case .cultural:
            return "theatermasks"
        case .nature:
            return "leaf"
        case .entertainment:
            return "star"
        case .shopping:
            return "bag"
        case .dining:
            return "fork.knife"
        case .religious:
            return "building"
        case .museum:
            return "building.2"
        case .park:
            return "figure.hiking"
        case .architecture:
            return "building.3"
        }
    }
    
    private func getFallbackImageURL(for category: TouristAttraction.Category) -> String {
        switch category {
        case .museum:
            return "https://images.unsplash.com/photo-1518998053901-5348d3961a04?auto=format&fit=crop&w=800&q=80"
        case .cultural:
            return "https://images.unsplash.com/photo-1577083552431-6e5fd01988ec?auto=format&fit=crop&w=800&q=80"
        case .historical:
            return "https://images.unsplash.com/photo-1589828994425-a83f2f9b8488?auto=format&fit=crop&w=800&q=80"
        case .nature:
            return "https://images.unsplash.com/photo-1511497584788-876760111969?auto=format&fit=crop&w=800&q=80"
        case .entertainment:
            return "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=800&q=80"
        case .dining:
            return "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80"
        case .shopping:
            return "https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=800&q=80"
        case .religious:
            return "https://images.unsplash.com/photo-1548276145-69a9521f0499?auto=format&fit=crop&w=800&q=80"
        case .architecture:
            return "https://images.unsplash.com/photo-1487958449943-2429e8be8625?auto=format&fit=crop&w=800&q=80"
        case .park:
            return "https://images.unsplash.com/photo-1519331379826-f10be5486c6f?auto=format&fit=crop&w=800&q=80"
        }
    }
}

// MARK: - Supporting Views

private struct AttractionImage: View {
    let url: String
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var loadError = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.2))
            } else if loadError {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard !url.isEmpty else {
            Logger.warning("Empty image URL provided")
            isLoading = false
            loadError = true
            return
        }
        
        guard let imageUrl = URL(string: url) else {
            Logger.warning("Invalid image URL: \(url)")
            isLoading = false
            loadError = true
            return
        }
        
        URLSession.shared.dataTask(with: imageUrl) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    Logger.error("Failed to load image: \(error.localizedDescription)")
                    loadError = true
                    return
                }
                
                guard let data = data, let loadedImage = UIImage(data: data) else {
                    Logger.error("Invalid image data received")
                    loadError = true
                    return
                }
                
                image = loadedImage
                Logger.success("Successfully loaded image")
            }
        }.resume()
    }
}

private struct AttractionDetails: View {
    let attraction: TouristAttraction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(attraction.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(attraction.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            HStack {
                Label(attraction.category.rawValue.capitalized, systemImage: categoryIcon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("\(Int(attraction.estimatedDuration)) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !attraction.tips.isEmpty {
                Text("Tips:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text(attraction.tips.joined(separator: " • "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var categoryIcon: String {
        switch attraction.category {
        case .historical:
            return "building.columns"
        case .cultural:
            return "theatermasks"
        case .nature:
            return "leaf"
        case .entertainment:
            return "star"
        case .shopping:
            return "bag"
        case .dining:
            return "fork.knife"
        case .religious:
            return "building"
        case .museum:
            return "building.2"
        case .park:
            return "figure.hiking"
        case .architecture:
            return "building.3"
        }
    }
} 
