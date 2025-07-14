import SwiftUI
import MapKit

// TransitCard displays a card view for a single transit route.
// It shows the route image, mode, timing, cost, and distance information.
// Users can tap the card to view detailed route information and modify settings.
struct TransitCard: View {
    let route: TransitRoute
    @State private var isExpanded = false
    @State private var showingRouteDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Route Image
            AsyncImage(url: URL(string: route.imageURL ?? "")) { phase in
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
                    // Fallback to mode-specific placeholder image
                    Image(systemName: route.mode.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 120)
                        .foregroundColor(route.mode.color)
                        .background(route.mode.color.opacity(0.1))
                @unknown default:
                    EmptyView()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Route Type and Mode
                HStack {
                    Label(route.type.rawValue, systemImage: route.type.icon)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Label(route.mode.rawValue, systemImage: route.mode.icon)
                        .font(.subheadline)
                        .foregroundColor(route.mode.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(route.mode.color.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Start and End Locations
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(route.startLocation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text(route.endLocation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Timing Information
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Departure")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(route.formattedStartTime)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Arrival")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(route.formattedEndTime)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                // Route Details
                HStack {
                    Label(route.formattedElapsedTime, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label(route.formattedDistance, systemImage: "location.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label(route.formattedCost, systemImage: "dollarsign.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Description
                if isExpanded {
                    Text(route.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                        .padding(.top, 4)
                    
                    // Instructions
                    if !route.instructions.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Instructions:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            ForEach(route.instructions, id: \.self) { instruction in
                                HStack(alignment: .top) {
                                    Text("•")
                                        .foregroundColor(.blue)
                                    Text(instruction)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                
                // Action Buttons
                HStack {
                    Button(action: {
                        showingRouteDetail = true
                    }) {
                        HStack {
                            Image(systemName: "map")
                            Text("View Route")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    Spacer()
                    
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
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showingRouteDetail) {
            TransitRouteDetailView(route: route)
        }
    }
}

// TransitRouteDetailView shows detailed route information and allows customization
struct TransitRouteDetailView: View {
    let route: TransitRoute
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMode: TransitRoute.TransportMode
    @State private var selectedStartTime: Date
    @State private var selectedEndTime: Date
    
    init(route: TransitRoute) {
        self.route = route
        self._selectedMode = State(initialValue: route.mode)
        self._selectedStartTime = State(initialValue: route.startTime)
        self._selectedEndTime = State(initialValue: route.endTime)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Route Image
                    AsyncImage(url: URL(string: route.imageURL ?? "")) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.2))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                        case .failure:
                            Image(systemName: route.mode.icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                                .foregroundColor(route.mode.color)
                                .background(route.mode.color.opacity(0.1))
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Route Information
                    VStack(alignment: .leading, spacing: 16) {
                        // Route Type
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Route Type")
                                .font(.headline)
                            Text(route.type.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Transport Mode Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Transport Mode")
                                .font(.headline)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(TransitRoute.TransportMode.allCases, id: \.self) { mode in
                                    Button(action: {
                                        selectedMode = mode
                                    }) {
                                        HStack {
                                            Image(systemName: mode.icon)
                                                .foregroundColor(mode.color)
                                            Text(mode.rawValue)
                                                .font(.caption)
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(selectedMode == mode ? mode.color.opacity(0.2) : Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        
                        // Time Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Timing")
                                .font(.headline)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Start Time")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    DatePicker("", selection: $selectedStartTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("End Time")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    DatePicker("", selection: $selectedEndTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                }
                            }
                        }
                        
                        // Route Details
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Route Details")
                                .font(.headline)
                            
                            HStack {
                                DetailItem(icon: "clock", title: "Duration", value: route.formattedElapsedTime)
                                Spacer()
                                DetailItem(icon: "location.circle", title: "Distance", value: route.formattedDistance)
                                Spacer()
                                DetailItem(icon: "dollarsign.circle", title: "Cost", value: route.formattedCost)
                            }
                        }
                        
                        // Instructions
                        if !route.instructions.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Instructions")
                                    .font(.headline)
                                
                                ForEach(route.instructions, id: \.self) { instruction in
                                    HStack(alignment: .top) {
                                        Text("•")
                                            .foregroundColor(.blue)
                                        Text(instruction)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Route Details")
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

// DetailItem is a helper view for displaying route details
struct DetailItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
} 