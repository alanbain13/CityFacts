import Foundation

struct Landmark: Identifiable, Codable, Hashable {
    var id: String { name }
    let name: String
    let description: String
    let imageURL: String
} 