# Render.com Deployment - Quick Steps (Urdu/Hindi)

Yeh guide Render.com par backend deploy karne ke liye hai.

---

## 🎯 Quick Overview

1. GitHub par code push karein
2. Render.com par account create karein
3. Web Service create karein
4. Environment variables add karein
5. Deploy karein
6. Flutter app mein URL add karein

---

## 📝 Step-by-Step Guide

### Step 1: GitHub Par Code Push Karein (Agar nahi hai)

Agar aapka code GitHub par already hai, to step 2 par jayein.

```bash
# Project root folder mein
git init
git add .
git commit -m "Initial commit"

# GitHub par repository create karein (github.com par)
# Phir yeh commands run karein:
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git branch -M main
git push -u origin main
```

---

### Step 2: Render.com Account Create Karein

1. **https://render.com** par jayein
2. **"Get Started for Free"** click karein
3. **GitHub account se sign up karein** (recommended)
   - Ya email se sign up karein
4. Email verify karein

---

### Step 3: Render.com Par Web Service Create Karein

#### 3.1 New Web Service

1. Render dashboard mein **"New +"** button click karein
2. **"Web Service"** select karein

#### 3.2 GitHub Repository Connect Karein

1. **"Connect account"** click karein (agar pehle se connect nahi hai)
2. GitHub account authorize karein
3. **Repository select karein** (aapki repository)

#### 3.3 Service Configuration

**Basic Settings:**
- **Name:** `tutor-finder-payment-backend` (ya koi bhi naam)
- **Region:** `Singapore` (Asia ke liye fastest) ya closest region
- **Branch:** `main`

**Build & Deploy Settings:**
- **Root Directory:** `backend` ⚠️ **IMPORTANT** - Yeh backend folder ka path hai
- **Environment:** `Node`
- **Build Command:** `npm install`
- **Start Command:** `npm start`

**Advanced Settings:**
- **Auto-Deploy:** `Yes` (code push par automatically deploy hoga)

---

### Step 4: Environment Variables Add Karein

Render dashboard mein **"Environment"** section mein yeh variables add karein:

#### Required Variables:

1. **STRIPE_SECRET_KEY**
   - Stripe Dashboard → Developers → API keys → Secret key copy karein
   - Format: `sk_test_...` (test mode) ya `sk_live_...` (production)

2. **APP_URL** (Deploy ke baad update karenge)
   - Pehle deploy karein
   - Render ne jo URL diya, wo copy karein
   - Format: `https://your-service-name.onrender.com`
   - Environment variables mein add/update karein

#### Optional Variables:

3. **STRIPE_WEBHOOK_SECRET** (Webhook setup ke baad)
   - Pehle deploy karein, phir webhook setup karenge

4. **FIREBASE_SERVICE_ACCOUNT** (Agar Firebase use karna hai)
   - Service account JSON content (optional)

#### Environment Variables Kaise Add Karenge:

1. Render dashboard → Aapki service → **"Environment"** tab
2. **"Add Environment Variable"** click karein
3. **Key** aur **Value** add karein
4. **"Save Changes"** click karein
5. Service automatically redeploy hoga

---

### Step 5: First Deployment

#### 5.1 Deploy Start Karein

1. Saari settings complete karein
2. **"Create Web Service"** click karein
3. Render automatically build start karega

#### 5.2 Deployment Process

Render automatically:
- ✅ Dependencies install karega
- ✅ Code build karega
- ✅ Server start karega
- ✅ URL generate karega (kuch minutes lagega)

#### 5.3 Deployment URL Milne Ke Baad

1. Service dashboard mein **URL mil jayega**
2. Format: `https://tutor-finder-payment-backend.onrender.com`
3. Is URL ko **copy karein**

#### 5.4 APP_URL Update Karein

1. **"Environment"** tab mein jayein
2. `APP_URL` variable add/update karein:
   - Key: `APP_URL`
   - Value: `https://your-service-name.onrender.com` (apna actual URL)
3. **"Save Changes"** click karein
4. Service redeploy hoga

---

### Step 6: Deployment Verify Karein

#### 6.1 Health Check

Browser mein yeh URL open karein:
```
https://your-service-name.onrender.com/health
```

**Expected Response:**
```json
{
  "status": "ok",
  "message": "Server is running"
}
```

