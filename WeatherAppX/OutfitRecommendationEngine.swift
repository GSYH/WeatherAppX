import Foundation

struct OutfitRecommendationEngine {
    
    static func generateOutfitRecommendation(weather: Weather, user: UserProfile) -> OutfitRecommendation {
        var items: [OutfitItem] = []
        var explanations: [String] = []
        
        // 1. Adjust temperature sensitivity
        // "coldSensitivity shifts all temperature thresholds by ±2°C per level"
        // Example: coldSensitivity = +2 (very cold sensitive) -> user feels colder -> heavier clothing earlier
        // Current logic uses strict thresholds.
        // Conceptually: If I am cold sensitive, 12°C feels like 8°C to me.
        // So Effective Temperature = FeelsLike - (Sensitivity * 2)
        // Check:
        // if T=10, Sens=+2. Eff = 10 - 4 = 6.
        // 10C is usually "light jacket", but 6 is "coat". So I need coat at 10C. Correct.
        // if T=10, Sens=-2 (warm tolerant). Eff = 10 - (-4) = 14.
        // 14C is > 10, so "light jacket". Correct.
        
        let effectiveTemp = weather.feelsLike - (Double(user.coldSensitivity) * 2.0)
        
        // 2. Base Layer & Coat Logic
        if effectiveTemp < -10 {
            items.append(.heavyWinterCoat)
            items.append(.warmBaseLayer)
            items.append(.gloves)
            items.append(.hat)
            explanations.append("Temperatures below -10°C require heavy insulation and extremity protection.")
        } else if effectiveTemp >= -10 && effectiveTemp < 0 {
            items.append(.winterCoat)
            items.append(.warmBaseLayer)
            explanations.append("Freezing temperatures require a winter coat and thermal layers.")
        } else if effectiveTemp >= 0 && effectiveTemp < 10 {
            items.append(.insulatedJacket) // "coat or insulated jacket" - simplified to insulated jacket for distinct item
            explanations.append("Cool temperatures between 0-10°C call for an insulated jacket.")
        } else {
            // > 10°C
            items.append(.lightJacket)
            explanations.append("Mild temperatures allow for lighter outerwear.")
        }
        
        // 3. Modifiers
        
        // Wind
        if weather.windSpeed > 10 {
            // Ideally we'd wrap or modify the outer layer, but since we return [OutfitItem],
            // we might want to ensure the chosen item is windproof, or add a scarf/protection.
            // The prompt says "add wind protection".
            // Since our enum is limited, let's assume 'scarf' or ensuring the coat is good.
            // Let's add 'scarf' for wind if not already present, or just note it.
            // If it's already < -10, we have hat/gloves. Scarf is good.
            if !items.contains(.scarf) {
                items.append(.scarf)
                explanations.append("Wind speed over 10mph suggests adding a scarf or windbreaker.")
            }
        }
        
        // Precipitation
        if weather.precipitationProbability > 0.4 {
            items.append(.waterproofBoots)
            // If light jacket, maybe change to raincoat?
            // "add waterproof footwear" is specifically requested.
            // We could also add umbrella.
            items.append(.umbrella)
            explanations.append("High chance of precipitation (>40%) requires waterproof footwear and an umbrella.")
        }
        
        // Commute
        if user.commuteMinutes > 40 {
             // "Prioritize warmth and comfort"
             // If we are on the edge, upgrade?
             // Simple logic: if we have a light jacket (10+), maybe upgrade to insulated?
             // Or if insulated (0-10), upgrade to winter coat?
             
             // Let's apply a small extra shift to effective temp effectively?
             // Or explicitly upgrade specific items.
             
             // Let's check existing items.
           if let index = items.firstIndex(of: .lightJacket) {
               items[index] = .insulatedJacket
               explanations.append("Long commute (>40m) suggests upgrading to a warmer jacket.")
           } else if let index = items.firstIndex(of: .insulatedJacket) {
               items[index] = .winterCoat
               explanations.append("Long commute (>40m) suggests upgrading to a full winter coat.")
           }
        }
        
        // 4. Generate Summary
        let summary = generateSummary(for: items)
        
        return OutfitRecommendation(items: items, summaryText: summary, explanation: explanations)
    }
    
    private static func generateSummary(for items: [OutfitItem]) -> String {
        // Goal: "Heavier winter coat, warm base layer, gloves, and a hat."
        // Natural language, oxord comma style.
        
        // Filter out "no outerwear" if we added it (we didn't add it in logic above, but good to be safe)
        let validItems = items.filter { $0 != .noOuterwear }
        
        if validItems.isEmpty {
            return "Wear whatever you like."
        }
        
        let modules = validItems.map { $0.rawValue }
        
        if modules.count == 1 {
            return "A \(modules[0])." // e.g. "A light jacket."
        } else if modules.count == 2 {
            return "\(modules[0].capitalized) and a \(modules[1])."
        } else {
            // Join with commas, add "and a" before last.
            // Note: Usage of "a" / "an" is tricky without NLP.
            // The prompt example: "Heavier winter coat, warm base layer, gloves, and a hat."
            // "gloves" is plural, no "a".
            // "hat" is singular, gets "a".
            // "warm base layer" singular, gets implicit handled? Dictionary is best.
            
            var resultParts: [String] = []
            
            for (index, item) in validItems.enumerated() {
                let name = item.rawValue
                
                // Add article if singular and not first item (first item capitalized at end).
                // Wait, prompt: "Heavier winter coat, warm base layer, gloves, and a hat."
                // "Heavier winter coat" - no article at start?
                // Actually usually "A heavier winter coat..." is better, but prompt omits it at start?
                // The prompt example is: "Heavier winter coat, warm base layer, gloves, and a hat."
                // So First item: No article, capitalize.
                // Middle items: No article? "warm base layer" has no 'a'.
                // Last item: "and a hat".
                
                // Let's follow the prompt's rhythm rigidly.
                // 1. Capitalize first letter of whole sentence.
                // 2. Comma separation.
                // 3. Last item gets "and".
                // 4. Articles?
                // The prompt has "gloves" (plural) and "a hat" (singular).
                // "Heavier winter coat" (singular, no article).
                // "warm base layer" (singular, no article).
                
                // Heuristic:
                // Plural items: gloves, waterproof boots, shoes.
                // Singular items: coat, jacket, hat, scarf, umbrella, shirt, sweater.
                
                var part = name
                let isPlural = name.hasSuffix("s") || name.hasSuffix("gloves") // primitive check
                
                if index == validItems.count - 1 {
                     // Last item
                     if !isPlural {
                         part = "a \(name)"
                     }
                     // Add "and"
                     // We assemble later.
                } else {
                    // Not last
                    // Prompt example doesn't put 'a' for first two.
                    // But "a hat" at then end.
                    // This creates a list style: "Item A, Item B, and a Item C."
                }
                
                resultParts.append(part)
            }
            
            // Construct string
            var sentence = ""
            for (i, part) in resultParts.enumerated() {
                if i == 0 {
                    sentence += part.prefix(1).capitalized + part.dropFirst()
                } else if i == resultParts.count - 1 {
                    sentence += ", and \(part)"
                } else {
                    sentence += ", \(part)"
                }
            }
            return sentence + "."
        }
    }
}
