# Directions API Setup Guide

Yeh guide aapko Google Directions API setup karne mein help karega.

---

## 📋 Step 1: Google Cloud Console Setup

### 1.1 Enable Directions API

1. **Google Cloud Console** mein jao:
   - https://console.cloud.google.com/

2. **Project Select Karein:**
   - Apna project select karein (e.g., `tutor-finder-0468`)

3. **APIs & Services → Library:**
   - Left sidebar se "APIs & Services" → "Library" par click karein

4. **Directions API Search Karein:**
   - Search bar mein "Directions API" type karein
   - "Directions API" select karein

5. **Enable Button Click Karein:**
   - "Enable" button par click karein

✅ **Directions API enable ho gaya!**

---

### 1.2 API Key Create Karein (Agar Already Nahi Hai)

1. **APIs & Services → Credentials:**
   - Left sidebar se "APIs & Services" → "Credentials" par click karein

2. **Create Credentials → API Key:**
   - "+ CREATE CREDENTIALS" button par click karein
   - "API key" select karein

3. **API Key Copy Karein:**
   - API key generate ho jayega
   - **IMPORTANT:** API key copy karein (yeh baad mein nahi milega)

4. **API Key Restrictions (Optional but Recommended):**
   - API key par click karein (edit mode)
   - **Application restrictions:**
     - Android apps: Apna Android package name add karein
     - iOS apps: Apna iOS bundle ID add karein
   - **API restrictions:**
     - "Restrict key" select karein
     - "Directions API" aur "Maps SDK for Android" aur "Maps SDK for iOS" select karein
   - "Save" click karein

---

## 📝 Step 2: .env File Mein API Key Add Karein

### 2.1 .env File Ka Location

Aapka `.env` file project root directory mein hona chahiye:
```
Tutor Finder Aun/
├── .env                    ← YAHAN
├── lib/
├── android/
├── ios/
└── ...
```

### 2.2 .env File Mein API Key Paste Karein

Agar `.env` file nahi hai, to pehle create karein. Agar hai, to is line ko add/update karein:

```env
GOOGLE_MAPS_API_KEY=YOUR_API_KEY_HERE
```

**Example:**
```env
GOOGLE_MAPS_API_KEY=AIzaSyD3drczRNnaKA95wt9kqfBh1OLFIDsNg2I
```

⚠️ **Important:**
- `YOUR_API_KEY_HERE` ko apni actual API key se replace karein
- Quotes (`"`) use mat karein
- Equal sign (`=`) ke baad space nahi hona chahiye

---

## ✅ Step 3: Verification

### 3.1 Code Check

Code already setup hai:
- ✅ `lib/data/services/directions_service.dart` - Directions service created
- ✅ `lib/parent_viewmodels/booking_view_detail_vm.dart` - ViewModel updated
- ✅ `lib/views/parent/booking_view_detail_screen.dart` - UI updated

### 3.2 Test Karein

1. **App Run Karein:**
   ```bash
   flutter run
   ```

2. **Booking Detail Screen Par Jao:**
   - Koi booking open karein jismein:
     - Parent location hai
     - Tutor location hai

3. **Map Check Karein:**
   - Map mein route (blue line) dikhni chahiye
   - Parent location: Green marker
   - Tutor location: Blue marker

---

## 🐛 Troubleshooting

### Error: "GOOGLE_MAPS_API_KEY not found in .env file"

**Solution:**
1. `.env` file check karein ki project root mein hai
2. API key correctly paste kiya hai
3. App restart karein (hot reload nahi, full restart)

### Error: "Directions API request timeout"

**Solution:**
1. Internet connection check karein
2. Directions API enable hai ki nahi check karein
3. API key restrictions check karein

### Error: "Directions Service Error: Status=REQUEST_DENIED"

**Solution:**
1. Directions API enable karein (Step 1.1)
2. API key restrictions check karein
3. Billing enable karein (agar free tier exceed ho gaya ho)

### Route Nahi Dikha

**Solution:**
1. Parent location check karein (UserModel mein latitude/longitude)
2. Tutor location check karein (UserModel mein latitude/longitude)
3. Debug logs check karein:
   ```dart
   if (kDebugMode) {
     print('Parent: ${vm.parentLatitude}, ${vm.parentLongitude}');
     print('Tutor: ${vm.tutorLatitude}, ${vm.tutorLongitude}');
   }
   ```

---

## 💰 Pricing

### Free Tier:
- **$200 free credit per month** (Google Cloud Console)
- **Directions API:** $5 per 1,000 requests
- Free tier mein approximately **40,000 requests/month** free

### Cost Estimation:
- Agar aapke app mein **100 bookings per day** hain
- To **3,000 requests/month** (approximately)
- Cost: **$15/month** (but free tier se cover ho jayega)

---

## 📝 Complete .env File Example

Agar aapka `.env` file already hai, to bas `GOOGLE_MAPS_API_KEY` add karein:

```env
# Existing variables (agar hain)
PAYMENT_BACKEND_URL=https://your-backend-url.com
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

# Add this line:
GOOGLE_MAPS_API_KEY=AIzaSyD3drczRNnaKA95wt9kqfBh1OLFIDsNg2I
```

---

## 🎯 Summary

1. ✅ **Directions API Enable Karein** (Google Cloud Console)
2. ✅ **API Key Create/Use Karein** (agar already nahi hai)
3. ✅ **.env File Mein API Key Add Karein:**
   ```
   GOOGLE_MAPS_API_KEY=YOUR_API_KEY_HERE
   ```
4. ✅ **App Restart Karein**
5. ✅ **Test Karein** (Booking Detail Screen)

---

**Setup Complete!** 🎉

Agar koi problem ho, to debug logs check karein ya error message share karein.
