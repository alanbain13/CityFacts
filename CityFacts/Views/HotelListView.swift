import SwiftUI
import CoreLocation
import WebKit

// HotelListView displays a list of hotels for a selected city.
// Users can select a hotel to view details or choose it for their itinerary.
// The view fetches hotel data and supports navigation to HotelDetailView.
struct HotelListView: View {
    let city: City
    @Binding var selectedHotel: Hotel?
    var onDone: (() -> Void)? = nil

    @StateObject private var viewModel = HotelListViewModel()

    var body: some View {
        VStack {
            if let selected = selectedHotel {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Currently Selected Hotel")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HotelCard(hotel: selected)
                        .overlay(
                            Text("Selected")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.blue)
                                .clipShape(Capsule())
                                .padding(8),
                            alignment: .topTrailing
                        )
                }
                .padding(.bottom)
            }

            if viewModel.isLoading {
                ProgressView("Loading hotels...")
                    .padding()
            } else if viewModel.hotels.isEmpty {
                Text("No hotels found")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List(viewModel.hotels) { hotel in
                    VStack(alignment: .leading, spacing: 8) {
                        // Hotel card for viewing details
                        NavigationLink(destination: HotelDetailView(
                            hotel: hotel,
                            city: city,
                            selectedHotel: $selectedHotel
                        )) {
                            HotelCard(hotel: hotel)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Separate select button
                        Button(action: {
                            selectedHotel = hotel
                            onDone?()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Select This Hotel")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Select Hotel")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    onDone?()
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchHotels(for: city)
            }
        }
    }
}

struct HotelRow: View {
    let hotel: Hotel
    let onSelect: () -> Void
    @State private var showingWebsite = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Hotel Image
            if let imageURL = hotel.imageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Hotel Info
            VStack(alignment: .leading, spacing: 4) {
                Text(hotel.name)
                    .font(.headline)
                
                if let address = hotel.address {
                    Text(address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    if let rating = hotel.rating {
                        Text("\(rating, specifier: "%.1f")")
                            .foregroundColor(.yellow)
                        Text("•")
                            .foregroundColor(.secondary)
                    }
                    if let priceLevel = hotel.priceLevel {
                        Text(priceLevel.rawValue)
                            .foregroundColor(.secondary)
                    }
                }
                .font(.subheadline)
            }
            .padding(.horizontal, 4)
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: onSelect) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Select Hotel")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                if let websiteURL = hotel.websiteURL {
                    Button(action: { showingWebsite = true }) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Website")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .sheet(isPresented: $showingWebsite) {
            if let websiteURLString = hotel.websiteURL,
               let websiteURL = URL(string: websiteURLString) {
                NavigationView {
                    HotelWebView(url: websiteURL)
                        .navigationTitle("Hotel Website")
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

// HotelWebView is a UIViewRepresentable that displays a hotel's website in a WebKit view.
// It provides a clean, non-persistent web view for viewing hotel websites within the app.
// The view supports back/forward navigation gestures and loads the specified URL.
struct HotelWebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
} 