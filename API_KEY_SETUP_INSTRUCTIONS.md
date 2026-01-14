# API Key Setup Instructions (Kahan Paste Karein)

## 📍 API Key Kahan Add Karein

### Step 1: `.env` File Location

Aapka **`.env` file** project ke **root directory** mein hona chahiye:

```
Tutor Finder Aun/          ← Project root
├── .env                   ← YAHAN API KEY ADD KAREIN
├── lib/
├── android/
├── ios/
├── pubspec.yaml
└── ...
```

---

### Step 2: `.env` File Mein API Key Add Karein

`.env` file open karein aur yeh line add/update karein:

```env
GOOGLE_MAPS_API_KEY=YOUR_API_KEY_HERE
```

**Example:**
```env
GOOGLE_MAPS_API_KEY=AIzaSyD3drczRNnaKA95wt9kqfBh1OLFIDsNg2I
```

⚠️ **Important Points:**
- `YOUR_API_KEY_HERE` ko apni actual Google Maps API key se replace karein
- Quotes (`"` ya `'`) use **MAT** karein
- Equal sign (`=`) ke baad space **NAHI** hona chahiye
- Line ke end mein semicolon (`;`) **NAHI** chahiye

---

### Step 3: API Key Kahan Se Milega

#### Option 1: Agar Aapke Paas Already API Key Hai
- Agar aapke paas already Google Maps API key hai, to bas `.env` file mein add karein

#### Option 2: Naya API Key Create Karein
1. **Google Cloud Console** mein jao: https://console.cloud.google.com/
2. Apna project select karein
3. **APIs & Services** → **Credentials** par jao
4. **+ CREATE CREDENTIALS** → **API key** click karein
5. API key generate ho jayega - isko copy karein
6. `.env` file mein paste karein

---

### Step 4: Directions API Enable Karein (Important!)

API key ke saath-saath **Directions API** bhi enable karna hoga:

1. **Google Cloud Console** mein jao
2. **APIs & Services** → **Library** par jao
3. Search bar mein **"Directions API"** type karein
4. **Directions API** select karein
5. **Enable** button click karein

✅ **Directions API enable ho gaya!**

---

### Step 5: App Restart Karein

⚠️ **Important:** `.env` file update karne ke baad **app ko restart karein** (hot reload nahi, full restart):

```bash
# Stop the app (Ctrl+C)
# Phir se run karein:
flutter run
```

Ya IDE mein:
- **Stop** button click karein
- Phir **Run** button click karein

---

## 📝 Complete Example

Agar aapka `.env` file already hai, to bas yeh line add karein:

```env
# Existing variables (agar hain)
PAYMENT_BACKEND_URL=https://your-backend-url.com
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key

# Add this line (NEW):
GOOGLE_MAPS_API_KEY=AIzaSyD3drczRNnaKA95wt9kqfBh1OLFIDsNg2I
```

Agar `.env` file nahi hai, to naya file create karein:

```env
GOOGLE_MAPS_API_KEY=AIzaSyD3drczRNnaKA95wt9kqfBh1OLFIDsNg2I
```

---

## ✅ Verification

### Check Karein Ki API Key Correct Hai:

1. `.env` file mein API key correctly paste kiya hai
2. Directions API enable kiya hai (Google Cloud Console)
3. App restart kiya hai
4. Booking Detail Screen mein route dikha (blue line on map)

---

## 🐛 Common Errors

### Error: "GOOGLE_MAPS_API_KEY not found in .env file"

**Solution:**
- `.env` file project root mein hai ki nahi check karein
- File name exactly `.env` hona chahiye (not `.env.txt`)
- API key correctly paste kiya hai ki nahi check karein
- App restart karein (not hot reload)

### Error: "Directions API request timeout"

**Solution:**
- Internet connection check karein
- Directions API enable kiya hai ki nahi check karein

### Error: "Directions Service Error: Status=REQUEST_DENIED"

**Solution:**
- Directions API enable karein (Google Cloud Console)
- API key restrictions check karein
- Billing enable karein (agar free tier exceed ho gaya ho)

---

## 📋 Quick Checklist

- [ ] Google Cloud Console mein Directions API enable kiya
- [ ] API key create/use kiya
- [ ] `.env` file project root mein hai
- [ ] `.env` file mein `GOOGLE_MAPS_API_KEY=YOUR_KEY` line add kiya
- [ ] App restart kiya (not hot reload)
- [ ] Booking Detail Screen mein route dikha

---

**Setup Complete!** 🎉

Agar koi problem ho, to `DIRECTIONS_API_SETUP_GUIDE.md` file check karein for detailed instructions.
