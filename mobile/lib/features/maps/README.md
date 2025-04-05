# Hospital Map Feature

This feature provides an interactive map interface for users to find nearby hospitals in the MediLeger app.

## Features

- Display hospitals on an interactive Google Map
- Search for locations
- Get current user location
- Adjust search radius
- View hospital details including:
  - Name
  - Distance
  - Reputation score
  - Contact information
  - Wallet address
- Get directions to hospitals
- Check hospital medicine stock

## Setup Requirements

### API Key Configuration

#### Android

1. Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Open `android/app/src/main/AndroidManifest.xml`
3. Replace `YOUR_GOOGLE_MAPS_API_KEY` with your actual API key

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY" />
```

#### iOS

1. Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Open `ios/Runner/AppDelegate.swift`
3. Add the following code:

```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## Implementation Details

The maps feature uses:

- Google Maps Flutter plugin for the map implementation
- Geolocator for accessing device location
- Geocoding for searching locations
- Hospital API from the backend to fetch nearby hospitals
- Riverpod for state management

## Data Flow

1. User opens the map screen
2. App requests location permissions (if not already granted)
3. App fetches user's current location
4. App makes API call to `/hospitals/nearby/{lat}/{lng}/{distance}` to get hospitals
5. Map displays markers for each hospital
6. User can tap on hospital markers to see details
7. User can change search radius to find more or fewer hospitals
8. User can search for different locations
