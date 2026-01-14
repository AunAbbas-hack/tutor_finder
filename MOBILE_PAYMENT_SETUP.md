# Mobile Payment Backend Setup Guide

## ⚠️ Problem

Mobile device par `localhost:3000` kaam nahi karta kyunki `localhost` mobile device ko refer karta hai, backend server ko nahi.

## ✅ Solutions

### Option 1: Ngrok (Local Testing - Recommended)

Ngrok se local backend ko publicly accessible banana:

1. **Ngrok Download:**
   - https://ngrok.com/download
   - Ya: `choco install ngrok` (Windows)

2. **Backend Server Start:**
   ```bash
   cd backend
   npm start
   ```

3. **Ngrok Start:**
   ```bash
   ngrok http 3000
   ```

4. **Forwarding URL Copy:**
   - Ngrok console mein URL milega: `https://xxxx-xxxx.ngrok-free.app`
   - Is URL ko copy karein

5. **`.env` File Update:**
   ```env
   PAYMENT_BACKEND_URL=https://xxxx-xxxx.ngrok-free.app
   ```

6. **App Restart:**
   - Flutter app restart karein
   - Payment ab kaam karega!

**Note:** Ngrok free tier mein har restart par URL change hota hai. Production ke liye Option 2 use karein.

---

### Option 2: Local Network IP (Same WiFi)

Agar mobile aur computer same WiFi par hain:

1. **Computer IP Address Find:**
   - Windows: `ipconfig` (PowerShell mein)
   - Look for "IPv4 Address" (e.g., `192.168.1.100`)

2. **Backend Server Start:**
   ```bash
   cd backend
   npm start
   ```

3. **Firewall Check:**
   - Windows Firewall mein port 3000 allow karein
   - Ya temporarily firewall disable karein (testing ke liye)

4. **`.env` File Update:**
   ```env
   PAYMENT_BACKEND_URL=http://192.168.1.100:3000
   ```
   (Apna actual IP address use karein)

5. **App Restart:**
   - Flutter app restart karein

**Limitations:**
- Sirf same WiFi par kaam karta hai
- IP address change ho sakta hai

---

### Option 3: Render.com (Production - Recommended)

Best option for production. See `RENDER_DEPLOYMENT_GUIDE.md` for complete guide.

Quick steps:
1. Backend ko Render.com par deploy karein
2. Render se URL mil jayega (e.g., `https://your-app.onrender.com`)
3. `.env` file mein add karein:
   ```env
   PAYMENT_BACKEND_URL=https://your-app.onrender.com
   ```

**Benefits:**
- Always accessible
- HTTPS support
- Production-ready
- Free tier available

---

## 📝 Current Setup

Agar `.env` file mein `PAYMENT_BACKEND_URL` nahi hai:

1. `.env` file open karein
2. Add karein:
   ```env
   PAYMENT_BACKEND_URL=https://your-backend-url.com
   ```

3. App restart karein

---

## 🔍 Debugging

Agar error aa raha hai:

1. **Check Backend Running:**
   ```bash
   cd backend
   npm start
   ```
   Server `http://localhost:3000` par start hona chahiye

2. **Check URL in `.env`:**
   - `PAYMENT_BACKEND_URL` correctly set hai?
   - URL mein `http://` ya `https://` prefix hai?

3. **Check Network:**
   - Mobile aur computer same WiFi par hain?
   - Firewall block nahi kar raha?

4. **Check Logs:**
   - Backend server logs check karein
   - Flutter app console logs check karein

---

## ✅ Quick Test

1. Backend URL test karein browser mein:
   ```
   http://your-backend-url/health
   ```
   Response: `{"status":"ok","message":"Server is running"}`

2. Agar browser mein kaam karta hai, to app mein bhi kaam karega

---

**Recommendation:** Production ke liye Render.com use karein (Option 3). Local testing ke liye ngrok use karein (Option 1).
