import SwiftUI

struct AttractionCard: View {
    let attraction: TouristAttraction
    @State private var showingDetails = false
    
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
        Button {
            showingDetails = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                if let url = URL(string: attraction.imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(attraction.name)
                        .font(.headline)
                    
                    Text(attraction.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Label(attraction.category.rawValue.capitalized, systemImage: categoryIcon)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Label("\(Int(attraction.estimatedDuration / 60)) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !attraction.tips.isEmpty {
                        Text("Tips:")
                            .font(.caption)
                            .fontWeight(.medium)
                        ForEach(attraction.tips, id: \.self) { tip in
                            Text("• \(tip)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 2)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetails) {
            NavigationStack {
                AttractionDetailView(attraction: convertedAttraction)
            }
        }
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