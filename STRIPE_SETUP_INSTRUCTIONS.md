# Stripe Integration Setup Instructions

## ✅ Implementation Complete!

Stripe payment integration successfully implement ho chuka hai. Ab setup karein:

---

## 🔧 Step 1: Backend Server Setup

### 1.1 Backend Folder mein Dependencies Install Karein

```bash
cd backend
npm install
```

### 1.2 Environment Variables Setup

`backend/.env` file create karein:

```env
STRIPE_SECRET_KEY=sk_test_your_secret_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here
APP_URL=http://localhost:5000
PORT=3000
```

**Stripe Keys Kahan Se Lein:**
1. [Stripe Dashboard](https://dashboard.stripe.com/test/apikeys) → Test Mode ON
2. **Secret Key** copy karein → `STRIPE_SECRET_KEY` mein paste karein
3. Webhook secret baad mein add karenge (Step 4 mein)

### 1.3 Backend Server Run Karein

```bash
npm start
# Ya development mode ke liye:
npm run dev
```

Server `http://localhost:3000` par run hoga.

---

## 📱 Step 2: Flutter App Configuration

### 2.1 Environment Variable Add Karein

`.env` file (project root mein) mein add karein:

```env
PAYMENT_BACKEND_URL=http://localhost:3000
```

**Production mein:**
```env
PAYMENT_BACKEND_URL=https://your-backend-url.com
```

### 2.2 Verify Dependencies

`pubspec.yaml` mein yeh packages already hain:
- ✅ `http: ^1.2.2`
- ✅ `url_launcher: ^6.3.2` (already hai)
- ✅ `flutter_dotenv: ^5.1.0` (already hai)

---

## 🌐 Step 3: Backend Server Deploy (Production)

Aap backend server ko deploy kar sakte hain:

### Option A: Railway (Recommended - Easy)
1. [Railway.app](https://railway.app) account banayein
2. GitHub repo connect karein
3. `backend` folder select karein
4. Environment variables add karein
5. Deploy!

### Option B: Render
1. [Render.com](https://render.com) account banayein
2. New Web Service
3. `backend/server.js` set karein
4. Environment variables add karein
5. Deploy!

### Option C: Heroku
```bash
cd backend
heroku create your-app-name
heroku config:set STRIPE_SECRET_KEY=sk_test_...
git push heroku main
```

### Option D: Vercel / Netlify Functions
Serverless functions use kar sakte hain.

---

## 🔔 Step 4: Webhook Setup

### 4.1 Stripe Dashboard mein Webhook Add Karein

1. [Stripe Dashboard](https://dashboard.stripe.com/test/webhooks) → Webhooks
2. "Add endpoint" click karein
3. Endpoint URL: `https://your-backend-url.com/api/stripe-webhook`
4. Events select karein:
   - `checkout.session.completed`
   - `checkout.session.async_payment_succeeded`
   - `checkout.session.async_payment_failed`
5. **Signing secret** copy karein
6. Backend `.env` file mein add karein: `STRIPE_WEBHOOK_SECRET=whsec_...`

### 4.2 Webhook Testing (Local)

Stripe CLI install karein:

```bash
# Windows: Download from GitHub
# Mac: brew install stripe/stripe-cli/stripe

stripe login
stripe listen --forward-to localhost:3000/api/stripe-webhook
```

Yeh aapko webhook secret dega local testing ke liye.

---

## 🧪 Step 5: Testing

### 5.1 Backend Server Test

```bash
curl http://localhost:3000/health
# Response: {"status":"ok","message":"Server is running"}
```

### 5.2 Stripe Test Cards

```
Card: 4242 4242 4242 4242
Expiry: Any future date (e.g., 12/25)
CVC: Any 3 digits (e.g., 123)
```

### 5.3 Test Flow

1. ✅ App run karein
2. ✅ Booking create karein
3. ✅ Payment button click karein
4. ✅ Stripe payment page khulna chahiye
5. ✅ Test card se payment complete karein
6. ✅ Success page par redirect hona chahiye

---

## 🔄 Payment Flow

```
1. User Booking Create Karta Hai
   ↓
2. Booking Firestore mein Save Hota Hai (pending status)
   ↓
3. Backend se Stripe Checkout Session Create Hota Hai
   ↓
4. User Stripe Payment Page par Redirect Hota Hai
   ↓
5. User Payment Complete Karta Hai
   ↓
6. Stripe Webhook Backend ko Notify Karta Hai
   ↓
7. Booking Status Update Hona Chahiye (manual implementation chahiye)
```

---

## ⚠️ Important Notes

### Webhook Implementation

Abhi webhook endpoint backend mein hai, lekin Firestore update nahi ho raha automatically. Aapko manually implement karna hoga:

**Option 1: Firebase Admin SDK Backend mein**
- Backend server mein Firebase Admin SDK add karein
- Webhook mein Firestore update karein

**Option 2: Flutter App se Check**
- Payment success page par booking status check karein
- Ya polling use karein payment status check karne ke liye

**Option 3: Simple Approach (Current)**
- Webhook backend mein log karein
- Manually booking update karein (ya baad mein implement karein)

---

## 📝 Files Created/Modified

### Backend:
- ✅ `backend/server.js` - Stripe Checkout Session endpoint
- ✅ `backend/package.json` - Dependencies
- ✅ `backend/.env.example` - Environment variables template
- ✅ `backend/README.md` - Backend documentation

### Flutter:
- ✅ `lib/data/services/payment_service.dart` - Payment service
- ✅ `lib/parent_viewmodels/request_booking_vm.dart` - Payment integration

---

## 🚀 Production Checklist

- [ ] Backend server deploy kiya
- [ ] Production Stripe keys configure kiye (Live Mode)
- [ ] Webhook endpoint production URL set kiya
- [ ] Environment variables production values set kiye
- [ ] HTTPS enabled (stripe requirement)
- [ ] Error logging setup kiya
- [ ] Payment success/cancel pages tested

---

## 🆘 Troubleshooting

### Issue: "Payment redirect failed"
- ✅ Backend server running hai check karein
- ✅ `PAYMENT_BACKEND_URL` correctly set hai check karein
- ✅ Backend logs check karein

### Issue: "CORS Error"
- ✅ Backend mein CORS enabled hai (already configured)
- ✅ Backend URL correct hai verify karein

### Issue: "Webhook not working"
- ✅ Webhook URL publicly accessible hai check karein
- ✅ Webhook secret correct hai verify karein
- ✅ Stripe CLI se local testing karein

---

## 📞 Support

Agar koi issue aaye:
1. Backend server logs check karein
2. Flutter console logs check karein
3. Stripe Dashboard → Logs check karein

---

**Setup Complete! Ab test karein! 🎉**
