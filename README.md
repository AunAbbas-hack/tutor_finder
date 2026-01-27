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

Install the following software first:

- **Git** - [Download Git](https://git-scm.com/downloads)
- **Flutter SDK** (latest stable version) - [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Dart SDK** (comes automatically with Flutter)
- **Android Studio** (for Android development) - [Download Android Studio](https://developer.android.com/studio)
- **VS Code** (optional, recommended) - [Download VS Code](https://code.visualstudio.com/)
- **Firebase Account** - [Firebase Console](https://console.firebase.google.com/)
- **Node.js** (for backend, if being used) - [Download Node.js](https://nodejs.org/)

### ✅ Prerequisites Check

Run these commands in Terminal/Command Prompt to verify:

```bash
# Git check
git --version

# Flutter check
flutter --version

# Dart check
dart --version

# Node.js check (if backend is being used)
node --version
npm --version
```

## 📦 Clone Project Steps

### Step 1: Clone the Repository

**Windows (PowerShell/Command Prompt):**
```bash
# Clone GitHub repository
git clone <YOUR_REPOSITORY_URL>

# Navigate to project folder
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

### Step 2: Install Flutter Dependencies

```bash
# Install Flutter packages
flutter pub get
```

**Note:** If you encounter any errors:
```bash
# Clean Flutter
flutter clean

# Then install dependencies again
flutter pub get
```

### Step 3: Install Backend Dependencies (Optional)

If the project has a Node.js backend:

```bash
# Navigate to backend folder
cd backend

# Install NPM packages
npm install

# Return to root folder
cd ..
```

### Step 4: Run Flutter Doctor Check

To verify Flutter setup:

```bash
flutter doctor
```

This command will show what is properly installed and what is missing.

**Important:** If there are any issues, fix them first before proceeding.

### Step 5: Check for Missing Files

After cloning, these files will be missing (this is normal, as they are sensitive):

- ❌ `android/app/google-services.json`
- ❌ `ios/Runner/GoogleService-Info.plist`
- ❌ `macos/Runner/GoogleService-Info.plist`
- ❌ `lib/firebase_options.dart`
- ❌ `assets/service_account.json`
- ❌ `android/local.properties` (this will be generated automatically)

**Now proceed with Firebase configuration setup (in the next section).**

### 🔐 Firebase Configuration Setup

**⚠️ IMPORTANT:** This project uses Firebase. After cloning, you need to manually add Firebase configuration files. The app will not run without these files.

#### Method 1: Using FlutterFire CLI (Recommended - Easiest Way)

**Step 1: Install FlutterFire CLI**

```bash
dart pub global activate flutterfire_cli
```

**Step 2: Login to Firebase**

```bash
firebase login
```

**Step 3: Configure Firebase Project**

```bash
flutterfire configure
```

This command will:
- Let you select your Firebase project
- Automatically generate configuration files for all platforms
- Automatically create `lib/firebase_options.dart`

**Step 4: Add Service Account Key (For Backend)**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** > **Service Accounts** tab
4. Click **"Generate new private key"** button
5. Save the downloaded JSON file as `assets/service_account.json`

```bash
# Copy example file (if creating manually)
# Windows:
copy assets\service_account.json.example assets\service_account.json

# Mac/Linux:
cp assets/service_account.json.example assets/service_account.json
```

Then replace the content in `assets/service_account.json` with the downloaded service account JSON file.

---

#### Method 2: Manual Setup (If you don't want to use FlutterFire CLI)

**Step 1: Download Files from Firebase Console**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create a new one)
3. Click **Project Settings** (⚙️ icon)
4. Go to **"Your apps"** section
5. Add app for each platform (if not already added):
   - Add Android app
   - Add iOS app
   - Add Web app (if web support is needed)

**Step 2: Download Configuration Files**

Download configuration file for each platform:

- **Android:** Download `google-services.json`
- **iOS:** Download `GoogleService-Info.plist`
- **Web:** Note down web app configuration details

**Step 3: Add Files to Project**

**Android Configuration:**

**Windows:**
```bash
# Copy example file
copy android\app\google-services.json.example android\app\google-services.json
```

**Mac/Linux:**
```bash
cp android/app/google-services.json.example android/app/google-services.json
```

Then replace the content in `android/app/google-services.json` with the downloaded `google-services.json` file.

**iOS Configuration:**

**Windows:**
```bash
copy ios\Runner\GoogleService-Info.plist.example ios\Runner\GoogleService-Info.plist
```

**Mac/Linux:**
```bash
cp ios/Runner/GoogleService-Info.plist.example ios/Runner/GoogleService-Info.plist
```

Then replace the content in `ios/Runner/GoogleService-Info.plist` with the downloaded `GoogleService-Info.plist` file.

**macOS Configuration (if developing for macOS):**

**Windows:**
```bash
copy macos\Runner\GoogleService-Info.plist.example macos\Runner\GoogleService-Info.plist
```

**Mac/Linux:**
```bash
cp macos/Runner/GoogleService-Info.plist.example macos/Runner/GoogleService-Info.plist
```

Then replace the content in `macos/Runner/GoogleService-Info.plist` with the downloaded `GoogleService-Info.plist` file.

**Flutter Firebase Options:**

**Windows:**
```bash
copy lib\firebase_options.dart.example lib\firebase_options.dart
```

**Mac/Linux:**
```bash
cp lib/firebase_options.dart.example lib/firebase_options.dart
```

Then manually edit `lib/firebase_options.dart` file and replace values with those from Firebase Console:
- `apiKey`
- `appId`
- `messagingSenderId`
- `projectId`
- `authDomain` (for web)
- `databaseURL`
- `storageBucket`
- `measurementId` (for web)

**Service Account (For Backend):**

1. Firebase Console > Project Settings > Service Accounts
2. Click **"Generate new private key"**
3. Save the downloaded JSON file as `assets/service_account.json`

**Windows:**
```bash
copy assets\service_account.json.example assets\service_account.json
```

**Mac/Linux:**
```bash
cp assets/service_account.json.example assets/service_account.json
```

Then replace the content in `assets/service_account.json` with the downloaded service account JSON file.

### ⚙️ Additional Setup

**Android Local Properties:**
- `android/local.properties` file is automatically generated at build time
- If you need to create it manually (Android Studio creates it automatically when you open the project for the first time):

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

**Note:** Usually this file is created automatically, you don't need to create it manually.

### ✅ Setup Verification

After everything is set up, verify:

```bash
# Flutter doctor check
flutter doctor

# Verify dependencies
flutter pub get

# Build check (if Android device/emulator is connected)
flutter build apk --debug
```

### 🏃 Running the App

**Step 1: Prepare Device/Emulator**

**Android:**
- Start emulator in Android Studio, or
- Connect physical Android device via USB (enable USB debugging)

**iOS (Mac only):**
- Start Xcode simulator, or
- Connect physical iOS device

**Step 2: Check Connected Devices**

```bash
flutter devices
```

This command will show which devices are available.

**Step 3: Run the App**

**Development Mode (Debug):**
```bash
flutter run
```

**Select Specific Device:**
```bash
flutter run -d <device-id>
```

**Release Mode (Production Build):**
```bash
# Android APK build
flutter build apk

# Android App Bundle (for Play Store)
flutter build appbundle

# iOS build (Mac only)
flutter build ios
```

**Hot Reload:**
- While app is running, press `r` for hot reload
- Press `R` for hot restart
- Press `q` to quit the app

### 📝 Important Notes

#### 🔒 Security & Sensitive Files

**Sensitive Files (Not uploaded to GitHub):**
These files are ignored in `.gitignore`, so they are not uploaded to GitHub:
- ❌ `android/app/google-services.json`
- ❌ `ios/Runner/GoogleService-Info.plist`
- ❌ `macos/Runner/GoogleService-Info.plist`
- ❌ `lib/firebase_options.dart`
- ❌ `assets/service_account.json`
- ❌ `android/local.properties`

**Example Files (Available on GitHub):**
- ✅ `android/app/google-services.json.example`
- ✅ `ios/Runner/GoogleService-Info.plist.example`
- ✅ `macos/Runner/GoogleService-Info.plist.example`
- ✅ `lib/firebase_options.dart.example`
- ✅ `assets/service_account.json.example`

**Firebase Security Best Practices:**
1. 🔐 Restrict Firebase API keys in Firebase Console (domain/IP restrictions)
2. 🔐 Properly configure Firebase Security Rules
3. 🔐 Keep service account key completely private - this is the most sensitive file
4. 🔐 Never publicly share API keys
5. 🔐 Use separate Firebase projects for production and development

#### 📱 Platform-Specific Notes

**Android:**
- Check minimum SDK version in `android/app/build.gradle`
- Google Play Services are required
- `google-services.json` file should be in `android/app/` folder

**iOS:**
- Xcode 12+ is required
- CocoaPods should be installed: `sudo gem install cocoapods`
- `GoogleService-Info.plist` file should be in `ios/Runner/` folder
- Check iOS deployment target

**Web:**
- Firebase Web configuration is required for web support
- Web configuration should be in `firebase_options.dart`

### 🛠️ Troubleshooting

#### Common Issues and Solutions:

**❌ Issue: "Firebase initialization error" or "Missing Firebase configuration"**

**Solution:**
1. Check that all configuration files are properly added:
   - `android/app/google-services.json` (for Android)
   - `ios/Runner/GoogleService-Info.plist` (for iOS)
   - `lib/firebase_options.dart` (for Flutter)
2. Verify Firebase project settings
3. Check if Firebase project ID is correct
4. Verify file paths are correct

**❌ Issue: "Build errors" or "Gradle build failed"**

**Solution:**
```bash
# Clean Flutter
flutter clean

# Reinstall dependencies
flutter pub get

# Clear Android build cache
cd android
./gradlew clean
cd ..

# Then try building again
flutter build apk
```

**❌ Issue: "Package not found" or "Dependencies error"**

**Solution:**
```bash
# Clear pub cache
flutter pub cache repair

# Reinstall dependencies
flutter pub get
```

**❌ Issue: "No devices found"**

**Solution:**
1. Android: Start emulator in Android Studio
2. Enable USB Debugging (for physical device)
3. Check devices with `flutter devices` command
4. Verify device is properly connected

**❌ Issue: "Service account file not found"**

**Solution:**
1. Check if `assets/service_account.json` file exists
2. Verify file path is correct
3. If file is missing, download it from Firebase Console

**❌ Issue: "local.properties missing" (Android)**

**Solution:**
- Usually this file is created automatically
- If not created, open the project in Android Studio, it will be created automatically
- Or create it manually (see Additional Setup section)

**❌ Issue: "Permission denied" errors**

**Solution:**
- Check file permissions
- Windows: Run terminal in Administrator mode
- Mac/Linux: Use `sudo` (if needed)

**❌ Issue: "Flutter version mismatch"**

**Solution:**
```bash
# Check Flutter version
flutter --version

# Upgrade Flutter
flutter upgrade

# Then install dependencies
flutter pub get
```

**If you encounter any other issues:**
1. Run `flutter doctor -v` for detailed information
2. Read error message properly
3. Check GitHub issues
4. Refer to Flutter documentation

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
# Clone project
git clone <repository-url>
cd "Tutor Finder Aun"

# Install dependencies
flutter pub get

# Configure Firebase (easiest way)
flutterfire configure

# Run app
flutter run

# Build
flutter build apk        # Android APK
flutter build appbundle  # Android App Bundle
flutter build ios        # iOS (Mac only)

# Clean
flutter clean
flutter pub get

# Check devices
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

If you encounter any issues or need help:
1. Check the Troubleshooting section in README
2. Search in GitHub Issues
3. Contact the maintainer

### 📄 License

[Add your license here]

---

## ✅ Setup Checklist

Follow this checklist after cloning:

- [ ] Git repository cloned
- [ ] Flutter dependencies installed (`flutter pub get`)
- [ ] Backend dependencies installed (if being used)
- [ ] Firebase project set up
- [ ] `android/app/google-services.json` file added
- [ ] `ios/Runner/GoogleService-Info.plist` file added (if developing for iOS)
- [ ] `lib/firebase_options.dart` file added
- [ ] `assets/service_account.json` file added (if backend is being used)
- [ ] Setup verified with `flutter doctor`
- [ ] App running successfully

**Note:** If any file is missing or you encounter setup issues, check the Troubleshooting section in README or contact the maintainer.
