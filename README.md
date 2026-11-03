# RideApp

iOS ride-sharing app with REST API integration, real-time tracking, and driver/passenger matching.

## Features

- JWT authentication with Keychain storage
- Real-time ride tracking with live location
- Ride history with pagination
- Driver matching and fare estimation
- Offline support with cached data

## Tech Stack

- Swift 5, UIKit (programmatic UI)
- URLSession networking
- CoreData local caching
- Keychain Services

## Setup

git clone the repo, run pod install, open the xcworkspace.

## Testing

Run xcodebuild test with iOS Simulator target.

## Architecture

Lightweight MVC with shared API client singleton. Codable with custom key mapping for snake_case responses.

## License

MIT
