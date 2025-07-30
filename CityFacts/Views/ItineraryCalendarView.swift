import SwiftUI

// ItineraryCalendarView displays all itinerary items in chronological order
// It shows a simple timeline view with proper sequencing of transit, attractions, and hotels
struct ItineraryCalendarView: View {
    let city: City
    let startDate: Date
    let endDate: Date
    let homeCity: City
    let tripSchedule: TripSchedule
    @State private var attractions: [TouristAttraction] = []
    @State private var selectedHotels: [Int: Hotel?] = [:]
    @State private var transitDays: [TransitDay] = []
    @State private var isLoading = true
    @State private var error: Error?
    @State private var showingExportSheet = false
    @State private var exportedXML: String = ""
    @StateObject private var cityStore = CityStore(isPremiumUser: false) // <-- Added CityStore
    @Environment(\.dismiss) private var dismiss
    
    private var numberOfDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return (components.day ?? 0) + 1
    }
    
    private func dateForDay(_ dayIndex: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: dayIndex, to: startDate) ?? startDate
    }
    
    private func attractionsForDay(_ dayIndex: Int) -> [TouristAttraction] {
        let attractionsPerDay = Int(ceil(Double(attractions.count) / Double(numberOfDays)))
        let startIndex = dayIndex * attractionsPerDay
        let endIndex = min(startIndex + attractionsPerDay, attractions.count)
        return Array(attractions[startIndex..<endIndex])
    }
    
    private func transitRoutesForDay(_ day: Int) -> [TransitRoute] {
        let calendar = Calendar.current
        let date = dateForDay(day - 1)
        return transitDays.first { calendar.isDate($0.date, inSameDayAs: date) }?.routes ?? []
    }
    
    private func exportTimelineToXML() {
        let tripInfo = TripTimeline.TripInfo(
            originCity: homeCity.name,
            destinationCity: city.name,
            startDate: startDate,
            endDate: endDate,
            startTime: tripSchedule.departureTime,
            endTime: tripSchedule.returnTime,
            homeCity: homeCity,
            destinationCityData: city
        )
        
        let timeline = TimelineDependencyResolver.generateTimeline(
            tripInfo: tripInfo,
            attractions: attractions,
            venues: cityStore.localDataService?.getVenues(for: city.id.uuidString) ?? [], // <-- Safely unwrap optional
            transitDays: transitDays,
            selectedHotels: selectedHotels
        )
        
        let serializer = XMLTimelineSerializer()
        exportedXML = serializer.exportToXML(timeline: timeline)
        showingExportSheet = true
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView("Loading timeline...")
                        .padding()
                } else if let error = error {
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    let allTimelineItems: [(day: Int, item: UnifiedTimelineItem)] = (0..<numberOfDays).flatMap { dayIndex in
                        let day = dayIndex + 1
                        let timelineItems = PersonalAvailabilityCalendar.generateChronologicalTimeline(
                            dayDate: dateForDay(dayIndex),
                            attractions: attractionsForDay(dayIndex),
                            venues: cityStore.localDataService?.getVenues(for: city.id.uuidString) ?? [], // <-- Safely unwrap optional
                            transitRoutes: transitRoutesForDay(day),
                            hotel: self.selectedHotels[day] ?? nil
                        )
                        return timelineItems.map { (day: day, item: $0) }
                    }.sorted { $0.item.start < $1.item.start }
                    
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(allTimelineItems.enumerated()), id: \.element.item.id) { idx, tuple in
                            let day = tuple.day
                            let item = tuple.item
                            let showDayLabel = idx == 0 || day != allTimelineItems[idx - 1].day
                            
                            if showDayLabel {
                                Text("Day \(day) - \(formatDate(dateForDay(day-1)))")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .padding(.top, idx == 0 ? 0 : 16)
                                    .padding(.bottom, 8)
                                    .padding(.horizontal)
                            }
                            
                            TimelineEventRow(item: item, day: day)
                        }
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("Trip Timeline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: exportTimelineToXML) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                    }
                    .disabled(isLoading || error != nil)
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportXMLView(xmlContent: exportedXML, tripName: "\(homeCity.name)-to-\(city.name)")
            }
        }
        .onAppear {
            if attractions.isEmpty {
                Task {
                    await loadData()
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func loadData() async {
        isLoading = true
        error = nil
        
        do {
            let fetchedAttractions = try await GooglePlacesService.shared.fetchTouristAttractions(for: city)
            
            await MainActor.run {
                self.attractions = fetchedAttractions
            }
            
            // Generate transit routes
            do {
                let transitRoutes = try await TransitService.shared.generateTransitRoutes(
                    tripSchedule: tripSchedule,
                    destinationCity: city,
                    selectedHotels: selectedHotels,
                    attractions: fetchedAttractions
                )
                await MainActor.run {
                    self.transitDays = transitRoutes
                }
            } catch {
                Logger.error("Error generating transit routes: \(error.localizedDescription)")
            }
        } catch {
            Logger.error("Error loading attractions: \(error)")
            self.error = error
        }
        
        isLoading = false
    }
}

// Export XML View
struct ExportXMLView: View {
    let xmlContent: String
    let tripName: String
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var showingDocumentPicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private func saveToDownloads() {
        // Create a temporary file with proper XML extension
        let fileName = "\(tripName)-timeline.xml"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            // Write XML content to temporary file
            try xmlContent.write(to: tempURL, atomically: true, encoding: .utf8)
            
            // Show document picker to save to Downloads
            showingDocumentPicker = true
        } catch {
            alertMessage = "Error creating XML file: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func shareXML() {
        // Create a temporary file for sharing
        let fileName = "\(tripName)-timeline.xml"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try xmlContent.write(to: tempURL, atomically: true, encoding: .utf8)
            showingShareSheet = true
        } catch {
            alertMessage = "Error creating XML file: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Trip Timeline Export")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Your trip timeline has been exported to XML format")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // XML Preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("XML Preview")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView {
                        Text(xmlContent)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    .frame(maxHeight: 300)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: saveToDownloads) {
                        HStack {
                            Image(systemName: "folder")
                            Text("Save to Downloads")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Button(action: shareXML) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share XML File")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.bottom)
            }
            .navigationTitle("Export Timeline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Export Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPickerView(xmlContent: xmlContent, fileName: "\(tripName)-timeline.xml")
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheetView(xmlContent: xmlContent, fileName: "\(tripName)-timeline.xml")
        }
    }
}

// Document Picker for saving to Downloads
struct DocumentPickerView: UIViewControllerRepresentable {
    let xmlContent: String
    let fileName: String
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Create a temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try xmlContent.write(to: tempURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error creating temporary file: \(error)")
        }
        
        // Create document picker for saving
        let picker = UIDocumentPickerViewController(forExporting: [tempURL])
        picker.delegate = context.coordinator
        picker.shouldShowFileExtensions = true
        
        // Set presentation style to prevent hanging
        picker.modalPresentationStyle = .formSheet
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let selectedURL = urls.first else { return }
            
            // Copy the file to the selected location
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(parent.fileName)
            
            do {
                if FileManager.default.fileExists(atPath: selectedURL.path) {
                    try FileManager.default.removeItem(at: selectedURL)
                }
                try FileManager.default.copyItem(at: tempURL, to: selectedURL)
                
                // Show success message
                DispatchQueue.main.async {
                    print("File saved successfully to: \(selectedURL.path)")
                }
            } catch {
                print("Error saving file: \(error)")
            }
            
            // Clean up temporary file
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("Document picker was cancelled")
            
            // Clean up temporary file
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(parent.fileName)
            try? FileManager.default.removeItem(at: tempURL)
        }
    }
}

