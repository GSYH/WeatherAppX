import Foundation

// MARK: - Core Data Models

struct Weather {
    let temperature: Double        // Celsius
    let feelsLike: Double          // Celsius
    let windSpeed: Double          // mph (as requested in spec, though mixed units are tricky, following spec)
    let precipitationProbability: Double // 0.0 – 1.0
    let humidity: Double           // 0 – 100
}

struct UserProfile {
    var coldSensitivity: Int       // -2 to +2
    var commuteMinutes: Int        // minutes
    
    // Default profile
    static let standard = UserProfile(coldSensitivity: 0, commuteMinutes: 30)
}

// MARK: - Recommendation Models

enum OutfitItem: String, CaseIterable {
    // Outerwear
    case heavyWinterCoat = "heavier winter coat"
    case winterCoat = "winter coat"
    case insulatedJacket = "insulated jacket"
    case lightJacket = "light jacket"
    case noOuterwear = "no outerwear" // logic might filter this out or handle explicitly
    
    // Tops/Base
    case warmBaseLayer = "warm base layer"
    case tShirt = "t-shirt"
    case longSleeveShirt = "long-sleeve shirt" 
    case sweater = "sweater"
    
    // Bottoms (implied or explicit? spec mainly focuses on coat/accessories in examples, but we can add)
    // Spec example: "Heavier winter coat, warm base layer, gloves, and a hat."
    // It seems focused on warmth protection.
    
    // Accessories
    case gloves = "gloves"
    case hat = "hat"
    case scarf = "scarf"
    case umbrella = "umbrella"
    
    // Footwear
    case waterproofBoots = "waterproof boots"
    case normalShoes = "shoes"
}

struct OutfitRecommendation {
    let items: [OutfitItem]
    let summaryText: String
    let explanation: [String]
}
