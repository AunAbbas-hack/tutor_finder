# Stripe Integration Steps - Complete Guide
## Parent Web App + Mobile App ke liye Payment Implementation

---

## 📋 Overview

Yeh guide aapko Stripe payment system ko apne Tutor Finder app mein implement karne ke liye step-by-step instructions deta hai. Stripe dono platforms (Web aur Mobile) ko support karta hai.

---

## 🎯 Prerequisites (Pehle se Chahiye)

1. **Stripe Account** - [https://dashboard.stripe.com/register](https://dashboard.stripe.com/register) se account banayein
2. **Stripe API Keys** - Dashboard se Test aur Live keys lena hoga
3. **Backend Server** - Payment Intent create karne ke liye (Firebase Functions ya separate Node.js server)
4. **Flutter Development Environment** - Already setup hai

---

## 📦 Step 1: Dependencies Install Karein

### 1.1 Flutter Stripe Package Add Karein

`pubspec.yaml` file mein jaake yeh package add/update karein:

```yaml
dependencies:
  flutter_stripe: ^12.1.1  # Comment hatayein
  http: ^1.2.2  # Already hai, verify karein
```

**Commands:**
```bash
flutter pub get
flutter pub upgrade
```

### 1.2 Platform-Specific Setup

#### Android (`android/app/build.gradle.kts`):
- Min SDK version: 21+ (already check karein)
- Kuch extra setup nahi chahiye usually

#### iOS (`ios/Podfile`):
```bash
cd ios
pod install
cd ..
```

#### Web (`web/index.html`):
- Stripe.js script add karna hoga (detailed steps neeche)

---

## 🔑 Step 2: Stripe Account Setup

### 2.1 Stripe Dashboard se Keys Lein

1. [Stripe Dashboard](https://dashboard.stripe.com/test/apikeys) par jayein
2. **Test Mode** ON karein (development ke liye)
3. **Publishable Key** copy karein (frontend ke liye)
4. **Secret Key** copy karein (backend ke liye - NEVER expose in frontend!)

### 2.2 Environment Variables Setup

`.env` file create/update karein (project root mein):

```env
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...  # Backend only
```

**Note:** `.env` file ko `.gitignore` mein add karein (security ke liye)

---

## 🔧 Step 3: Backend Setup (Payment Intent Creation)

### 3.1 Option A: Firebase Functions (Recommended)

Agar Firebase Functions use kar rahe ho:

**File:** `functions/index.js` (create karein agar nahi hai)

```javascript
const functions = require('firebase-functions');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  // Authentication check
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { amount, currency = 'usd', bookingId } = data;

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount * 100, // Convert to cents
      currency: currency,
      metadata: {
        userId: context.auth.uid,
        bookingId: bookingId,
      },
    });

    return { clientSecret: paymentIntent.client_secret };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});
```

### 3.2 Option B: Separate Node.js/Express Server

Agar separate backend server use kar rahe ho:

**File:** `server/payment.js`

```javascript
const express = require('express');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

app.post('/create-payment-intent', async (req, res) => {
  const { amount, currency = 'usd', bookingId, userId } = req.body;

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount * 100,
      currency: currency,
      metadata: { userId, bookingId },
    });

    res.json({ clientSecret: paymentIntent.client_seent });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});
```

**Backend URL:** Environment variable mein store karein
```env
BACKEND_URL=https://your-backend-url.com
```

---

## 💻 Step 4: Flutter Code Implementation

### 4.1 Stripe Service Create Karein

**File:** `lib/data/services/stripe_service.dart` (NEW FILE)

```dart
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StripeService {
  static String? get publishableKey => dotenv.env['STRIPE_PUBLISHABLE_KEY'];
  static String? get backendUrl => dotenv.env['BACKEND_URL'];

  // Initialize Stripe
  static Future<void> initialize() async {
    Stripe.publishableKey = publishableKey ?? '';
    Stripe.merchantIdentifier = 'merchant.com.your.app'; // iOS ke liye
    await Stripe.instance.applySettings();
  }

  // Create Payment Intent (backend se call)
  static Future<String> createPaymentIntent({
    required double amount,
    required String currency,
    required String bookingId,
    required String userId,
  }) async {
    final response = await http.post(
      Uri.parse('$backendUrl/create-payment-intent'), // Ya Firebase Functions URL
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amount,
        'currency': currency,
        'bookingId': bookingId,
        'userId': userId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['clientSecret'];
    } else {
      throw Exception('Failed to create payment intent');
    }
  }

  // Confirm Payment (Web + Mobile dono ke liye)
  static Future<PaymentIntent> confirmPayment({
    required String clientSecret,
  }) async {
    return await Stripe.instance.confirmPayment(
      clientSecret,
      PaymentMethodParams.card(
        paymentMethodData: PaymentMethodData(),
      ),
    );
  }

  // Web ke liye Payment Sheet (alternative approach)
  static Future<void> initiatePaymentSheet({
    required String clientSecret,
  }) async {
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Tutor Finder',
      ),
    );

    await Stripe.instance.presentPaymentSheet();
  }
}
```

### 4.2 Payment Service Create Karein

**File:** `lib/data/services/payment_service.dart` (NEW FILE)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tutor_finder/data/services/stripe_service.dart';
import 'package:tutor_finder/data/models/payment_model.dart'; // Create karna hoga

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Process Payment
  Future<bool> processPayment({
    required double amount,
    required String bookingId,
    required String parentId,
    required String tutorId,
  }) async {
    try {
      // 1. Payment Intent create karein
      final clientSecret = await StripeService.createPaymentIntent(
        amount: amount,
        currency: 'usd',
        bookingId: bookingId,
        userId: parentId,
      );

      // 2. Payment confirm karein
      final paymentIntent = await StripeService.confirmPayment(
        clientSecret: clientSecret,
      );

      // 3. Payment record save karein Firestore mein
      if (paymentIntent.status == PaymentIntentStatus.Succeeded) {
        await _firestore.collection('payments').add({
          'paymentId': paymentIntent.id,
          'bookingId': bookingId,
          'parentId': parentId,
          'tutorId': tutorId,
          'amount': amount,
          'status': 'completed',
          'timestamp': FieldValue.serverTimestamp(),
          'paymentMethod': 'stripe',
        });

        // 4. Booking status update karein
        await _firestore.collection('bookings').doc(bookingId).update({
          'paymentStatus': 'paid',
          'paymentId': paymentIntent.id,
        });

        return true;
      }

      return false;
    } catch (e) {
      print('Payment Error: $e');
      return false;
    }
  }

  // Payment History
  Stream<List<PaymentModel>> getPaymentHistory(String parentId) {
    return _firestore
        .collection('payments')
        .where('parentId', isEqualTo: parentId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromMap(doc.data()))
            .toList());
  }
}
```

### 4.3 Payment Model Create Karein

**File:** `lib/data/models/payment_model.dart` (NEW FILE)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String paymentId;
  final String bookingId;
  final String parentId;
  final String tutorId;
  final double amount;
  final String status; // 'pending', 'completed', 'failed'
  final DateTime timestamp;
  final String paymentMethod;

  PaymentModel({
    required this.paymentId,
    required this.bookingId,
    required this.parentId,
    required this.tutorId,
    required this.amount,
    required this.status,
    required this.timestamp,
    required this.paymentMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'bookingId': bookingId,
      'parentId': parentId,
      'tutorId': tutorId,
      'amount': amount,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'paymentMethod': paymentMethod,
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      paymentId: map['paymentId'] ?? '',
      bookingId: map['bookingId'] ?? '',
      parentId: map['parentId'] ?? '',
      tutorId: map['tutorId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentMethod: map['paymentMethod'] ?? 'stripe',
    );
  }
}
```

