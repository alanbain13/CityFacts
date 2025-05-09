import SwiftUI
import MapKit
import SafariServices

struct AttractionDetailView: View {
    let attraction: Attraction
    @Environment(\.dismiss) private var dismiss
    @State private var showingWebsite = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Image with Website Link
                if let url = URL(string: attraction.imageURL) {
                    ZStack(alignment: .topTrailing) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                        }
                        .frame(height: 250)
                        .clipped()
                        .onTapGesture {
                            if let websiteURLString = attraction.websiteURL,
                               let websiteURL = URL(string: websiteURLString) {
                                showingWebsite = true
                            }
                        }
                        
                        // Map Link
                        Link(destination: URL(string: "maps://?daddr=\(attraction.coordinates.latitude),\(attraction.coordinates.longitude)")!) {
                            HStack {
                                Image(systemName: "map")
                                Text("View on Map")
                            }
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                        }
                        .padding(12)
                    }
                }
                
                VStack(spacing: 20) {
                    // Information Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Information")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(attraction.name)
                                .font(.headline)
                            
                            Text(attraction.description)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Interesting Facts Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Interesting Facts")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            FactRow(icon: "tag", text: "Category: \(attraction.category.rawValue)")
                            FactRow(icon: "clock", text: "Duration: \(Int(attraction.estimatedDuration / 60)) minutes")
                            FactRow(icon: "dollarsign.circle", text: "Price Level: \(attraction.priceLevel.rawValue)")
                            FactRow(icon: "star.fill", text: "Rating: \(String(format: "%.1f", attraction.rating))")
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Tips Section
                    if !attraction.tips.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Tips")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(attraction.tips, id: \.self) { tip in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                            .foregroundStyle(.secondary)
                                        Text(tip)
                                    }
                                }
                            }
                            .font(.body)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingWebsite) {
            if let websiteURLString = attraction.websiteURL,
               let websiteURL = URL(string: websiteURLString) {
                NavigationStack {
                    SafariView(url: websiteURL)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingWebsite = false
                                }
                            }
                        }
                }
            }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct FactRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
            Text(text)
        }
        .font(.subheadline)
    }
} 