import Foundation

// Verification Script

// 1. Setup Data
let weather = Weather(
    temperature: -10,
    feelsLike: -13,
    windSpeed: 12,
    precipitationProbability: 0.0,
    humidity: 0 // not specified in example, default 0
)

// User Profile (default, sensitivity 0)
// Spec says "adjustable by coldSensitivity".
// Example output implementation assumption:
// "temperature = -10, feelsLike = -13" -> Effective Temp = -13 - (0) = -13.
// Threshold: < -10.
// Modifiers:
// Wind > 10 (12 > 10) -> Add wind protection.
// Precip 0.0 -> None.
// Range -> Not specified.

let user = UserProfile.standard

// 2. Run Engine
let recommendation = OutfitRecommendationEngine.generateOutfitRecommendation(weather: weather, user: user)

// 3. Print Output
print("Summary: \(recommendation.summaryText)")
print("Items: \(recommendation.items.map { $0.rawValue })")
print("Explanations: \(recommendation.explanation)")

// Verification Check
let expectedSummary = "Heavier winter coat, warm base layer, gloves, and a hat." // prompt example style, though maybe not exact match depending on implementation details
// Check requirements: "Add wind protection".
// Logic:
// -13 is < -10. Items: heavyWinterCoat, warmBaseLayer, gloves, hat.
// Wind > 10: Add scarf?
// If scarf is added, summary might be: "Heavier winter coat, warm base layer, gloves, hat, and a scarf."

print("\n--- Diagnostic ---")
print("FeelsLike: \(weather.feelsLike)")
print("EffectiveTemp: \(weather.feelsLike - Double(user.coldSensitivity * 2))")
print("Wind: \(weather.windSpeed)")
