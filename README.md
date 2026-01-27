# Tutor Finder App

Flutter-based mobile application for connecting tutors with students.

## 📋 Table of Contents

- [Prerequisites](#-prerequisites)
- [Clone Project Steps](#-clone-project-steps)
- [Firebase Configuration Setup](#-firebase-configuration-setup)
- [Running the App](#-running-the-app)
- [Troubleshooting](#-troubleshooting)

## 🚀 Getting Started

### Prerequisites

Pehle yeh software install karo:

- **Git** - [Download Git](https://git-scm.com/downloads)
- **Flutter SDK** (latest stable version) - [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Dart SDK** (Flutter ke saath automatically aata hai)
- **Android Studio** (Android development ke liye) - [Download Android Studio](https://developer.android.com/studio)
- **VS Code** (optional, recommended) - [Download VS Code](https://code.visualstudio.com/)
- **Firebase Account** - [Firebase Console](https://console.firebase.google.com/)
- **Node.js** (backend ke liye, agar use ho raha ho) - [Download Node.js](https://nodejs.org/)

### ✅ Prerequisites Check

Terminal/Command Prompt mein yeh commands run karke verify karo:

```bash
# Git check
git --version

# Flutter check
flutter --version

# Dart check
dart --version

# Node.js check (agar backend use ho raha ho)
node --version
npm --version
```

## 📦 Clone Project Steps

### Step 1: Repository Clone Karo

**Windows (PowerShell/Command Prompt):**
```bash
# GitHub repository clone karo
git clone <YOUR_REPOSITORY_URL>

# Project folder mein jao
cd "Tutor Finder Aun"
```

**Example:**
```bash
git clone https://github.com/yourusername/tutor-finder-app.git
cd "Tutor Finder Aun"
```

**Mac/Linux:**
```bash
git clone <YOUR_REPOSITORY_URL>
cd "Tutor Finder Aun"
```

### Step 2: Flutter Dependencies Install Karo

```bash
# Flutter packages install karo
flutter pub get
```

**Note:** Agar koi error aaye to:
```bash
# Flutter clean karo
flutter clean

# Phir dependencies install karo
flutter pub get
```

### Step 3: Backend Dependencies Install Karo (Optional)

Agar project mein Node.js backend ho to:

```bash
# Backend folder mein jao
cd backend

# NPM packages install karo
npm install

# Wapas root folder mein jao
cd ..
```

### Step 4: Flutter Doctor Check Karo

Flutter setup verify karne ke liye:

```bash
flutter doctor
```

Yeh command batayega ke kya kya properly install hai aur kya missing hai.

**Important:** Agar koi issue ho to pehle usko fix karo, phir aage badho.

### Step 5: Missing Files Check Karo

Clone ke baad yeh files missing hongi (yeh normal hai, kyunki sensitive hain):

- ❌ `android/app/google-services.json`
- ❌ `ios/Runner/GoogleService-Info.plist`
- ❌ `macos/Runner/GoogleService-Info.plist`
- ❌ `lib/firebase_options.dart`
- ❌ `assets/service_account.json`
- ❌ `android/local.properties` (yeh automatically generate hogi)

**Ab aage Firebase configuration setup karo (next section mein).**

### 🔐 Firebase Configuration Setup

**⚠️ IMPORTANT:** Ye project Firebase use karta hai. Clone ke baad aapko manually Firebase configuration files add karni hongi. Bina in files ke app run nahi hoga.

#### Method 1: FlutterFire CLI Use Karna (Recommended - Easiest Way)

**Step 1: FlutterFire CLI Install Karo**

```bash
dart pub global activate flutterfire_cli
```

**Step 2: Firebase Login Karo**

```bash
firebase login
```

**Step 3: Firebase Project Configure Karo**

```bash
flutterfire configure
```

Yeh command:
- Aapko Firebase project select karne dega
- Automatically sab platforms ke liye configuration files generate karega
- `lib/firebase_options.dart` automatically create ho jayega

**Step 4: Service Account Key Add Karo (Backend ke liye)**

1. [Firebase Console](https://console.firebase.google.com/) mein jao
2. Apna project select karo
3. **Project Settings** > **Service Accounts** tab mein jao
4. **"Generate new private key"** button click karo
5. Download ki hui JSON file ko `assets/service_account.json` mein save karo

```bash
# Example file copy karo (agar manually banana ho)
# Windows:
copy assets\service_account.json.example assets\service_account.json

# Mac/Linux:
cp assets/service_account.json.example assets/service_account.json
```

Phir downloaded service account JSON file ko `assets/service_account.json` mein replace karo.

---

#### Method 2: Manual Setup (FlutterFire CLI nahi use karna ho to)

**Step 1: Firebase Console se Files Download Karo**

1. [Firebase Console](https://console.firebase.google.com/) mein jao
2. Apna project select karo (ya naya project banao)
3. **Project Settings** (⚙️ icon) click karo
4. **"Your apps"** section mein jao
5. Har platform ke liye app add karo (agar nahi hai to):
   - Android app add karo
   - iOS app add karo
   - Web app add karo (agar web support chahiye)

**Step 2: Configuration Files Download Karo**

Har platform ke liye configuration file download karo:

- **Android:** `google-services.json` download karo
- **iOS:** `GoogleService-Info.plist` download karo
- **Web:** Web app configuration details note karo

**Step 3: Files Project Mein Add Karo**

**Android Configuration:**

**Windows:**
```bash
# Example file copy karo
copy android\app\google-services.json.example android\app\google-services.json
```

**Mac/Linux:**
```bash
cp android/app/google-services.json.example android/app/google-services.json
```

Phir downloaded `google-services.json` file ko `android/app/google-services.json` mein replace karo.

**iOS Configuration:**

**Windows:**
```bash
copy ios\Runner\GoogleService-Info.plist.example ios\Runner\GoogleService-Info.plist
```

**Mac/Linux:**
```bash
cp ios/Runner/GoogleService-Info.plist.example ios/Runner/GoogleService-Info.plist
```

Phir downloaded `GoogleService-Info.plist` file ko `ios/Runner/GoogleService-Info.plist` mein replace karo.

**macOS Configuration (agar macOS development karni ho):**

**Windows:**
```bash
copy macos\Runner\GoogleService-Info.plist.example macos\Runner\GoogleService-Info.plist
```

**Mac/Linux:**
```bash
cp macos/Runner/GoogleService-Info.plist.example macos/Runner/GoogleService-Info.plist
```

Phir downloaded `GoogleService-Info.plist` file ko `macos/Runner/GoogleService-Info.plist` mein replace karo.

**Flutter Firebase Options:**

**Windows:**
```bash
copy lib\firebase_options.dart.example lib\firebase_options.dart
```

**Mac/Linux:**
```bash
cp lib/firebase_options.dart.example lib/firebase_options.dart
```

Phir `lib/firebase_options.dart` file ko manually edit karo aur Firebase Console se mili hui values se replace karo:
- `apiKey`
- `appId`
- `messagingSenderId`
- `projectId`
- `authDomain` (web ke liye)
- `databaseURL`
- `storageBucket`
- `measurementId` (web ke liye)

**Service Account (Backend ke liye):**

1. Firebase Console > Project Settings > Service Accounts
2. **"Generate new private key"** click karo
3. Download ki hui JSON file ko `assets/service_account.json` mein save karo

**Windows:**
```bash
copy assets\service_account.json.example assets\service_account.json
```

**Mac/Linux:**
```bash
cp assets/service_account.json.example assets/service_account.json
```

Phir downloaded service account JSON file ko `assets/service_account.json` mein replace karo.

### ⚙️ Additional Setup

**Android Local Properties:**
- `android/local.properties` file automatically generate hoti hai build time par
- Agar manually banana ho to (Android Studio first time open karne par automatically ban jati hai):

**Windows:**
```properties
sdk.dir=C:\\Users\\YOUR_USERNAME\\AppData\\Local\\Android\\sdk
flutter.sdk=C:\\path\\to\\flutter
```

**Mac/Linux:**
```properties
sdk.dir=/Users/YOUR_USERNAME/Library/Android/sdk
flutter.sdk=/path/to/flutter
```

**Note:** Usually yeh file automatically ban jati hai, manually banana ki zarurat nahi hoti.

### ✅ Setup Verification

Sab kuch setup hone ke baad verify karo:

```bash
# Flutter doctor check
flutter doctor

# Dependencies verify karo
flutter pub get

# Build check (agar Android device/emulator connected ho)
flutter build apk --debug
```

### 🏃 Running the App

**Step 1: Device/Emulator Ready Karo**

**Android:**
- Android Studio mein emulator start karo, ya
- Physical Android device USB se connect karo (USB debugging enable karo)

**iOS (Mac only):**
- Xcode simulator start karo, ya
- Physical iOS device connect karo

**Step 2: Connected Devices Check Karo**

```bash
flutter devices
```

Yeh command dikhayega ke kaunse devices available hain.

**Step 3: App Run Karo**

**Development Mode (Debug):**
```bash
flutter run
```

**Specific Device Select Karke:**
```bash
flutter run -d <device-id>
```

**Release Mode (Production Build):**
```bash
# Android APK build
flutter build apk

# Android App Bundle (Play Store ke liye)
flutter build appbundle

# iOS build (Mac only)
flutter build ios
```

**Hot Reload:**
- App run karte waqt `r` press karo hot reload ke liye
- `R` press karo hot restart ke liye
- `q` press karo app band karne ke liye

### 📝 Important Notes

#### 🔒 Security & Sensitive Files

**Sensitive Files (GitHub par nahi jati):**
Ye files `.gitignore` mein ignore hain, isliye GitHub par upload nahi hoti:
- ❌ `android/app/google-services.json`
- ❌ `ios/Runner/GoogleService-Info.plist`
- ❌ `macos/Runner/GoogleService-Info.plist`
- ❌ `lib/firebase_options.dart`
- ❌ `assets/service_account.json`
- ❌ `android/local.properties`

**Example Files (GitHub par available hain):**
- ✅ `android/app/google-services.json.example`
- ✅ `ios/Runner/GoogleService-Info.plist.example`
- ✅ `macos/Runner/GoogleService-Info.plist.example`
- ✅ `lib/firebase_options.dart.example`
- ✅ `assets/service_account.json.example`

**Firebase Security Best Practices:**
1. 🔐 Firebase API keys ko Firebase Console mein restrict karo (domain/IP restrictions)
2. 🔐 Firebase Security Rules properly configure karo
3. 🔐 Service account key ko bilkul private rakho - yeh sabse sensitive file hai
4. 🔐 API keys ko kabhi bhi publicly share mat karo
5. 🔐 Production aur development ke liye alag Firebase projects use karo

#### 📱 Platform-Specific Notes

**Android:**
- Minimum SDK version check karo `android/app/build.gradle` mein
- Google Play Services required hain
- `google-services.json` file `android/app/` folder mein honi chahiye

**iOS:**
- Xcode 12+ required hai
- CocoaPods install hona chahiye: `sudo gem install cocoapods`
- `GoogleService-Info.plist` file `ios/Runner/` folder mein honi chahiye
- iOS deployment target check karo

**Web:**
- Web support ke liye Firebase Web configuration required hai
- `firebase_options.dart` mein web configuration honi chahiye

### 🛠️ Troubleshooting

#### Common Issues aur Solutions:

**❌ Issue: "Firebase initialization error" ya "Missing Firebase configuration"**

**Solution:**
1. Check karo ke sab configuration files properly add ki hain:
   - `android/app/google-services.json` (Android ke liye)
   - `ios/Runner/GoogleService-Info.plist` (iOS ke liye)
   - `lib/firebase_options.dart` (Flutter ke liye)
2. Firebase project settings verify karo
3. Firebase project ID sahi hai ya nahi check karo
4. Files ke paths sahi hain ya nahi verify karo

**❌ Issue: "Build errors" ya "Gradle build failed"**

**Solution:**
```bash
# Flutter clean karo
flutter clean

# Dependencies phir se install karo
flutter pub get

# Android build cache clear karo
cd android
./gradlew clean
cd ..

# Phir build try karo
flutter build apk
```

**❌ Issue: "Package not found" ya "Dependencies error"**

**Solution:**
```bash
# Pub cache clear karo
flutter pub cache repair

# Dependencies phir se install karo
flutter pub get
```

**❌ Issue: "No devices found"**

**Solution:**
1. Android: Android Studio mein emulator start karo
2. USB Debugging enable karo (physical device ke liye)
3. `flutter devices` command se devices check karo
4. Device properly connected hai ya nahi verify karo

**❌ Issue: "Service account file not found"**

**Solution:**
1. `assets/service_account.json` file exist karti hai ya nahi check karo
2. File path sahi hai ya nahi verify karo
3. Agar file missing hai to Firebase Console se download karo

**❌ Issue: "local.properties missing" (Android)**

**Solution:**
- Usually yeh file automatically ban jati hai
- Agar nahi bani to Android Studio project ko open karo, automatically ban jayegi
- Ya manually create karo (see Additional Setup section)

**❌ Issue: "Permission denied" errors**

**Solution:**
- File permissions check karo
- Windows: Administrator mode mein terminal run karo
- Mac/Linux: `sudo` use karo (agar zarurat ho)

**❌ Issue: "Flutter version mismatch"**

**Solution:**
```bash
# Flutter version check karo
flutter --version

# Flutter upgrade karo
flutter upgrade

# Phir dependencies install karo
flutter pub get
```

**Agar koi aur issue ho to:**
1. `flutter doctor -v` run karo detailed info ke liye
2. Error message properly read karo
3. GitHub issues check karo
4. Flutter documentation refer karo

### 📚 Project Structure

```
lib/
├── views/          # UI screens
├── data/           # Data models and services
├── utils/          # Utility functions
└── main.dart       # App entry point

assets/
└── service_account.json  # Firebase service account (not in git)

android/
└── app/
    └── google-services.json  # Firebase Android config (not in git)

ios/
└── Runner/
    └── GoogleService-Info.plist  # Firebase iOS config (not in git)
```

### 📚 Quick Reference Commands

```bash
# Project clone karna
git clone <repository-url>
cd "Tutor Finder Aun"

# Dependencies install
flutter pub get

# Firebase configure (easiest way)
flutterfire configure

# App run karna
flutter run

# Build karna
flutter build apk        # Android APK
flutter build appbundle  # Android App Bundle
flutter build ios        # iOS (Mac only)

# Clean karna
flutter clean
flutter pub get

# Devices check karna
flutter devices

# Flutter doctor (setup check)
flutter doctor
flutter doctor -v  # Detailed info
```

### 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### 📞 Support

Agar koi issue ho ya help chahiye:
1. README ka Troubleshooting section check karo
2. GitHub Issues mein search karo
3. Maintainer se contact karo

### 📄 License

[Add your license here]

---

## ✅ Setup Checklist

Clone ke baad yeh checklist follow karo:

- [ ] Git repository clone ho gaya
- [ ] Flutter dependencies install ho gaye (`flutter pub get`)
- [ ] Backend dependencies install ho gaye (agar use ho raha ho)
- [ ] Firebase project setup ho gaya
- [ ] `android/app/google-services.json` file add ki
- [ ] `ios/Runner/GoogleService-Info.plist` file add ki (agar iOS develop karna ho)
- [ ] `lib/firebase_options.dart` file add ki
- [ ] `assets/service_account.json` file add ki (agar backend use ho raha ho)
- [ ] `flutter doctor` se setup verify kiya
- [ ] App successfully run ho raha hai

**Note:** Agar koi file missing ho ya setup mein issue ho to README ka Troubleshooting section check karo ya maintainer se contact karo.
