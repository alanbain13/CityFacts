import SwiftUI

struct HotelCard: View {
    let hotel: Hotel
    let schedule: HotelSchedule?
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
                        
                        // Hotel rating and price
                        HStack {
                            if let rating = hotel.rating {
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                    Text(String(format: "%.1f", rating))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if let priceLevel = hotel.priceLevel {
                                Text(priceLevel.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
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
                
                // Hotel Schedule Information
                if let schedule = schedule {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Hotel Schedule")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Check-in")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(schedule.formattedCheckInTime)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .center, spacing: 2) {
                                Text("Evening Arrival")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(schedule.formattedEveningArrivalTime)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Check-out")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(schedule.formattedCheckOutTime)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
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