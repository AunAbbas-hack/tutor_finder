# Render.com Deployment Guide - Complete

Yeh guide aapko Render.com par backend deploy karne mein help karega.

---

## ✅ Security - Secret Keys Kahan Add Karenge?

**Haan, secret keys Render.com par environment variables ke through add karein. Yeh bilkul secure hai:**

- ✅ Environment variables encrypted hote hain
- ✅ Code mein visible nahi hoti
- ✅ Sirf backend server access kar sakta hai
- ✅ GitHub repo mein nahi jayegi (secure)

---

## 📋 Prerequisites (Pehle Ye Chahiye)

1. ✅ GitHub account
2. ✅ Render.com account (free)
3. ✅ Stripe account (test keys)
4. ✅ Backend code ready

---

## 🚀 Step 1: GitHub Par Code Push Karein

Agar aapka code GitHub par nahi hai:

### 1.1 Git Initialize (Agar nahi hai)

```bash
# Project root folder mein
git init
git add .
git commit -m "Initial commit"
```

### 1.2 GitHub Repository Create Karein

1. GitHub.com par login karein
2. "New repository" click karein
3. Repository name: `tutor-finder-backend` (ya koi bhi naam)
4. Public ya Private select karein
5. "Create repository" click karein

### 1.3 Code Push Karein

```bash
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git branch -M main
git push -u origin main
```

**Important:** `.env` file ko `.gitignore` mein add karein (secret keys GitHub par nahi jayengi)

---

## 🌐 Step 2: Render.com Account Create Karein

1. https://render.com par jayein
2. "Get Started for Free" click karein
3. GitHub account se sign up karein (recommended)
   - Ya email se sign up karein
4. Email verify karein

---

## 🔧 Step 3: Render.com Par Web Service Create Karein

### 3.1 New Web Service

1. Render dashboard mein "New +" button click karein
2. "Web Service" select karein

### 3.2 GitHub Repository Connect Karein

1. "Connect account" click karein (agar pehle se connect nahi hai)
2. GitHub account authorize karein
3. Repository select karein (tutor-finder-backend)

### 3.3 Service Configuration

**Basic Settings:**
- **Name:** `tutor-finder-payment-backend` (ya koi bhi naam)
- **Region:** Singapore (Asia ke liye fastest) ya closest region
- **Branch:** `main` (ya aapki main branch)

**Build & Deploy Settings:**
- **Root Directory:** `backend` ⚠️ IMPORTANT - Yeh backend folder ka path hai
- **Environment:** `Node`
- **Build Command:** `npm install`
- **Start Command:** `npm start`

**Advanced Settings (Optional):**
- **Auto-Deploy:** `Yes` (code push par automatically deploy hoga)

---

## 🔐 Step 4: Environment Variables Add Karein

Render dashboard mein "Environment" section mein yeh variables add karein:

### Required Environment Variables:

1. **STRIPE_SECRET_KEY**
   - Value: `sk_test_...` (Stripe Dashboard se)
   - Stripe Dashboard → Developers → API keys → Secret key copy karein

2. **STRIPE_WEBHOOK_SECRET** (Optional - webhook setup ke baad)
   - Value: `whsec_...` (Webhook setup ke baad milega)
   - Pehle deploy karein, baad mein webhook add karenge

3. **APP_URL** (Important!)
   - Value: Render ne jo URL diya hai (deploy ke baad milega)
   - Format: `https://your-service-name.onrender.com`
   - Pehle deploy karein, URL milne ke baad update karenge

4. **PORT** (Optional)
   - Render automatically `PORT` environment variable set karta hai
   - Aapko manually add karne ki zarurat nahi

5. **GOOGLE_APPLICATION_CREDENTIALS** (Optional - Firebase Admin SDK ke liye)
   - Agar Firebase Admin SDK use karna hai
   - Service account JSON file path ya JSON content

### Environment Variables Kaise Add Karenge:

1. Render dashboard → Aapki service → "Environment" tab
2. "Add Environment Variable" click karein
3. Key aur Value add karein
4. "Save Changes" click karein
5. Service automatically redeploy hoga

---

## 📝 Step 5: First Deployment

### 5.1 Deploy Start Karein

1. Saari settings complete karein
2. "Create Web Service" click karein
3. Render automatically build start karega

### 5.2 Deployment Process

Render automatically:
- ✅ Dependencies install karega (`npm install`)
- ✅ Code build karega
- ✅ Server start karega
- ✅ URL generate karega

### 5.3 Deployment URL Milne Ke Baad

1. Service dashboard mein URL mil jayega
2. Format: `https://tutor-finder-payment-backend.onrender.com`
3. Is URL ko copy karein

### 5.4 APP_URL Update Karein

1. "Environment" tab mein jayein
2. `APP_URL` variable update karein:
   - Value: `https://tutor-finder-payment-backend.onrender.com` (apna actual URL)
