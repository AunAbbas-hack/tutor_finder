# Payment Backend Server

Yeh backend server Stripe Checkout Session create karne ke liye hai.

## Setup

1. **Dependencies Install Karein:**
```bash
npm install
```

2. **Environment Variables:**
`.env` file create karein (`.env.example` se copy karein):
```bash
cp .env.example .env
```

3. **Stripe Keys Add Karein:**
- Stripe Dashboard se Secret Key copy karein
- `.env` file mein `STRIPE_SECRET_KEY` set karein

4. **Run Server:**
```bash
npm start
# Ya development ke liye:
npm run dev
```

## Endpoints

### POST `/api/create-checkout-session`
Stripe Checkout Session create karta hai.

**Request Body:**
```json
{
  "amount": 5000,
  "bookingId": "booking123",
  "tutorId": "tutor123",
  "parentId": "parent123",
  "currency": "usd"
}
```

**Response:**
```json
{
  "success": true,
  "sessionUrl": "https://checkout.stripe.com/...",
  "sessionId": "cs_test_..."
}
```

### POST `/api/stripe-webhook`
Stripe webhook events receive karta hai.

## Deployment

Aap is server ko deploy kar sakte hain:
- Heroku
- Railway
- Render
- Vercel (Serverless Functions)
- DigitalOcean
- AWS
- Google Cloud Run

## Notes

- Webhook endpoint publicly accessible hona chahiye
- Production mein HTTPS use karein
- Environment variables secure rakhein
