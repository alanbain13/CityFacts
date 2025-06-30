import SwiftUI

struct HotelCard: View {
    let hotel: Hotel
    var onHotelChange: (() -> Void)? = nil
    var onImageTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hotel Image - tappable for viewing details
            Button(action: { onImageTap?() }) {
                AsyncImage(url: URL(string: hotel.imageURL ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 150)
                            .clipped()
                    case .failure:
                        // Show a placeholder if the image fails to load
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 150)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(.secondary)
                    case .empty:
                        // Show a progress view while loading
                        ProgressView()
                            .frame(height: 150)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Hotel Details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hotel.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if let address = hotel.address {
                            Text(address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    if let onHotelChange = onHotelChange {
                        Button(action: onHotelChange) {
                            Text("Change")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
} 