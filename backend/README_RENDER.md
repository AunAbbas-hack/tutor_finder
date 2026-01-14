# Render.com Deployment - Quick Reference

## Environment Variables (Render Dashboard)

Add these in Render → Your Service → Environment:

```
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
APP_URL=https://your-service-name.onrender.com
PORT=10000 (Render automatically sets this)
```

## Service Configuration

- **Root Directory:** `backend`
- **Build Command:** `npm install`
- **Start Command:** `npm start`
- **Node Version:** 18+ (default)

## Quick Deploy Steps

1. Push code to GitHub
2. Render → New Web Service
3. Connect GitHub repo
4. Set Root Directory: `backend`
5. Add environment variables
6. Deploy!

See `RENDER_DEPLOYMENT_GUIDE.md` for complete guide.
