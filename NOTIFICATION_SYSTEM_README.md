# 📱 Notification System Documentation

## Overview
Yeh document explain karta hai ke **Tutor Finder App** mein notifications kab kab aur kis kis user ko jayengi.

---

## 🎯 Notification Types

### 1. **Booking Notifications**
### 2. **Chat/Message Notifications**
### 3. **System Notifications**
### 4. **Profile/Account Notifications**

---

## 👨‍👩‍👧‍👦 Parent Notifications

### **1. Booking Related Notifications**

#### ✅ **Booking Approved**
- **Trigger:** Jab tutor booking request ko approve kare
- **Message:** `"Your booking request has been approved by [Tutor Name]"`
- **When:** Tutor ne booking accept ki
- **Action:** Booking details screen par navigate kar sakte hain

#### ❌ **Booking Rejected**
- **Trigger:** Jab tutor booking request ko reject kare
- **Message:** `"Your booking request has been rejected by [Tutor Name]"`
- **When:** Tutor ne booking reject ki
- **Action:** Booking details screen par navigate kar sakte hain

#### 📅 **Booking Reminder**
- **Trigger:** Booking date se 1 din pehle
- **Message:** `"Reminder: Your session with [Tutor Name] is tomorrow at [Time]"`
- **When:** Booking date se 24 hours pehle
- **Action:** Booking details screen par navigate kar sakte hain

#### ✅ **Session Completed**
- **Trigger:** Jab tutor session complete mark kare
- **Message:** `"Session with [Tutor Name] has been marked as completed"`
- **When:** Tutor ne session complete ki
- **Action:** Booking details screen par navigate kar sakte hain

#### ❌ **Booking Cancelled by Tutor**
- **Trigger:** Jab tutor booking cancel kare
- **Message:** `"[Tutor Name] has cancelled your booking"`
- **When:** Tutor ne booking cancel ki
- **Action:** Booking details screen par navigate kar sakte hain

---

### **2. Chat/Message Notifications**

#### 💬 **New Message Received**
- **Trigger:** Jab tutor message send kare
- **Message:** `"[Tutor Name]: [Message Preview]"`
- **When:** Tutor ne message send kiya
- **Action:** Chat screen par navigate kar sakte hain
- **Note:** Agar app open hai to notification nahi aayega (in-app message show hoga)

---

### **3. System Notifications**

#### 🔔 **Welcome Notification**
- **Trigger:** Jab parent account create ho
- **Message:** `"Welcome to Tutor Finder! Find the best tutors for your children."`
- **When:** Signup complete hone par
- **Action:** Dashboard par navigate

#### ✅ **Profile Verified**
- **Trigger:** Jab admin profile verify kare
- **Message:** `"Your profile has been verified successfully"`
- **When:** Admin ne profile verify ki
- **Action:** Profile screen par navigate

---

## 👨‍🏫 Tutor Notifications

### **1. Booking Related Notifications**

#### 📝 **New Booking Request**
- **Trigger:** Jab parent booking request create kare
- **Message:** `"New booking request from [Parent Name] for [Subject(s)]"`
- **When:** Parent ne booking request submit ki
- **Action:** Booking requests screen par navigate kar sakte hain
- **Priority:** High (immediate notification)

#### ✅ **Booking Accepted Confirmation**
- **Trigger:** Jab tutor booking accept kare (self-confirmation)
- **Message:** `"You have accepted booking request from [Parent Name]"`
- **When:** Tutor ne booking accept ki
- **Action:** Booking details screen par navigate

#### ❌ **Booking Rejected Confirmation**
- **Trigger:** Jab tutor booking reject kare (self-confirmation)
- **Message:** `"You have rejected booking request from [Parent Name]"`
- **When:** Tutor ne booking reject ki
- **Action:** Booking requests screen par navigate

#### 📅 **Upcoming Session Reminder**
- **Trigger:** Session se 2 hours pehle
- **Message:** `"Reminder: You have a session with [Parent Name] in 2 hours"`
- **When:** Session time se 2 hours pehle
- **Action:** Booking details screen par navigate

#### ✅ **Session Completed by Parent**
- **Trigger:** Jab parent session complete mark kare
- **Message:** `"Session with [Parent Name] has been marked as completed"`
- **When:** Parent ne session complete ki
- **Action:** Booking details screen par navigate

#### ❌ **Booking Cancelled by Parent**
- **Trigger:** Jab parent booking cancel kare
- **Message:** `"[Parent Name] has cancelled the booking"`
- **When:** Parent ne booking cancel ki
- **Action:** Booking details screen par navigate

---

### **2. Chat/Message Notifications**

#### 💬 **New Message Received**
- **Trigger:** Jab parent message send kare
- **Message:** `"[Parent Name]: [Message Preview]"`
- **When:** Parent ne message send kiya
- **Action:** Chat screen par navigate kar sakte hain
- **Note:** Agar app open hai to notification nahi aayega (in-app message show hoga)

