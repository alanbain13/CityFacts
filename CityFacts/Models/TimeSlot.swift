import Foundation

struct TimeSlot: Identifiable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    
    static let morningSlot = TimeSlot(
        startTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 0))!,
        endTime: Calendar.current.date(from: DateComponents(hour: 12, minute: 0))!,
        duration: 3 * 60 * 60 // 3 hours in seconds
    )
    
    static let afternoonSlot = TimeSlot(
        startTime: Calendar.current.date(from: DateComponents(hour: 14, minute: 0))!,
        endTime: Calendar.current.date(from: DateComponents(hour: 17, minute: 0))!,
        duration: 3 * 60 * 60 // 3 hours in seconds
    )
    
    static let allSlots = [morningSlot, afternoonSlot]
    
    func canFit(duration: TimeInterval) -> Bool {
        return duration <= self.duration
    }
    
    func remainingTime(after duration: TimeInterval) -> TimeInterval {
        return max(0, self.duration - duration)
    }
} 