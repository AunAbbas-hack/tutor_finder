# Mobile Maps Fix Guide - Maps SDK Not Working

## 🔴 Problem
- Mobile par map show nahi ho raha (blank screen + red location icon)
- API list mein Maps SDK for Android/iOS ka usage nahi dikh raha
- Maps JavaScript API 100% errors show ho rahi hai (yeh web ke liye hai)

## ✅ Solution Steps

### Step 1: Google Cloud Console mein APIs Enable Karein

1. **Google Cloud Console** mein jayein: https://console.cloud.google.com/
2. **Project select karein**: `tutor-finder-0468`
3. **APIs & Services** → **Library** mein jayein
4. **Ye APIs enable karein** (search karke):
   - ✅ **Maps SDK for Android** (Android ke liye)
   - ✅ **Maps SDK for iOS** (iOS ke liye)
   - ✅ **Maps JavaScript API** (Web ke liye - already enabled lag raha hai)
   - ✅ **Geocoding API** (Address search ke liye)
   - ✅ **Places API** (Optional - agar search bar add karna hai)

### Step 2: API Keys Check Karein

#### Android API Key: `AIzaSyA2ebsMRA8YTeMmV9_OR3pQTKy1JcoQBug`
1. **APIs & Services** → **Credentials** mein jayein
2. Is API key ko click karein
3. **API restrictions** check karein:
   - Agar "Restrict key" enabled hai, to ensure ye APIs allowed hain:
     - ✅ Maps SDK for Android
     - ✅ Geocoding API
   - Ya phir "Don't restrict key" select karein (development ke liye)
4. **Application restrictions** check karein:
   - Agar Android app restriction hai, to package name verify karein: `com.aunxbscs.tutor_finder`
   - SHA-1 certificate fingerprint add karein (agar needed ho)

#### iOS API Key: `AIzaSyBRdpt-CA5VhjTkIggIXlavuGT0yfkrJuQ`
1. Same API key ko check karein
2. **API restrictions** mein ensure:
   - ✅ Maps SDK for iOS
   - ✅ Geocoding API
3. **Application restrictions** (agar hai):
   - iOS bundle ID: `com.aunxbscs.tutorFinder`

### Step 3: Billing Verify Karein

1. **Billing** section mein jayein
2. Ensure billing account linked hai
3. **Maps SDK requires billing** - free tier available hai but billing account zaroori hai

### Step 4: SHA-1 Certificate Fingerprint (Android)

Agar API key mein Android app restrictions hain, to SHA-1 add karna hoga:

```bash
# Debug keystore ke liye:
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release keystore ke liye (agar hai):
keytool -list -v -keystore <path-to-release-keystore> -alias <alias-name>
```

SHA-1 fingerprint ko API key ke "Application restrictions" mein add karein.

### Step 5: Code mein Error Handling Add Karein

LocationViewModel mein error handling improve karein taake errors properly log ho.

## 🔍 Debugging Steps

### Android ke liye:
1. **Logcat** check karein:
   ```bash
   flutter run
   # Ya Android Studio mein Logcat tab
   ```
2. Look for errors like:
   - "Google Maps API key not found"
   - "API key not valid"
   - "Billing not enabled"

### iOS ke liye:
1. **Xcode Console** mein errors check karein
2. Look for similar error messages

### Test Karein:
1. App rebuild karein: `flutter clean && flutter pub get`
2. Android: `flutter run`
3. iOS: `flutter run` (ya Xcode se)

## 📝 Current API Keys

- **Android**: `AIzaSyA2ebsMRA8YTeMmV9_OR3pQTKy1JcoQBug`
- **iOS**: `AIzaSyBRdpt-CA5VhjTkIggIXlavuGT0yfkrJuQ`

## ⚠️ Important Notes

1. **Maps SDK for Android** aur **Maps SDK for iOS** alag APIs hain
2. Web ke liye **Maps JavaScript API** use hoti hai (jo already enabled hai)
3. Mobile ke liye **Maps SDK** enable karna zaroori hai
4. API keys ko proper restrictions ke saath configure karein
5. Billing account linked hona zaroori hai

## 🎯 Quick Checklist

- [ ] Maps SDK for Android enabled
- [ ] Maps SDK for iOS enabled  
- [ ] API keys mein proper restrictions set
- [ ] Billing account linked
- [ ] SHA-1 fingerprint added (Android restrictions ke liye)
- [ ] App rebuild kiya
- [ ] Logs check kiye

## 🐛 Common Issues

1. **Blank map with red icon**: API key invalid ya API not enabled
2. **No usage in API list**: API key restrictions too strict
3. **100% errors**: Billing not enabled ya API key wrong
4. **Map loads but no tiles**: Network issue ya API quota exceeded
