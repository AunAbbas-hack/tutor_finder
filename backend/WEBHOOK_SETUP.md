# Webhook Setup Guide

## Firebase Admin SDK Setup

Webhook Firestore mein payments save karne ke liye Firebase Admin SDK chahiye.

### Option 1: Service Account File (Local Development)

1. `assets/service_account.json` file ko `backend/` folder mein copy karein
2. `backend/server.js` mein uncomment karein:
   ```javascript
   admin.initializeApp({
     credential: admin.credential.cert(require('./service_account.json'))
   });
   ```

### Option 2: Environment Variable (Production - Recommended)

`.env` file mein add karein:
```env
GOOGLE_APPLICATION_CREDENTIALS=./service_account.json
```

Ya service account JSON directly:
```env
FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"..."}
```

### Option 3: No Setup (Webhook won't save to Firestore)

Agar Firebase Admin SDK setup nahi karna, webhook log karega lekin Firestore mein save nahi karega.

## Stripe Webhook Secret

`.env` file mein add karein:
```env
STRIPE_WEBHOOK_SECRET=whsec_...
```

Yeh Stripe Dashboard → Webhooks → Your endpoint → Signing secret se milega.
