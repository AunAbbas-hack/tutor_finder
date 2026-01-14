# 🧪 OAuth 2.0 FCM Testing Steps

## ✅ Setup Complete!

Service Account JSON file properly placed at `assets/service_account.json`

---

## 🚀 Testing Steps

### **Step 1: App Restart (Important!)**

**⚠️ CRITICAL:** Assets hot reload se load nahi hoti!

1. App ko **completely close** karo (not just hot reload)
2. Terminal mein stop karo: `Ctrl + C`
3. Phir se run karo:
   ```bash
   flutter run
   ```

**Why?** Assets (Service Account JSON) app start mein load hoti hain, hot reload se reload nahi hoti.

---

### **Step 2: Check Console Logs**

App start hone ke baad console mein yeh logs dikhne chahiye:

#### **On App Start:**
```
✅ Environment variables loaded successfully
✅ Firebase initialized successfully
```

#### **On First Notification Attempt:**
```
✅ OAuth token generated successfully
Token valid until: [timestamp]
📤 Sending FCM V1 API request to: https://fcm.googleapis.com/v1/projects/tutor-finder-0468/messages:send
   Token: [FCM_TOKEN]...
✅ Push notification sent successfully to user: [userId]
   Message ID: projects/tutor-finder-0468/messages/0:...
```

---

### **Step 3: Test Notification Trigger**

#### **Test 1: Booking Request (Parent → Tutor)**
1. Parent login karo
2. Booking create karo (any tutor ke liye)
3. Console check karo:
   - OAuth token generated ✅
   - FCM V1 API call successful ✅
   - Notification sent ✅
4. Tutor device par notification aayegi ✅

#### **Test 2: Booking Approval (Tutor → Parent)**
1. Tutor login karo
2. Booking request accept/reject karo
3. Console check karo:
   - Notification sent successfully ✅
4. Parent device par notification aayegi ✅

#### **Test 3: Message Notification**
1. Kisi user ko message send karo
2. Console check karo:
   - Notification sent successfully ✅
3. Receiver device par notification aayegi ✅

---

### **Step 4: Background/Killed State Test**

**Important:** Background/killed state mein bhi notifications kaam karni chahiye!

1. App ko background mein bhejo (home button press)
2. Ya app ko completely kill karo
3. Notification trigger karo (booking, message, etc.)
4. Notification aayegi ✅

---

## 🔍 Verification Checklist

### **Setup Verification:**
- [ ] Service Account JSON file exists: `assets/service_account.json` ✅
- [ ] `pubspec.yaml` mein assets properly configured ✅
- [ ] App completely restarted (not hot reload) ✅

### **OAuth Token Verification:**
- [ ] Console mein: `✅ OAuth token generated successfully` ✅
- [ ] Token expiry time logged (valid for ~55 minutes) ✅
- [ ] No errors during token generation ✅

### **FCM V1 API Verification:**
- [ ] Console mein: `📤 Sending FCM V1 API request to: https://fcm.googleapis.com/v1/...` ✅
- [ ] Console mein: `✅ Push notification sent successfully` ✅
- [ ] Message ID logged ✅
- [ ] Response status: 200 OK ✅

### **Notification Delivery Verification:**
- [ ] Notification received on device ✅
- [ ] Notification title/body correct hai ✅
- [ ] Notification tap par app open hoti hai ✅
- [ ] Background state mein notification aayegi ✅
- [ ] Killed state mein notification aayegi ✅

---

## ❌ Common Issues & Fixes

### **Issue 1: "Service Account JSON not found"**

**Error:**
```
⚠️ Service Account not found in assets
❌ Service Account JSON not found. Please place it in assets/service_account.json
```

**Fix:**
1. File path check karo: `assets/service_account.json` (not in `images` folder)
2. File name exactly `service_account.json` hai (not `.json.txt`)
3. `pubspec.yaml` mein assets properly added hai:
   ```yaml
   assets:
     - assets/service_account.json
   ```
4. App completely restart karo (not hot reload)

---

### **Issue 2: "Invalid JSON" or "JSON Parse Error"**

**Error:**
```
❌ Error loading Service Account credentials: FormatException: Unexpected character
```

**Fix:**
1. JSON file valid hai ya nahi check karo
2. JSON format correct hai ya nahi verify karo
3. Extra characters ya formatting issues check karo
4. Firebase Console se naya JSON download karo (agar purana invalid ho)

---

### **Issue 3: "401 Unauthorized"**

**Error:**
```
❌ Failed to send push notification: 401
Error: Unauthorized - Token may be invalid
```

**Fix:**
1. Service Account permissions check karo (Firebase Console → IAM & Admin)
2. Service Account ko "Firebase Cloud Messaging API" permission grant karo
3. Token cache clear karo (app restart)
4. Service Account JSON file correct hai ya nahi verify karo

---

### **Issue 4: "403 Forbidden"**

**Error:**
```
❌ Failed to send push notification: 403
Error: Forbidden - Check Service Account permissions
```

**Fix:**
1. Service Account permissions check karo:
   - Firebase Console → Project Settings → Service Accounts
   - Service Account email ko note karo
   - Google Cloud Console → IAM & Admin → IAM
   - Service Account find karo aur permissions check karo
2. FCM API enabled hai ya nahi verify karo:
   - Google Cloud Console → APIs & Services → Enabled APIs
   - "Firebase Cloud Messaging API" enabled hai ya nahi check karo
3. Project ID correct hai ya nahi verify karo: `tutor-finder-0468`

---

### **Issue 5: "404 Not Found"**

**Error:**
```
❌ Failed to send push notification: 404
Error: Not Found - Check project ID and FCM token
```

**Fix:**
1. Project ID correct hai ya nahi check karo: `tutor-finder-0468`
2. FCM token valid hai ya nahi check karo (Firestore → users collection)
3. API endpoint correct hai ya nahi verify karo

---

### **Issue 6: "OAuth Token Generation Failed"**

**Error:**
```
❌ Error generating OAuth token: [error details]
```

**Fix:**
1. Service Account JSON file valid hai ya nahi check karo
2. Internet connection check karo (token generation ke liye network chahiye)
3. Service Account JSON mein required fields present hain ya nahi check karo:
   - `type`: `service_account`
   - `project_id`
   - `private_key`
   - `client_email`
   - etc.

---

## 🎯 Success Indicators

### **✅ Everything Working:**
- OAuth token generated successfully
- FCM V1 API call successful (200 OK)
- Notification sent successfully
- Notification received on device
- Background/killed state mein bhi notifications kaam karti hain

---

## 📝 Testing Summary

### **Quick Test:**
1. App restart karo ✅
2. Login karo ✅
3. Booking create karo ya message send karo ✅
4. Console logs check karo ✅
5. Notification receive karo ✅

**Agar sab logs green (✅) hain aur notification aayi, to implementation successful hai!** 🎉

---

## 🚀 Next Steps After Successful Testing

1. **Production Ready:**
   - Service Account JSON ko `.gitignore` mein already added hai ✅
   - Security best practices follow kiye gaye hain ✅

2. **Monitor:**
   - Console logs regularly check karo
   - Notification delivery rates monitor karo
   - Error logs track karo

3. **Optimize:**
   - Token caching already implemented ✅
   - Auto-refresh already implemented ✅

---

**Ab app run karke test karo!** 🚀
