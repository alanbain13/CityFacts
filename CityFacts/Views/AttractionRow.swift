/// AttractionRow.swift
/// A view that displays a single attraction's basic information in a row format.
/// This view is used as part of a list or stack of attractions.

import SwiftUI

/// A view that represents a single attraction in a list.
/// It displays the attraction's image, name, rating, price level, and address,
/// along with a button to view more details.
///
/// The row layout consists of:
/// - A square image on the left
/// - Attraction details in the middle (name, rating, price level, address)
/// - A chevron indicator on the right
/// 
/// The entire row is tappable and will trigger the provided onSelect action.
struct AttractionRow: View {
    /// The attraction model containing all the data to be displayed
    let attraction: Attraction
    
    /// Indicates whether this attraction is currently selected in the parent view
    let isSelected: Bool
    
    /// Callback closure executed when the row is tapped
    /// This is typically used to show the attraction details view
    let onSelect: () -> Void
    
    /// The view body that constructs the attraction row layout
    /// 
    /// Layout structure:
    /// - Button wrapper for tap handling
    ///   - HStack for horizontal layout
    ///     - AsyncImage for attraction photo
    ///     - VStack for attraction details
    ///       - Name
    ///       - Description
    ///       - Address
    ///     - Chevron indicator
    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .center, spacing: 12) {
                AsyncImage(url: URL(string: attraction.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(attraction.name)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(attraction.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Text(attraction.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.blue)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            .opacity(isSelected ? 0.7 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 