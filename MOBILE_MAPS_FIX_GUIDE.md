# Mobile Maps Fix Guide
## Maps Blank/Red Icon Issue on Android/iOS

### ❌ Problem:
- Mobile build mein maps blank screen dikhata hai
- Sirf red location icon dikhata hai
- Web (localhost) par maps sahi kaam karte hain
- Har jagah jahan location use ho rahi hai, yahi issue hai

---

## 🔍 Root Cause:
Yeh issue Google Maps API key configuration se related hai:
1. **API Key Restrictions** - API key mein package name/bundle ID restrictions hain
2. **Maps SDK Not Enabled** - Maps SDK for Android/iOS enable nahi hai
3. **Billing Not Enabled** - Google Cloud Console mein billing enable nahi hai
4. **API Key Not Matching** - API key package name/bundle ID se match nahi kar rahi

---

## ✅ Solutions:

### **Solution 1: Check Google Cloud Console - API Key Configuration**

#### Step 1: Google Cloud Console mein jayein
- https://console.cloud.google.com/apis/credentials
- Project: `tutor-finder-0468` select karein

#### Step 2: Android API Key Check
**API Key:** `AIzaSyA2ebsMRA8YTeMmV9_OR3pQTKy1JcoQBug`
**Package Name:** `com.aunxbscs.tutor_finder`

1. API Key ko edit karein
2. **Application restrictions** check karein:
   - **Option A (Recommended for Production):** "Android apps" select karein
     - Package name: `com.aunxbscs.tutor_finder`
     - SHA-1 certificate fingerprint add karein (debug ke liye)
   - **Option B (For Testing):** "None" select karein (temporarily)

3. **API restrictions** check karein:
   - Ensure yeh APIs enabled hain:
     - ✅ Maps SDK for Android
     - ✅ Maps SDK for iOS (agar iOS key hai)
   - Ya "Don't restrict key" select karein (testing ke liye)

#### Step 3: iOS API Key Check
**API Key:** `AIzaSyBRdpt-CA5VhjTkIggIXlavuGT0yfkrJuQ`
**Bundle ID:** `com.aunxbscs.tutorFinder`

1. API Key ko edit karein
2. **Application restrictions:**
   - **Option A:** "iOS apps" select karein
     - Bundle ID: `com.aunxbscs.tutorFinder`
   - **Option B:** "None" select karein (testing ke liye)

---

### **Solution 2: Enable Maps SDKs**

1. Google Cloud Console → APIs & Services → Library
2. Enable karein:
   - **Maps SDK for Android**: https://console.cloud.google.com/apis/library/maps-android-backend.googleapis.com
   - **Maps SDK for iOS**: https://console.cloud.google.com/apis/library/maps-ios-backend.googleapis.com
3. Enable button click karein

---

### **Solution 3: Check Billing**

1. Google Cloud Console → Billing: https://console.cloud.google.com/billing
2. Project: `tutor-finder-0468` select karein
3. Ensure billing account attached hai
4. **Note:** Google Maps free tier mein bhi billing account required hota hai

---

### **Solution 4: Get SHA-1 Fingerprint (Android Debug Build)**

Debug build ke liye SHA-1 fingerprint add karna zaroori hai:

#### Windows:
```bash
cd android
gradlew signingReport
```

Ya:
```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

#### Mac/Linux:
```bash
cd android
./gradlew signingReport
```

Ya:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

SHA-1 fingerprint ko copy karein aur Google Cloud Console mein API key restrictions mein add karein.

---

### **Solution 5: Verify Package Name/Bundle ID**

#### Android:
**File:** `android/app/build.gradle.kts`
**Line 27:** `applicationId = "com.aunxbscs.tutor_finder"`

Ensure yeh package name Google Cloud Console mein API key restrictions mein exact match karta hai.

#### iOS:
**File:** `ios/Runner/Info.plist`
**Bundle ID:** Check `ios/Runner.xcodeproj/project.pbxproj` ya Xcode mein

Ensure Bundle ID: `com.aunxbscs.tutorFinder` Google Cloud Console mein match karta hai.

---

## 🐛 Debugging Steps:

### Android Debug Logs:
1. Device/Emulator connect karein
2. Run: `flutter run`
3. Logcat check karein:
   ```bash
   flutter logs
   ```
4. Look for errors like:
   - "Google Maps API key not found"
   - "Authentication failed"
   - "API key restricted"

### iOS Debug Logs:
1. Xcode mein project open karein
2. Run karein
3. Console check karein for errors

---

## 📝 Current Configuration:

### Android:
- **API Key:** `AIzaSyA2ebsMRA8YTeMmV9_OR3pQTKy1JcoQBug`
- **Package Name:** `com.aunxbscs.tutor_finder`
- **File:** `android/app/src/main/AndroidManifest.xml` (Line 51-52)

### iOS:
- **API Key:** `AIzaSyBRdpt-CA5VhjTkIggIXlavuGT0yfkrJuQ`
- **Bundle ID:** `com.aunxbscs.tutorFinder`
- **File:** `ios/Runner/Info.plist` (Line 56-57)

---

## ✅ Verification Checklist:

### Google Cloud Console:
- [ ] Billing account attached to project
- [ ] Maps SDK for Android enabled
- [ ] Maps SDK for iOS enabled
- [ ] API key restrictions properly configured
- [ ] SHA-1 fingerprint added (Android debug)
- [ ] Package name matches API key restrictions
- [ ] Bundle ID matches API key restrictions (iOS)

### Code Configuration:
- [ ] Android API key in AndroidManifest.xml
- [ ] iOS API key in Info.plist
- [ ] Package name matches in build.gradle.kts
- [ ] Bundle ID matches in Xcode project

### Testing:
- [ ] Clean build: `flutter clean`
- [ ] Rebuild: `flutter build apk` / `flutter build ios`
- [ ] Test on device/emulator
- [ ] Check logs for errors

---

## 🔧 Quick Fix (For Testing Only):

Agar aap testing kar rahe hain aur jaldi fix chahiye:

1. **Google Cloud Console → APIs & Credentials**
2. API Key edit karein
3. **Application restrictions:** "None" select karein (temporarily)
4. **API restrictions:** "Don't restrict key" select karein (temporarily)
5. **Save** karein
6. App rebuild karein
7. Test karein

**⚠️ Warning:** Production mein yeh settings use mat karein - security risk hai!

---

## 🚀 After Fixing:

Agar sab kuch sahi configure hai, to:
- Maps properly load honge
- Red icon ki jagah actual map dikhega
- Zoom/Scroll kaam karega
- Markers properly show honge

---

## 📞 Common Errors:

### Error: "Google Maps API key not found"
- **Solution:** AndroidManifest.xml ya Info.plist mein API key check karein

### Error: "Authentication failed"
- **Solution:** API key restrictions check karein - package name/bundle ID match karein

### Error: "API key restricted"
- **Solution:** Google Cloud Console mein API key restrictions remove karein (testing) ya properly configure karein

### Maps SDK not enabled
- **Solution:** Google Cloud Console → APIs & Services → Library → Enable Maps SDKs

---

## 🎯 Recommended Production Setup:

1. **Separate API Keys:**
   - Android production key (with package name restriction)
   - iOS production key (with bundle ID restriction)
   - Web key (with HTTP referrer restriction)

2. **API Restrictions:**
   - Only required APIs enable karein
   - Application restrictions properly set karein

3. **Billing:**
   - Billing account attached
   - Usage monitoring enabled
