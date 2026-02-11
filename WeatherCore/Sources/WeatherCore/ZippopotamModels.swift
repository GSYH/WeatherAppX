import Foundation

struct ZippopotamResponse: Decodable {
  struct Place: Decodable {
    let placeName: String
    let stateAbbreviation: String
    let latitude: String
    let longitude: String

    enum CodingKeys: String, CodingKey {
      case placeName = "place name"
      case stateAbbreviation = "state abbreviation"
      case latitude
      case longitude
    }
  }

  let places: [Place]

  enum CodingKeys: String, CodingKey {
    case places = "places"
  }
}
