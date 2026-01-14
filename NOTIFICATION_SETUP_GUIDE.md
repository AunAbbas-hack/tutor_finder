# 🔔 Notification System Setup Guide

## ❌ Missing Items (Notifications Nahi Aa Rahi)

### 1. **Service Account JSON Missing**
**Problem:** Service Account JSON file `assets/service_account.json` mein nahi hai.

**Solution:**
1. Firebase Console mein jao: https://console.firebase.google.com
2. Apne project ko select karo
3. Project Settings → Service Accounts tab
4. "Generate New Private Key" button click karo
5. JSON file download hogi
6. File ko `assets/service_account.json` mein rakho

**Note:** Service Account JSON file sensitive hai, isliye `.gitignore` mein already added hai.

---

### 2. **FCM Token Initialization Missing**
**Problem:** 
- Parent login ke baad FCM token initialize ho raha hai ✅
- **Tutor login ke baad FCM token initialize nahi ho raha** ❌
- **Existing users (app restart ke baad) ke liye FCM token initialize nahi ho raha** ❌

**Solution:**
- `AuthWrapper` mein FCM token initialization add karni hogi
- Ya `TutorMainScreen` / `ParentMainScreen` mein initialization add karni hogi

---

### 3. **Android Notification Channel Setup**
**Status:** ✅ Already configured in `AndroidManifest.xml`

---

## ✅ Step-by-Step Fix

### Step 1: Add Service Account JSON
1. Firebase Console → Project Settings → Service Accounts
2. "Generate New Private Key" → JSON file download karo
3. File ko `assets/service_account.json` mein rakho
4. Verify karo ke `pubspec.yaml` mein assets properly configured hai

### Step 2: Fix FCM Token Initialization
- AuthWrapper mein add karo (sab users ke liye)
- Ya individual screens mein add karo

### Step 3: Test
1. App ko real device par run karo (emulator par notifications properly work nahi karti)
2. Login karo
3. Console mein check karo:
   - `📱 FCM Token: ...` dikhna chahiye
   - `✅ FCM token saved to Firestore` dikhna chahiye
4. Notification trigger karo (booking create karo, etc.)
5. Check karo ke notification aayi ya nahi

---

## 🔍 Debugging Steps

### Check 1: FCM Token Saved?
Firestore → `users` collection → User document → Check `fcmToken` field

### Check 2: Service Account JSON Loaded?
Console mein check karo:
```
✅ OAuth token generated successfully
```
Agar error dikhe, to:
- Service Account JSON file `assets/service_account.json` mein hai ya nahi check karo
- File name exactly `service_account.json` hai ya nahi verify karo
- `pubspec.yaml` mein assets properly configured hai ya nahi check karo

### Check 3: Notification Sent?
Console mein check karo:
```
✅ Push notification sent successfully to user: userId
```
Agar yeh nahi dikhe, to notification send nahi hui.

### Check 4: Permissions?
Android 13+ par notification permission manually grant karni padti hai.

---

## 📝 Quick Checklist

- [ ] Service Account JSON file `assets/service_account.json` mein hai
- [ ] `pubspec.yaml` mein assets properly configured hai
- [ ] FCM token initialization added for all users (parent + tutor) ✅
- [ ] App real device par test kiya
- [ ] Notification permission granted (Android 13+)
- [ ] Firestore mein `fcmToken` field check kiya
- [ ] Console logs check kiye (OAuth token generated successfully)

---

## 🚨 Common Issues

### Issue 1: "Service Account JSON not found"
**Fix:** 
- Service Account JSON file `assets/service_account.json` mein honi chahiye
- File name exactly `service_account.json` honi chahiye
- `pubspec.yaml` mein assets properly configured hona chahiye
- App completely restart karo (assets hot reload se load nahi hoti)

### Issue 2: "OAuth token generation failed"
**Fix:** 
- Service Account JSON file valid hai ya nahi check karo
- JSON format correct hai ya nahi verify karo
- Firebase Console se naya JSON download karo (agar purana invalid ho)

### Issue 3: "Token is null"
**Fix:** FCM token initialization properly nahi hui. Check karo ke `initializeToken()` call ho rahi hai ya nahi.

### Issue 4: "Notification sent but not received"
**Fix:** 
- Real device par test karo (emulator par properly work nahi karta)
- Android notification permission check karo
- App background/killed state mein test karo
- OAuth token successfully generated hai ya nahi console mein check karo

### Issue 5: "401 Unauthorized" or "403 Forbidden"
**Fix:**
- Service Account permissions check karo (Firebase Console → IAM & Admin)
- FCM API enabled hai ya nahi verify karo (Google Cloud Console → APIs & Services)
- Service Account JSON file correct hai ya nahi verify karo

---

## 📞 Next Steps

1. **Pehle Service Account JSON file `assets/service_account.json` mein rakho**
2. **Phir app completely restart karo** (FCM token initialization already fixed ✅)
3. **Phir test karo** real device par