---

## 🎨 Step 5: UI Screens Create Karein

### 5.1 Checkout Screen

**File:** `lib/views/parent/checkout_screen.dart` (NEW FILE)

Key features:
- Amount display
- Payment method selection
- Card input fields (Stripe Elements use karein web ke liye)
- Payment button
- Loading state
- Error handling

**Web ke liye:** Stripe Elements use karein (iframe-based, secure)
**Mobile ke liye:** Native Stripe Payment Sheet use karein

### 5.2 Payment Methods Screen

**File:** `lib/views/parent/payment_methods_screen.dart` (NEW FILE)

Key features:
- Saved payment methods list
- Add new payment method
- Set default payment method
- Delete payment method

### 5.3 Payment History Screen

**File:** `lib/views/parent/payment_history_screen.dart` (NEW FILE)

Key features:
- Past payments list
- Payment status
- Receipt download
- Filter by date/status

---

## 🌐 Step 6: Web-Specific Setup

### 6.1 Stripe.js Script Add Karein

**File:** `web/index.html` mein yeh add karein:

```html
<head>
  <!-- Existing code... -->
  
  <!-- Stripe.js Script -->
  <script src="https://js.stripe.com/v3/"></script>
</head>
```

### 6.2 Web Payment Flow

Web ke liye Stripe Elements use karein:
- Card Element (iframe-based, secure)
- Payment Element (more customizable)
- Redirect-based payment (alternative)

