# Stripe Checkout Session - Simple Redirect Approach
## Koi Custom UI Nahi - Sirf Redirect to Stripe

---

## 🎯 Overview

Yeh approach **sabse simple** hai kyunki:
- ✅ Koi custom payment UI nahi banana padega
- ✅ Stripe ka ready-made hosted payment page use hoga
- ✅ User booking ke baad Stripe ke page par redirect ho jayega
- ✅ Payment complete hone ke baad automatically wapas aayega
- ✅ Web + Mobile dono ke liye kaam karega

---

## 🔄 Payment Flow (Simple)

```
1. User Booking Create Karta Hai
   ↓
2. Backend Stripe Checkout Session Create Karta Hai
   ↓
3. User Stripe ke Hosted Payment Page par Redirect Hota Hai
   ↓
4. User Payment Complete Karta Hai (Card, UPI, Wallet, etc.)
   ↓
5. Stripe Webhook Backend ko Notify Karta Hai
   ↓
6. User Success Page par Redirect Hota Hai
   ↓
7. Booking Status "Paid" ho jata hai
```

---

## 📋 Step-by-Step Implementation

---

## Step 1: Dependencies

### 1.1 Flutter Package (Minimal - Sirf HTTP call ke liye)

`pubspec.yaml` mein:
```yaml
dependencies:
  http: ^1.2.2  # Already hai aapke project mein
  url_launcher: ^7.0.0  # Stripe page khulne ke liye (mobile/web)
```

**Note:** `flutter_stripe` package ki zarurat nahi! Sirf HTTP call se kaam chalega.

```bash
flutter pub get
```

---

## Step 2: Stripe Account Setup

### 2.1 Stripe Dashboard se Keys

