import Foundation

struct TimeSlot: Identifiable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
    
    static let morningSlot = TimeSlot(
        startTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
        endTime: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
    )
    
    static let afternoonSlot = TimeSlot(
        startTime: Calendar.current.date(bySettingHour: 13, minute: 0, second: 0, of: Date())!,
        endTime: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date())!
    )
    
    static let allSlots = [morningSlot, afternoonSlot]
    
    func canFit(duration: TimeInterval) -> Bool {
        return duration <= self.duration
    }
    
    func remainingTime(after duration: TimeInterval) -> TimeInterval {
        return max(0, self.duration - duration)
    }
} 