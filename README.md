# WeatherAppX

WeatherAppX is an iOS weather app built with SwiftUI.
I am actively developing a clothing advice algorithm that turns live weather data into practical outfit recommendations.

## What this project does
- Shows current weather and forecast data.
- Provides weather-aware clothing guidance based on temperature, wind, humidity, and precipitation.
- Includes widget support and shared weather logic in `WeatherCore`.

## Clothing Advice Algorithm (in progress)
Current recommendation logic is in:
- `WeatherAppX/OutfitRecommendationEngine.swift`
- `WeatherCore/Sources/WeatherCore/AdviceEngine.swift`

The algorithm currently uses:
- `feelsLike` temperature thresholds for base outfit suggestions.
- Wind checks to suggest extra wind protection.
- Precipitation checks for umbrella/waterproof items.
- Humidity checks for breathable or moisture-wicking clothing.
- User profile modifiers (such as cold sensitivity and commute time) to personalize recommendations.

This part of the app is still being improved for better personalization and clearer explanations.

## Project structure
- `WeatherAppX/`: main app target and SwiftUI views.
- `WeatherCore/`: shared weather and advice engine logic.
- `WeatherWidget/`: widget extension code.
- `WeatherApp/`: additional app module/prototype code.

## Run locally
1. Open the Xcode project at `WeatherAppX/WeatherAppX.xcodeproj`.
2. Select the `WeatherAppX` scheme.
3. Build and run on simulator or device.

## Status
This is an active development project. Feedback on the outfit recommendation behavior is welcome.