---

### **3. Profile/Account Notifications**

#### ✅ **Profile Approved**
- **Trigger:** Jab admin tutor profile approve kare
- **Message:** `"Congratulations! Your tutor profile has been approved"`
- **When:** Admin ne profile approve ki
- **Action:** Profile screen par navigate

#### ❌ **Profile Rejected**
- **Trigger:** Jab admin tutor profile reject kare
- **Message:** `"Your tutor profile has been rejected. Please update your information."`
- **When:** Admin ne profile reject ki
- **Action:** Profile edit screen par navigate

#### ⚠️ **Profile Under Review**
- **Trigger:** Jab tutor signup complete kare
- **Message:** `"Your profile is under review. We'll notify you once it's approved."`
- **When:** Signup complete hone par
- **Action:** Profile screen par navigate

---

## 🔄 Notification Flow

### **Booking Flow Notifications**

```
Parent creates booking
    ↓
Tutor gets notification: "New booking request"
    ↓
Tutor approves/rejects
    ↓
Parent gets notification: "Booking approved/rejected"
    ↓
Session reminder (1 day before for parent, 2 hours before for tutor)
    ↓
Session completed
    ↓
Both get notification: "Session completed"
```

### **Chat Flow Notifications**

```
User A sends message
    ↓
User B gets notification: "New message from User A"
    ↓
(Only if app is in background/killed)
```

---

## 📋 Notification Priority

### **High Priority (Immediate)**
- New booking request (Tutor)
- Booking approved/rejected (Parent)
- Booking cancelled (Both)
- Profile approved/rejected (Tutor)

### **Medium Priority**
- New message received (Both)
- Session reminders (Both)
- Session completed (Both)

### **Low Priority**
- Welcome notifications
- Profile under review
- System updates

---

## 🔔 Notification Delivery

### **When Notifications Are Sent:**

1. **Real-time (Immediate)**
   - Booking requests
   - Booking status changes
   - New messages (if app closed)

2. **Scheduled**
   - Session reminders (24 hours before for parent, 2 hours before for tutor)
   - Daily/weekly summaries (future feature)

3. **Event-based**
   - Profile verification
   - Account updates
   - System announcements

---

## 📱 Notification Display

### **App States:**

1. **App Open (Foreground)**
   - In-app notification show hoga
   - System notification nahi aayega
   - Real-time update in notification bell

2. **App Background**
   - System notification aayega
   - Lock screen par dikhega
   - Notification tray mein save hoga

3. **App Killed/Closed**
   - System notification aayega
   - Lock screen par dikhega
   - Notification tap karne par app open hogi

---

## 🎯 Notification Triggers Summary

### **Parent Ko Notifications:**
1. ✅ Booking approved
2. ❌ Booking rejected
3. 📅 Booking reminder (1 day before)
4. ✅ Session completed
5. ❌ Booking cancelled by tutor
6. 💬 New message from tutor
7. 🔔 Welcome message
8. ✅ Profile verified

### **Tutor Ko Notifications:**
1. 📝 New booking request
2. ✅ Booking accepted (self-confirmation)
3. ❌ Booking rejected (self-confirmation)
4. 📅 Session reminder (2 hours before)
5. ✅ Session completed
6. ❌ Booking cancelled by parent
7. 💬 New message from parent
8. ✅ Profile approved
9. ❌ Profile rejected
10. ⚠️ Profile under review

---

## 🔧 Technical Implementation

### **Notification Channels:**
- **Booking Notifications:** High priority, sound enabled
- **Message Notifications:** Medium priority, sound enabled
- **System Notifications:** Low priority, no sound

### **Notification Storage:**
- Firestore collection: `notifications`
- Real-time stream for in-app notifications
- FCM for push notifications (background/killed state)

### **Notification Limits (Free Tier):**
- Unlimited notifications (FCM free tier)
- No daily limit
- Background notifications supported

---

## 📝 Notes

1. **Notification Delivery:**
   - Notifications reliable hain (FCM guarantee)
   - Offline ho to online aane par deliver hoga
   - 1 din baad bhi notification aayega (jab device online ho)

2. **Notification Preferences:**
   - Future feature: User notification preferences
   - Currently: All notifications enabled by default

3. **Notification History:**
   - All notifications Firestore mein store hongi
   - 30 days tak history available
   - Old notifications auto-delete (future feature)

---

## 🚀 Future Enhancements

1. **Notification Preferences**
   - User apni notification preferences set kar sakte hain
   - Specific notification types disable kar sakte hain

2. **Notification Groups**
   - Similar notifications ko group karna
   - E.g., "5 new booking requests"

3. **Rich Notifications**
   - Images in notifications
   - Action buttons (Approve/Reject directly from notification)

4. **Scheduled Notifications**
   - Daily summaries
   - Weekly reports
   - Monthly statistics

---

**Last Updated:** [Current Date]
**Version:** 1.0
**Status:** Implementation Phase 1 Complete
