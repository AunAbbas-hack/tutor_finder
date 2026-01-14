const express = require('express');
const cors = require('cors');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const admin = require('firebase-admin');
require('dotenv').config();

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  try {
    // Option 1: Use service account file (if available in backend folder)
    // admin.initializeApp({
    //   credential: admin.credential.cert(require('./service_account.json'))
    // });
    
    // Option 2: Use environment variable (recommended for production)
    if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      admin.initializeApp({
        credential: admin.credential.applicationDefault()
      });
    } else {
      // Option 3: Use service account JSON from environment variable
      if (process.env.FIREBASE_SERVICE_ACCOUNT) {
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount)
        });
      } else {
        console.warn('⚠️ Firebase Admin SDK not initialized. Payment webhook will not save to Firestore.');
      }
    }
    console.log('✅ Firebase Admin SDK initialized');
  } catch (error) {
    console.error('❌ Firebase Admin SDK initialization error:', error.message);
    console.warn('⚠️ Payment webhook will not save to Firestore without Firebase Admin SDK');
  }
}

const db = admin.apps.length > 0 ? admin.firestore() : null;

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Server is running' });
});

// Create Stripe Checkout Session
app.post('/api/create-checkout-session', async (req, res) => {
  try {
    const { amount, bookingId, tutorId, parentId, currency = 'inr' } = req.body;

    // Validation
    if (!amount || !bookingId || !tutorId || !parentId) {
      return res.status(400).json({
        error: 'Missing required fields: amount, bookingId, tutorId, parentId',
      });
    }

    // Create Stripe Checkout Session
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [
        {
          price_data: {
            currency: currency.toLowerCase(),
            product_data: {
              name: 'Tutor Booking Payment',
              description: `Booking ID: ${bookingId}`,
            },
            // For INR: amount is in rupees, convert to paisa (multiply by 100)
            // For USD: amount is in dollars, convert to cents (multiply by 100)
            // For other currencies: check Stripe documentation
            unit_amount: Math.round(amount * 100), // Convert to smallest currency unit (paisa for INR, cents for USD)
          },
          quantity: 1,
        },
      ],
      mode: 'payment',
      success_url: `${process.env.APP_URL}/payment-success?session_id={CHECKOUT_SESSION_ID}&booking_id=${bookingId}`,
      cancel_url: `${process.env.APP_URL}/payment-cancel?booking_id=${bookingId}`,
      client_reference_id: bookingId,
      metadata: {
        bookingId: bookingId,
        parentId: parentId,
        tutorId: tutorId,
      },
    });

    res.json({
      success: true,
      sessionUrl: session.url,
      sessionId: session.id,
    });
  } catch (error) {
    console.error('Stripe Error:', error);
    res.status(500).json({
      error: 'Failed to create checkout session',
      message: error.message,
    });
  }
});

// Webhook endpoint for Stripe
app.post('/api/stripe-webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET;

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, endpointSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle the event
  if (event.type === 'checkout.session.completed') {
    const session = event.data.object;
    
    console.log('Payment successful for session:', session.id);
    console.log('Booking ID:', session.metadata.bookingId);
    
    try {
      const bookingId = session.metadata.bookingId;
      const parentId = session.metadata.parentId;
      const tutorId = session.metadata.tutorId;
      const amount = session.amount_total / 100; // Convert from cents/paise to main currency unit
      const currency = session.currency.toUpperCase();
      const paymentId = session.payment_intent || session.id; // Use payment_intent if available, else session id
      
      if (!db) {
        console.error('❌ Firestore not available. Payment record not saved.');
        return res.json({ received: true, warning: 'Firestore not initialized' });
      }
      
      // Create PaymentModel document in Firestore
      const now = new Date().toISOString();
      const paymentData = {
        paymentId: paymentId,
        bookingId: bookingId,
        parentId: parentId,
        tutorId: tutorId,
        amount: amount,
        currency: currency.toLowerCase(),
        status: 'completed',
        paymentMethod: 'card',
        stripeSessionId: session.id,
        stripePaymentIntentId: session.payment_intent || null,
        transactionId: session.payment_intent || session.id,
        createdAt: now,
        completedAt: now,
        updatedAt: now,
        tutorPaid: false, // Admin will mark as paid later
        metadata: {
          customerEmail: session.customer_email,
          customerDetails: session.customer_details,
        }
      };
      
      // Save payment to Firestore
      await db.collection('payments').doc(paymentId).set(paymentData);
      console.log('✅ Payment saved to Firestore:', paymentId);
      
      // Update booking payment status
      if (bookingId) {
        await db.collection('bookings').doc(bookingId).update({
          paymentStatus: 'paid',
          paymentId: paymentId,
          paymentDate: now,
          updatedAt: now,
        });
        console.log('✅ Booking payment status updated:', bookingId);
      }
      
    } catch (error) {
      console.error('❌ Error saving payment to Firestore:', error);
      // Don't fail webhook - Stripe will retry if we return error
    }
  }

  res.json({ received: true });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Stripe Secret Key: ${process.env.STRIPE_SECRET_KEY ? 'Set' : 'NOT SET'}`);
});
