import Foundation

struct Award: Decodable, Identifiable {
    enum Criterion: String, Decodable {
        case issues
        case closed
        case tags
        case unlock
    }

    var id: String { name }
    var name: String
    var description: String
    var color: String
    var criterion: Criterion
    var value: Int
    var image: String

    static let allAwards = Bundle.main.decode("Awards.json", as: [Award].self)
    static let example = allAwards[0]
}