// Share Sheet for XML export
struct ShareSheetView: UIViewControllerRepresentable {
    let xmlContent: String
    let fileName: String
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Create a temporary file for sharing
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try xmlContent.write(to: tempURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error creating temporary file for sharing: \(error)")
        }
        
        let controller = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        
        // Set presentation style to prevent hanging
        controller.modalPresentationStyle = .popover
        
        controller.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            if let error = error {
                print("Share sheet error: \(error)")
            } else if completed {
                print("File shared successfully")
            } else {
                print("Share cancelled")
            }
            
            // Clean up temporary file
            try? FileManager.default.removeItem(at: tempURL)
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Simple timeline event row
struct TimelineEventRow: View {
    let item: UnifiedTimelineItem
    let day: Int
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func getEventIcon() -> String {
        switch item {
        case .transit:
            return "car.fill"
        case .attraction:
            return "building.2.fill"
        case .hotel:
            return "bed.double.fill"
        case .meal:
            return "fork.knife"
        case .sleep:
            return "moon.fill"
        case .venue:
            return "building.2.crop.circle.fill"
        }
    }
    
    private func getEventColor() -> Color {
        switch item {
        case .transit:
            return .blue
        case .attraction:
            return .green
        case .hotel:
            return .purple
        case .meal:
            return .orange
        case .sleep:
            return .indigo
        case .venue:
            return .red
        }
    }
    
    private func getEventTitle() -> String {
        switch item {
        case .transit(let route, _, _):
            return "\(route.startLocation) → \(route.endLocation)"
        case .attraction(let attraction, _, _):
            return attraction.name
        case .hotel(let hotel, _, _):
            return "Check-in: \(hotel.name)"
        case .meal(let mealType, _, _):
            return mealType.capitalized
        case .sleep(_, _):
            return "Sleep"
        case .venue(let venue, _, _):
            return venue.name
        }
    }
    
    private func getEventSubtitle() -> String {
        switch item {
        case .transit(let route, _, _):
            return "\(route.mode.rawValue) • \(Int(route.elapsedTime / 60)) min"
        case .attraction(let attraction, _, _):
            return attraction.category.rawValue
        case .hotel(let hotel, _, _):
            return hotel.address ?? "Hotel"
        case .meal(_, _, _):
            return "Meal time"
        case .sleep(_, _):
            return "Rest time"
        case .venue(let venue, _, _):
            return venue.category ?? "Venue"
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time indicator
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTime(item.start))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text(formatTime(item.end))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50, alignment: .trailing)
            
            // Event content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: getEventIcon())
                        .foregroundColor(getEventColor())
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(getEventTitle())
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(getEventSubtitle())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
    }
}

#Preview {
    ItineraryCalendarView(
        city: City(
            id: UUID(),
            name: "Paris",
            country: "France",
            continent: .europe,
            population: 2161000,
            description: "Paris is the capital and largest city of France.",
            landmarks: [],
            coordinates: City.Coordinates(latitude: 48.8566, longitude: 2.3522),
            timezone: "Europe/Paris",
            imageURL: nil,
            facts: []
        ),
        startDate: Date(),
        endDate: Date().addingTimeInterval(86400 * 3),
        homeCity: City(
            id: UUID(),
            name: "New York",
            country: "USA",
            continent: .northAmerica,
            population: 8419000,
            description: "New York is the most populous city in the United States.",
            landmarks: [],
            coordinates: City.Coordinates(latitude: 40.7128, longitude: -74.0060),
            timezone: "America/New_York",
            imageURL: nil,
            facts: []
        ),
        tripSchedule: TripSchedule(
            homeCity: "New York",
            departureDate: Date(),
            departureTime: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date(),
            returnDate: Date().addingTimeInterval(86400 * 3),
            returnTime: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date().addingTimeInterval(86400 * 3)) ?? Date()
        )
    )
} 