1. [Stripe Dashboard](https://dashboard.stripe.com/test/apikeys) → Test Mode ON
2. **Publishable Key** copy karein (backend ke liye zarurat nahi actually, but keep it)
3. **Secret Key** copy karein (backend ke liye - MOST IMPORTANT)

### 2.2 Environment Variables

Backend mein (Firebase Functions ya Node.js server):

```env
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...  # Baad mein webhook setup ke baad
```

---

## Step 3: Backend - Checkout Session Create Karein

### 3.1 Firebase Functions (Recommended)

**File:** `functions/index.js`

```javascript
const functions = require('firebase-functions');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const admin = require('firebase-admin');
admin.initializeApp();

// Create Checkout Session
exports.createCheckoutSession = functions.https.onCall(async (data, context) => {
  // 1. User authentication check
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must login');
  }

  const { amount, bookingId, tutorId, parentId, bookingDetails } = data;

  try {
    // 2. Stripe Checkout Session create karein
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'], // Card, UPI, Wallet sab support
      line_items: [
        {
          price_data: {
            currency: 'usd', // Ya 'inr' agar India se payment
            product_data: {
              name: 'Tutor Booking Payment',
              description: `Booking ID: ${bookingId}`,
            },
            unit_amount: Math.round(amount * 100), // Convert to cents/paisa
          },
          quantity: 1,
        },
      ],
      mode: 'payment',
      success_url: 'https://your-app-url.com/payment-success?session_id={CHECKOUT_SESSION_ID}',
      cancel_url: 'https://your-app-url.com/payment-cancel',
      client_reference_id: bookingId, // Booking ID track karne ke liye
      metadata: {
        bookingId: bookingId,
        parentId: parentId,
        tutorId: tutorId,
      },
    });

    // 3. Session ID save karein Firestore mein (optional - tracking ke liye)
    await admin.firestore().collection('payment_sessions').doc(session.id).set({
      bookingId: bookingId,
      parentId: parentId,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 4. Return session URL
    return { 
      sessionUrl: session.url, // Ye URL user ko redirect karni hai
      sessionId: session.id 
    };

  } catch (error) {
    console.error('Stripe Error:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
```

### 3.2 Node.js/Express Server (Agar separate backend ho)

**File:** `server/routes/payment.js`

```javascript
const express = require('express');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const router = express.Router();

router.post('/create-checkout-session', async (req, res) => {
  const { amount, bookingId, tutorId, parentId } = req.body;

  try {
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: 'Tutor Booking Payment',
              description: `Booking ID: ${bookingId}`,
            },
            unit_amount: Math.round(amount * 100),
          },
          quantity: 1,
        },
      ],
      mode: 'payment',
      success_url: `${process.env.APP_URL}/payment-success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${process.env.APP_URL}/payment-cancel`,
      metadata: {
        bookingId: bookingId,
        parentId: parentId,
        tutorId: tutorId,
      },
    });

    res.json({ 
      sessionUrl: session.url,
      sessionId: session.id 
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

module.exports = router;
```

---

## Step 4: Flutter - Booking Flow mein Integration

### 4.1 Payment Service (Simple)

**File:** `lib/data/services/payment_service.dart`

```dart
import 'package:cloud_functions/cloud_functions.dart'; // Firebase Functions ke liye
// Ya
import 'package:http/http.dart' as http; // Separate backend ke liye
import 'package:url_launcher/url_launcher.dart'; // URL open karne ke liye
import 'dart:convert';

class PaymentService {
  // Firebase Functions use kar rahe ho to
  Future<String?> createCheckoutSession({
    required double amount,
    required String bookingId,
    required String tutorId,
    required String parentId,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('createCheckoutSession');
      
      final result = await callable.call({
        'amount': amount,
        'bookingId': bookingId,
        'tutorId': tutorId,
        'parentId': parentId,
      });

      final sessionUrl = result.data['sessionUrl'] as String;
      return sessionUrl;
      
    } catch (e) {
      print('Payment Error: $e');
      return null;
    }
  }

  // Ya agar separate backend use kar rahe ho to
  Future<String?> createCheckoutSessionHttp({
    required double amount,
    required String bookingId,
    required String tutorId,
    required String parentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://your-backend.com/create-checkout-session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'bookingId': bookingId,
          'tutorId': tutorId,
          'parentId': parentId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['sessionUrl'] as String;
      }
      return null;
    } catch (e) {
      print('Payment Error: $e');
      return null;
    }
  }

  // Stripe URL open karein (Web + Mobile dono ke liye)
  Future<void> redirectToPayment(String sessionUrl) async {
    final uri = Uri.parse(sessionUrl);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // External browser/app mein khulega
      );
    }
  }
}
```

### 4.2 Booking ViewModel mein Integration

**File:** `lib/parent_viewmodels/request_booking_vm.dart` (Ya booking create karne wali file)

```dart
import 'package:tutor_finder/data/services/payment_service.dart';
import 'package:get/get.dart'; // Snackbar ke liye

class RequestBookingViewModel extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();

  Future<void> createBookingAndRedirectToPayment({
    required double amount,
    required String tutorId,
    // ... other booking parameters
  }) async {
    try {
      // 1. Pehle booking create karein (pending status ke saath)
      final bookingId = await _createBooking(/* ... */);
      
      // 2. Payment session create karein
      final sessionUrl = await _paymentService.createCheckoutSession(
        amount: amount,
        bookingId: bookingId,
        tutorId: tutorId,
        parentId: currentUserId, // Current logged in user
      );

      if (sessionUrl != null) {
        // 3. User ko Stripe payment page par redirect karein
        await _paymentService.redirectToPayment(sessionUrl);
        
        // User ab Stripe ke page par hai
        // Payment complete hone ke baad webhook se status update hoga
      } else {
        Get.snackbar('Error', 'Payment session create nahi hui');
      }
    } catch (e) {
      Get.snackbar('Error', 'Booking create karte waqt error: $e');
    }
  }
}
```

---

## Step 5: Webhooks - Payment Status Update

### 5.1 Webhook Endpoint (Backend)

**File:** `functions/index.js` (continue)

```javascript
// Webhook endpoint
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET;

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, endpointSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle the event
  if (event.type === 'checkout.session.completed') {
    const session = event.data.object;
    
    // Payment successful!
    const bookingId = session.metadata.bookingId;
    const parentId = session.metadata.parentId;
    const tutorId = session.metadata.tutorId;
    const amount = session.amount_total / 100; // Convert back from cents

    // 1. Payment record save karein
    await admin.firestore().collection('payments').add({
      paymentId: session.payment_intent,
      bookingId: bookingId,
      parentId: parentId,
      tutorId: tutorId,
      amount: amount,
      status: 'completed',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      sessionId: session.id,
    });

    // 2. Booking status update karein
    await admin.firestore().collection('bookings').doc(bookingId).update({
      paymentStatus: 'paid',
      paymentId: session.payment_intent,
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 3. Notification send karein (optional)
    // await sendPaymentNotification(parentId, tutorId, bookingId);
  }

  res.json({ received: true });
});
```

### 5.2 Stripe Dashboard mein Webhook Setup

1. Stripe Dashboard → Developers → Webhooks
2. "Add endpoint" click karein
3. Endpoint URL: `https://your-region-your-project.cloudfunctions.net/stripeWebhook`
4. Events select karein:
   - `checkout.session.completed`
   - `checkout.session.async_payment_succeeded`
   - `checkout.session.async_payment_failed`
5. Webhook signing secret copy karein → Environment variable mein add karein

---

## Step 6: Success/Cancel Pages (Simple)

### 6.1 Success Page

**File:** `lib/views/parent/payment_success_screen.dart`

```dart
class PaymentSuccessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            SizedBox(height: 20),
            Text('Payment Successful!', style: TextStyle(fontSize: 24)),
            SizedBox(height: 10),
            Text('Your booking has been confirmed'),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Get.offAll(() => ParentMainScreen()),
              child: Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 6.2 Cancel Page

**File:** `lib/views/parent/payment_cancel_screen.dart`

```dart
class PaymentCancelScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 80),
            SizedBox(height: 20),
            Text('Payment Cancelled', style: TextStyle(fontSize: 24)),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 6.3 Routes Setup