**File:** `lib/data/services/stripe_web_service.dart` (OPTIONAL - separate web service)

```dart
import 'dart:js' as js;
import 'dart:html' as html;

class StripeWebService {
  // Web-specific payment handling
  static Future<void> processWebPayment(String clientSecret) async {
    // Stripe.js ke through payment process karein
    // Platform-specific code web ke liye
  }
}
```

---

## 📱 Step 7: Mobile-Specific Setup

### 7.1 Android Configuration

**File:** `android/app/src/main/AndroidManifest.xml`

Check karein ke internet permission hai:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### 7.2 iOS Configuration

**File:** `ios/Runner/Info.plist`

Check karein ke App Transport Security properly configured hai.

**File:** `ios/Runner.xcodeproj/project.pbxproj`

Merchant identifier setup (agar Apple Pay use karna ho)

---

## 🔄 Step 8: Integration Points

### 8.1 Booking Flow mein Payment Add Karein

**File:** `lib/parent_viewmodels/request_booking_vm.dart`

Booking create karne ke baad payment screen par redirect karein.

### 8.2 Booking Detail Screen

**File:** `lib/views/parent/booking_view_detail_screen.dart`

"Pay Now" button add karein agar payment pending hai.

---

## 🔔 Step 9: Webhooks Setup (Important!)

Stripe webhooks se payment status updates receive karein:

### 9.1 Webhook Endpoint

Backend mein webhook endpoint create karein:

```javascript
app.post('/stripe-webhook', express.raw({type: 'application/json'}), (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, process.env.WEBHOOK_SECRET);
  } catch (err) {
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle events
  if (event.type === 'payment_intent.succeeded') {
    // Update payment status in Firestore
    const paymentIntent = event.data.object;
    // Update database...
  }

  res.json({received: true});
});
```

### 9.2 Stripe Dashboard se Webhook Configure

1. Stripe Dashboard → Developers → Webhooks
2. Add endpoint URL
3. Select events: `payment_intent.succeeded`, `payment_intent.payment_failed`
4. Webhook signing secret copy karein

---

## 🧪 Step 10: Testing

### 10.1 Test Cards (Stripe Test Mode)

```
Card Number: 4242 4242 4242 4242
Expiry: Any future date (e.g., 12/25)
CVC: Any 3 digits (e.g., 123)
```

### 10.2 Test Scenarios

1. ✅ Successful payment
2. ❌ Failed payment (use card: 4000 0000 0000 0002)
3. ✅ Payment with 3D Secure (use card: 4000 0027 6000 3184)
4. ✅ Refund testing
5. ✅ Webhook testing (Stripe CLI use karein)

### 10.3 Stripe CLI (Local Testing)

```bash
# Install Stripe CLI
# Windows: Download from GitHub
# Mac: brew install stripe/stripe-cli/stripe

# Login
stripe login

# Forward webhooks to local server
stripe listen --forward-to localhost:5000/stripe-webhook
```

