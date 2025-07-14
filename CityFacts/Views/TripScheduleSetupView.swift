import SwiftUI

// TripScheduleSetupView allows users to set departure and arrival times for their trip
// This establishes the foundation for all subsequent transit and attraction scheduling
struct TripScheduleSetupView: View {
    @Binding var tripSchedule: TripSchedule?
    @Environment(\.dismiss) private var dismiss
    
    @State private var homeCity: String = ""
    @State private var departureDate: Date = Date()
    @State private var departureTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var returnDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    @State private var returnTime: Date = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Home City") {
                    TextField("Enter your home city", text: $homeCity)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section("Departure") {
                    DatePicker("Departure Date", selection: $departureDate, displayedComponents: .date)
                    DatePicker("Departure Time", selection: $departureTime, displayedComponents: .hourAndMinute)
                }
                
                Section("Return") {
                    DatePicker("Return Date", selection: $returnDate, displayedComponents: .date)
                    DatePicker("Return Time", selection: $returnTime, displayedComponents: .hourAndMinute)
                }
                
                Section("Trip Summary") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Duration:")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(tripDuration) days")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Departure:")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(formattedDepartureDate) at \(formattedDepartureTime)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Return:")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(formattedReturnDate) at \(formattedReturnTime)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Trip Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTripSchedule()
                    }
                    .disabled(homeCity.isEmpty)
                }
            }
        }
    }
    
    private var tripDuration: Int {
        Calendar.current.dateComponents([.day], from: departureDate, to: returnDate).day ?? 0 + 1
    }
    
    private var formattedDepartureDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: departureDate)
    }
    
    private var formattedReturnDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: returnDate)
    }
    
    private var formattedDepartureTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: departureTime)
    }
    
    private var formattedReturnTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: returnTime)
    }
    
    private func saveTripSchedule() {
        let schedule = TripSchedule(
            homeCity: homeCity,
            departureDate: departureDate,
            departureTime: departureTime,
            returnDate: returnDate,
            returnTime: returnTime
        )
        
        tripSchedule = schedule
        dismiss()
    }
}

#Preview {
    TripScheduleSetupView(tripSchedule: .constant(nil))
} 