**File:** `lib/main.dart` (routes)

```dart
GetPage(
  name: '/payment-success',
  page: () => PaymentSuccessScreen(),
),
GetPage(
  name: '/payment-cancel',
  page: () => PaymentCancelScreen(),
),
```

---

## Step 7: Mobile App mein Deep Linking

### 7.1 Android - Deep Link Setup

**File:** `android/app/src/main/AndroidManifest.xml`

```xml
<activity
    android:name=".MainActivity"
    ...>
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
    
    <!-- Deep Link for Payment Success -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="https"
              android:host="your-app-url.com"
              android:pathPrefix="/payment-success"/>
    </intent-filter>
</activity>
```

### 7.2 iOS - Deep Link Setup

**File:** `ios/Runner/Info.plist`

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>your-app-url</string>
        </array>
    </dict>
</array>
```

---

## Step 8: Complete Flow Example

### Booking Create + Payment Redirect

```dart
// User booking create karta hai
void onBookTutor() async {
  // 1. Booking create (pending payment status)
  final booking = await bookingService.createBooking(
    tutorId: tutor.id,
    amount: tutor.hourlyRate * hours,
    status: 'pending_payment', // Payment pending
  );

  // 2. Payment session create
  final paymentService = PaymentService();
  final sessionUrl = await paymentService.createCheckoutSession(
    amount: booking.totalAmount,
    bookingId: booking.id,
    tutorId: tutor.id,
    parentId: currentUser.id,
  );

  // 3. Redirect to Stripe
  if (sessionUrl != null) {
    await paymentService.redirectToPayment(sessionUrl);
    // User Stripe page par hai
    // Webhook payment complete hone par booking update karega
  }
}
```

---

## ✅ Advantages of This Approach

1. ✅ **Zero UI Design** - Stripe ka ready page
2. ✅ **Secure** - Card data aapke server par nahi jata
3. ✅ **Multiple Payment Methods** - Card, UPI, Wallet sab support
4. ✅ **Mobile + Web** - Dono platforms pe kaam karta hai
5. ✅ **Less Code** - Minimal implementation
6. ✅ **PCI Compliant** - Stripe handle karta hai

---

## 🔄 Payment Status Check (Optional)

Agar real-time status check karna ho to:

```dart
// Check payment status
Future<void> checkPaymentStatus(String sessionId) async {
  // Backend se session status check karein
  // Ya Firestore mein payment record check karein
}
```

---

## 📝 Summary - Kya Karna Hai

### Backend:
1. ✅ Stripe Checkout Session create karne wala endpoint
2. ✅ Webhook endpoint (payment status receive karne ke liye)
3. ✅ Firestore mein payment records save karna

### Frontend:
1. ✅ Booking create ke baad payment service call karna
2. ✅ Stripe URL par redirect karna
3. ✅ Success/Cancel pages (simple)
4. ✅ Deep linking setup (mobile ke liye)

### Kya NAHI Karna:
- ❌ Custom payment form UI
- ❌ Card input fields
- ❌ Payment method selection UI
- ❌ `flutter_stripe` package (agar redirect approach use kar rahe ho)

---

## 🧪 Testing

### Test Cards:
```
Card: 4242 4242 4242 4242
Expiry: Any future date
CVC: Any 3 digits
```

### Test Flow:
1. Booking create karein
2. Stripe test page khulna chahiye
3. Test card se payment complete karein
4. Success page par redirect hona chahiye
5. Webhook se booking status "paid" hona chahiye

---

## 🚀 Production

1. Stripe Dashboard → Live Mode toggle
2. Live Secret Key backend mein set karein
3. Production webhook URL setup karein
4. Success/Cancel URLs production URLs se update karein

---

**Yeh approach sabse simple hai! Koi complex UI nahi, sirf redirect aur webhooks.**
