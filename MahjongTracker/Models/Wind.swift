import Foundation

enum Wind: Int, Codable, CaseIterable, Identifiable {
    case east  = 0
    case south = 1
    case west  = 2
    case north = 3

    var id: Int { rawValue }

    var character: String {
        switch self {
        case .east:  return "東"
        case .south: return "南"
        case .west:  return "西"
        case .north: return "北"
        }
    }

    var label: String {
        switch self {
        case .east:  return "East"
        case .south: return "South"
        case .west:  return "West"
        case .north: return "North"
        }
    }

    var next: Wind {
        Wind(rawValue: (rawValue + 1) % 4) ?? .east
    }
}
