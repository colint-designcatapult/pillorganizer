# Deep Link Setup Guide for CabiNET

## Deep Link Format

The app accepts deep links in the following format:

```
cabinet://patient?patientId=123456
```

## Platform Configuration ✅

**Both Android and iOS configurations have been automatically applied:**

### ✅ Android Configuration (Already Applied)

The deep link intent filter has been added to `android/app/src/main/AndroidManifest.xml`:

- Scheme: `cabinet`
- Host: `patient`
- Supports query parameters like `patientId`

### ✅ iOS Configuration (Already Applied)

The URL scheme has been configured in `ios/Runner/Info.plist`:

- Custom URL scheme: `cabinet`
- Bundle URL name: `cabinet.deeplink`

## How It Works

1. **App Launch**: When the app is launched via a deep link with a patient ID, it will:

   - Put the patientId in the deep link provider

2. **Deep Link Handling**: The app uses the `DeepLinkService` to:

   - Listen for incoming deep links while the app is running
   - Extract the `patientId` parameter from the URL
   - Store it in the `DeepLinkProvider` for access throughout the app

3. **Patient ID Access**: You can access the patient ID from anywhere in the app using:
   ```dart
   final deepLinkProvider = Provider.of<DeepLinkProvider>(context);
   String? patientId = deepLinkProvider.patientId;
   ```

## Testing Deep Links

### Android Testing

```bash
# Test via ADB (replace with actual package name)
adb shell am start \
  -W -a android.intent.action.VIEW \
  -d "cabinet://patient?patientId=123456" \
  jct.pillorganizer.pills
```

### iOS Testing

```bash
# Test via Simulator
xcrun simctl openurl booted "cabinet://patient?patientId=123456"
```

### Web Testing (for development)

You can also test the deep link by opening this URL in a browser on a device with the app installed:

```
cabinet://patient?patientId=123456
```

## Notes

- The patient ID persists until the app is restarted or explicitly cleared
- Deep links work both when the app is closed and when it's running in the background
