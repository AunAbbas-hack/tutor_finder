# Backend Server Quick Start

## ⚠️ Important: Backend Server MUST be Running!

Payment feature ke liye backend server **zaroori** hai. Agar backend server running nahi hai, to payment kaam nahi karega.

---

## 🚀 Backend Start Karna

### Step 1: Backend Folder Mein Jao

```bash
cd backend
```

### Step 2: Dependencies Install (Pehli baar hi)

```bash
npm install
```

### Step 3: Environment Variables Setup

`.env` file create karein (agar nahi hai):

```env
STRIPE_SECRET_KEY=sk_test_your_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here
APP_URL=http://localhost:3000
PORT=3000
```

### Step 4: Server Start

```bash
npm start
```

**Expected Output:**
```
Server running on http://localhost:3000
```

---

## ✅ Verify Server Running

Browser mein open karein:
```
http://localhost:3000/health
```

Response:
```json
{"status":"ok","message":"Server is running"}
```

Agar yeh response aaye, to server running hai! ✅

---

## 📱 Mobile Testing Setup

### Option 1: Local Network IP (Same WiFi)

1. **Backend Server Start:**
   ```bash
   cd backend
   npm start
   ```

2. **Computer IP Address:**
   - Windows: `ipconfig`
   - Look for IPv4 Address (e.g., `192.168.100.23`)

3. **`.env` File Update (Project Root):**
   ```env
   PAYMENT_BACKEND_URL=http://192.168.100.23:3000
   ```

4. **Flutter App Restart:**
   - Hot restart ya full restart

5. **Firewall Check:**
   - Windows Firewall mein port 3000 allow karein
   - Ya temporarily disable karein (testing ke liye)

---

### Option 2: Ngrok (Recommended for Testing)

1. **Ngrok Install:**
   - https://ngrok.com/download

2. **Backend Start:**
   ```bash
   cd backend
   npm start
   ```

3. **Ngrok Start (New Terminal):**
   ```bash
   ngrok http 3000
   ```

4. **URL Copy:**
   - Ngrok console se URL copy karein (e.g., `https://xxxx-xxxx.ngrok-free.app`)

5. **`.env` File Update:**
   ```env
   PAYMENT_BACKEND_URL=https://xxxx-xxxx.ngrok-free.app
   ```

6. **App Restart**

---

## 🔍 Troubleshooting

### Error: "Please check your internet connection"

**Causes:**
1. ❌ Backend server running nahi hai
2. ❌ `.env` file mein `PAYMENT_BACKEND_URL` set nahi hai
3. ❌ Wrong URL (localhost on mobile)
4. ❌ Firewall blocking
5. ❌ Mobile aur computer different WiFi par

**Solutions:**
1. ✅ Backend server start karein (`npm start` in backend folder)
2. ✅ `.env` file check karein - `PAYMENT_BACKEND_URL` correctly set hai?
3. ✅ Mobile par localhost use mat karein - IP address ya ngrok URL use karein
4. ✅ Firewall check karein
5. ✅ Same WiFi par connect karein

---

## 📝 Quick Checklist

- [ ] Backend server running hai (`npm start` in backend folder)
- [ ] Server health check pass (`http://localhost:3000/health`)
- [ ] `.env` file mein `PAYMENT_BACKEND_URL` set hai
- [ ] Mobile testing: IP address ya ngrok URL use kiya
- [ ] Flutter app restart kiya (hot restart se kaam nahi karega)
- [ ] Same WiFi par connect hain (agar IP address use kar rahe hain)

---

## 🎯 Current Setup

Your IP Address: `192.168.100.23`

For Mobile Testing, `.env` file should have:
```env
PAYMENT_BACKEND_URL=http://192.168.100.23:3000
```

**Important:** Backend server running hona chahiye! ✅