Agar yeh response aaye, to server successfully deploy ho gaya! ✅

#### 6.2 Logs Check Karein

1. Render dashboard → **"Logs"** tab
2. Check karein ke server start ho gaya
3. Agar error hai, logs mein dikhega

---

### Step 7: Flutter App Mein Backend URL Add Karein

#### 7.1 Root `.env` File Create/Update Karein

Project **root folder** mein `.env` file create karein (agar nahi hai):

```env
PAYMENT_BACKEND_URL=https://your-service-name.onrender.com
```

**Example:**
```env
PAYMENT_BACKEND_URL=https://tutor-finder-payment-backend.onrender.com
```

#### 7.2 Important Notes

- ✅ `.env` file **root folder** mein honi chahiye (project root)
- ✅ URL mein `https://` zaroor hona chahiye
- ✅ URL ke end mein `/` nahi hona chahiye
- ✅ `.env` file already `.gitignore` mein hai (secure)

---

### Step 8: App Test Karein

1. **Flutter app run karein**
2. **Booking create karein**
3. **Pay Now button click karein**
4. **Stripe payment page khulna chahiye** ✅

---

## ⚠️ Important Notes

### Free Tier Limitations:

1. **Sleep Mode:**
   - Free tier **15 minutes inactivity** ke baad sleep mode mein chala jata hai
   - First request thoda slow hoga (wake up time ~30 seconds)
   - Baad ki requests fast hongi

2. **Solution (Optional):**
   - Paid plan lein ($7/month - always on)
   - Ya uptime monitoring service use karein

### Security:

- ✅ **Never commit `.env` file** to GitHub (already in `.gitignore`)
- ✅ **Environment variables** use karein (code mein hardcode nahi)
- ✅ **Stripe keys** secure rakhein

---

## 🧪 Testing Checklist

- [ ] Render dashboard mein service running hai
- [ ] Health check pass ho raha hai (`/health` endpoint)
- [ ] Logs mein koi error nahi hai
- [ ] Flutter app `.env` file mein URL correctly set hai
- [ ] Payment button click karne par Stripe page khul raha hai

---

## 🔍 Troubleshooting

### Issue: Deployment Failed

**Check:**
- ✅ Root Directory: `backend` correctly set hai?
- ✅ Build Command: `npm install` correct hai?
- ✅ Start Command: `npm start` correct hai?
- ✅ Logs check karein error message ke liye

### Issue: Server Not Starting

**Check:**
- ✅ `package.json` mein `start` script hai?
- ✅ Environment variables correctly set hain?
- ✅ `STRIPE_SECRET_KEY` set hai?

### Issue: Payment Not Working

**Check:**
- ✅ `PAYMENT_BACKEND_URL` Flutter app `.env` mein correctly set hai?
- ✅ Backend server running hai (health check)?
- ✅ Stripe keys correctly set hain?
- ✅ URL format correct hai? (`https://` se start hona chahiye)

---

## 📋 Complete Checklist

- [ ] GitHub repo create kiya
- [ ] Code GitHub par push kiya
- [ ] Render.com account create kiya
- [ ] Web Service create kiya
- [ ] Root Directory: `backend` set kiya
- [ ] Environment variables add kiye:
  - [ ] STRIPE_SECRET_KEY
  - [ ] APP_URL (deploy ke baad update kiya)
- [ ] Deployment successful
- [ ] Health check pass (`/health` endpoint)
- [ ] Flutter app `.env` file create/update kiya
- [ ] PAYMENT_BACKEND_URL correctly set kiya
- [ ] Payment test kiya

---

## 🎉 Success!

Agar sab kuch theek se setup ho gaya:

1. ✅ Backend Render.com par running hai
2. ✅ Payments Stripe ke through process ho rahi hain
3. ✅ Mobile app se payments kaam kar rahi hain

---

## 📞 Help

Agar koi issue aaye:
1. Render dashboard → **Logs** check karein
2. Health check URL try karein
3. Flutter app console logs check karein

---

**Deployment Complete! 🚀**

---

## 📚 Additional Resources

- Complete detailed guide: `RENDER_DEPLOYMENT_GUIDE.md`
- Backend README: `backend/README.md`
- Webhook setup: `backend/WEBHOOK_SETUP.md`