3. "Save Changes" click karein
4. Service redeploy hoga

---

## ✅ Step 6: Deployment Verify Karein

### 6.1 Health Check

Browser mein yeh URL open karein:
```
https://your-service-name.onrender.com/health
```

Expected Response:
```json
{
  "status": "ok",
  "message": "Server is running"
}
```

### 6.2 Logs Check Karein

1. Render dashboard → "Logs" tab
2. Check karein ke server start ho gaya
3. Agar error hai, logs mein dikhega

---

## 🔔 Step 7: Stripe Webhook Setup

### 7.1 Webhook URL

Aapka webhook URL hoga:
```
https://your-service-name.onrender.com/api/stripe-webhook
```

### 7.2 Stripe Dashboard Mein Webhook Add Karein

1. Stripe Dashboard → Developers → Webhooks
2. "Add endpoint" click karein
3. Endpoint URL: `https://your-service-name.onrender.com/api/stripe-webhook`
4. Events select karein:
   - `checkout.session.completed`
   - `checkout.session.async_payment_succeeded`
   - `checkout.session.async_payment_failed`
5. "Add endpoint" click karein

### 7.3 Webhook Secret Copy Karein

1. Webhook endpoint create hone ke baad
2. "Signing secret" click karein (Reveal button)
3. Secret copy karein (starts with `whsec_...`)

### 7.4 Render Mein Webhook Secret Add Karein

1. Render dashboard → Environment variables
2. Add karein:
   - Key: `STRIPE_WEBHOOK_SECRET`
   - Value: `whsec_...` (jo abhi copy kiya)
3. Save karein (service redeploy hoga)

---

## 📱 Step 8: Flutter App Mein Backend URL Update Karein

### 8.1 Root `.env` File Mein

Project root folder mein `.env` file update karein:

```env
PAYMENT_BACKEND_URL=https://your-service-name.onrender.com
```

**Important:** `.env` file ko `.gitignore` mein add karein (security ke liye)

---

## ⚠️ Important Notes

### Free Tier Limitations:

1. **Sleep Mode:**
   - Free tier 15 minutes inactivity ke baad sleep mode mein chala jata hai
   - First request thoda slow hoga (wake up time)
   - Baad ki requests fast hongi

2. **Solution (Optional):**
   - Paid plan lein ($7/month - always on)
   - Ya uptime monitoring service use karein (ping every 10 minutes)

### Security Best Practices:

1. ✅ **Never commit `.env` file** to GitHub
2. ✅ **Environment variables** use karein (code mein hardcode nahi)
3. ✅ **Stripe keys** secure rakhein
4. ✅ **Webhook secret** safely store karein

---

## 🧪 Testing

### 1. Health Check Test

```bash
curl https://your-service-name.onrender.com/health
```

Expected: `{"status":"ok","message":"Server is running"}`

### 2. Payment Test

1. Flutter app run karein
2. Booking create karein
3. Payment button click karein
4. Stripe payment page khulna chahiye

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
- ✅ PORT variable automatically set hota hai (manual add nahi karna)

### Issue: Webhook Not Working

**Check:**
- ✅ Webhook URL publicly accessible hai?
- ✅ `STRIPE_WEBHOOK_SECRET` correctly set hai?
- ✅ Stripe Dashboard mein webhook endpoint active hai?
- ✅ Logs check karein webhook events ke liye

### Issue: Payment Not Working

**Check:**
- ✅ `PAYMENT_BACKEND_URL` Flutter app `.env` mein correctly set hai?
- ✅ Backend server running hai (health check)?
- ✅ Stripe keys correctly set hain?
- ✅ Network connectivity check karein

---

## 📊 Deployment Checklist

- [ ] GitHub repo create kiya
- [ ] Code GitHub par push kiya
- [ ] Render.com account create kiya
- [ ] Web Service create kiya
- [ ] Root Directory: `backend` set kiya
- [ ] Environment variables add kiye:
  - [ ] STRIPE_SECRET_KEY
  - [ ] APP_URL (deploy ke baad update kiya)
  - [ ] STRIPE_WEBHOOK_SECRET (webhook setup ke baad)
- [ ] Deployment successful
- [ ] Health check pass
- [ ] Stripe webhook setup kiya
- [ ] Flutter app `.env` update kiya
- [ ] Payment test kiya

---

## 🎉 Success!

Agar sab kuch theek se setup ho gaya:

1. ✅ Backend Render.com par running hai
2. ✅ Payments Stripe ke through process ho rahi hain
3. ✅ Webhooks Firestore mein payments save kar rahe hain
4. ✅ Mobile app se payments kaam kar rahi hain

---

## 📞 Support

Agar koi issue aaye:
1. Render dashboard → Logs check karein
2. Stripe Dashboard → Webhooks → Logs check karein
3. Flutter app console logs check karein

---

**Deployment Complete! 🚀**