---

## 📝 Step 11: Environment Setup

### 11.1 `.env` File Structure

```env
# Stripe Keys
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...  # Backend only
STRIPE_WEBHOOK_SECRET=whsec_...  # Webhook signing secret

# Backend URL
BACKEND_URL=https://your-backend.com
# OR Firebase Functions URL
FIREBASE_FUNCTIONS_URL=https://your-region-your-project.cloudfunctions.net
```

### 11.2 `.gitignore` Update

```gitignore
.env
.env.local
*.pem
service_account.json
```

---

## 🔐 Step 12: Security Best Practices

1. ✅ **NEVER** expose Secret Key in frontend code
2. ✅ Always use HTTPS in production
3. ✅ Validate payment amounts on backend
4. ✅ Use webhooks for payment status (don't trust frontend)
5. ✅ Implement proper error handling
6. ✅ Log payment events for audit
7. ✅ PCI Compliance - Stripe Elements use karein (card data never touches your server)

---

## 🚀 Step 13: Production Deployment

### 13.1 Live Keys Switch

1. Stripe Dashboard → Toggle "Live Mode"
2. Live Publishable Key use karein
3. Live Secret Key backend mein use karein
4. Update `.env` files

### 13.2 Firebase Functions Deploy

```bash
cd functions
npm install
firebase deploy --only functions
```

### 13.3 Environment Variables Set

Firebase Functions mein:
```bash
firebase functions:config:set stripe.secret_key="sk_live_..."
```

---

## 📚 Step 14: Documentation & Resources

### Useful Links:

1. **Stripe Flutter Package:** https://pub.dev/packages/flutter_stripe
2. **Stripe Documentation:** https://stripe.com/docs
3. **Stripe Test Cards:** https://stripe.com/docs/testing
4. **Stripe Webhooks:** https://stripe.com/docs/webhooks
5. **Stripe Elements (Web):** https://stripe.com/docs/stripe-js

---

## ✅ Implementation Checklist

### Setup Phase
- [ ] Stripe account create kiya
- [ ] API keys configure kiye
- [ ] Dependencies install kiye
- [ ] Environment variables setup kiye

### Backend Phase
- [ ] Payment Intent endpoint create kiya
- [ ] Webhook endpoint setup kiya
- [ ] Database schema design kiya
- [ ] Security validation add ki

### Frontend Phase
- [ ] StripeService create kiya
- [ ] PaymentService create kiya
- [ ] Payment Model create kiya
- [ ] Checkout Screen UI banaya
- [ ] Payment Methods Screen banaya
- [ ] Payment History Screen banaya
- [ ] Web integration complete ki
- [ ] Mobile integration complete ki

### Testing Phase
- [ ] Test cards se payment test kiya
- [ ] Webhook testing complete ki
- [ ] Error handling test kiya
- [ ] Both platforms (web + mobile) test kiye

### Production Phase
- [ ] Live keys configure kiye
- [ ] Webhook production URL setup kiya
- [ ] Monitoring setup kiya
- [ ] Documentation complete ki

---

## 🆘 Common Issues & Solutions

### Issue 1: "No such payment_method"
**Solution:** Payment Intent create karte time `automatic_payment_methods` enable karein

### Issue 2: Web payment not working
**Solution:** Stripe.js script properly load ho raha hai check karein, aur CORS issues check karein

### Issue 3: 3D Secure not working
**Solution:** Test cards use karein jo 3D Secure require karte hain, aur `confirmPayment` method properly implement karein

### Issue 4: Webhook not receiving events
**Solution:** Webhook URL publicly accessible hona chahiye, Stripe CLI se local testing karein

---

## 📞 Support

Agar koi issue aaye:
1. Stripe Dashboard → Logs check karein
2. Browser Console (web) / Logcat (Android) / Xcode Console (iOS) check karein
3. Backend logs check karein
4. Stripe Support: https://support.stripe.com

---

**Last Updated:** [Current Date]
**Version:** 1.0
