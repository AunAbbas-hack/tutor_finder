# Tutor Session Tabs Logic - Current Implementation

## ✅ Current Logic Analysis

Code analyze karne ke baad, **logic already correct hai** aapki requirement ke hisaab se!

---

## 📋 Tab Logic (Current Implementation)

### 1. Upcoming Tab
**Shows:**
- ✅ Bookings with `completed` status (payment done)
- ✅ Future date/time (booking date + time is after now)

**File:** `lib/tutor_viewmodels/tutor_session_vm.dart` (Line 345-350)

```dart
if (booking.status == BookingStatus.completed) {
  // Payment done (completed status)
  if (bookingDateTime.isAfter(now)) {
    // Future booking with payment done - upcoming
    upcomingList.add(sessionModel);
  }
}
```

**Result:** Sirf upcoming bookings WITH payment done show hongi ✅

---

### 2. Approved Tab
**Shows:**
- ✅ Bookings with `approved` status (payment NOT done)
- ✅ Any date (future OR past - payment pending hai to approved tab mein)

**File:** `lib/tutor_viewmodels/tutor_session_vm.dart` (Line 355-360)

```dart
else if (booking.status == BookingStatus.approved) {
  // Payment NOT done (approved status)
  if (bookingDateTime.isAfter(now)) {
    // Future booking without payment - approved tab
    approvedList.add(sessionModel);
  }
}
```

**Result:** Approved bookings (payment pending) show hongi ✅

---

### 3. Past Tab
**Shows:**
- ✅ Bookings with `completed` status + past date (payment done, date pass)
- ✅ Bookings with `approved` status + past date (payment pending, date pass)

**File:** `lib/tutor_viewmodels/tutor_session_vm.dart` (Line 350-364)

```dart
if (booking.status == BookingStatus.completed) {
  if (bookingDateTime.isAfter(now)) {
    upcomingList.add(sessionModel);
  } else {
    // Past booking with payment done - past
    pastList.add(sessionModel);
    completedList.add(sessionModel);
  }
} else if (booking.status == BookingStatus.approved) {
  if (bookingDateTime.isAfter(now)) {
    approvedList.add(sessionModel);
  } else {
    // Past booking without payment - past tab (incomplete)
    pastList.add(sessionModel);
    pastIncompleteList.add(sessionModel);
  }
}
```

**Result:** Past bookings (jab date pass ho jaye) show hongi ✅

---

## 🔄 Expected Flow

### Scenario 1: Booking Approval → Payment → Upcoming

1. **Parent booking create karta hai**
   - Status: `pending`
   - Shows in: Booking Requests (tutor side)

2. **Tutor approve karta hai**
   - Status: `approved` (payment pending)
   - Shows in: **Approved Tab** ✅

3. **Parent payment karta hai**
   - Status should change to: `completed` (payment done)
   - Shows in: **Upcoming Tab** (if future date) ✅
   - Moves from: Approved Tab → Upcoming Tab ✅

4. **Date pass ho jaye**
   - Status: `completed` (payment done)
   - Shows in: **Past Tab** ✅
   - Moves from: Upcoming Tab → Past Tab ✅

---

### Scenario 2: Booking Approval → Payment Pending → Past

1. **Tutor approve karta hai**
   - Status: `approved` (payment pending)
   - Shows in: **Approved Tab** ✅

2. **Date pass ho jaye (payment nahi hua)**
   - Status: `approved` (payment still pending)
   - Shows in: **Past Tab** (Past Incomplete filter) ✅
   - Moves from: Approved Tab → Past Tab ✅

---

## ⚠️ Current Issue

### Problem:
- Logic **correct hai** ✅
- BUT: Payment complete hone par booking status update nahi ho raha ❌
- Webhook mein Firestore update nahi ho raha ❌

### What Happens Currently:
1. Parent payment karta hai
2. Webhook receive hota hai
3. BUT booking status `approved` se `completed` nahi hota
4. Booking approved tab mein hi rehti hai (upcoming mein nahi jati)

---

## ✅ Solution Required

### Backend Webhook Update Needed:

**File:** `backend/server.js` (Line 86-100)

**Current Code:**
```javascript
if (event.type === 'checkout.session.completed') {
  const session = event.data.object;
  console.log('Payment successful for session:', session.id);
  console.log('Booking ID:', session.metadata.bookingId);
  
  // ❌ Firestore update nahi ho raha
}
```

**Should Be:**
```javascript
if (event.type === 'checkout.session.completed') {
  const session = event.data.object;
  const bookingId = session.metadata.bookingId;
  
  // ✅ Firestore update karna hoga
  // Booking status: approved → completed
  // Payment status update karna hoga
}
```

---

## 📊 Status Mapping

| Booking Status | Payment Status | Tab Location |
|---------------|----------------|--------------|
| `pending` | N/A | Booking Requests (not in sessions) |
| `approved` | Pending | **Approved Tab** |
| `completed` | Done | **Upcoming Tab** (if future) OR **Past Tab** (if past) |
| `rejected` | N/A | Not shown |
| `cancelled` | N/A | Not shown |

---

## 🎯 Summary

### Current Implementation Status:

✅ **Logic:** Correct hai (aapki requirement ke hisaab se)
❌ **Webhook Update:** Missing hai (booking status update nahi ho raha)
❌ **Payment Tracking:** Payment status field nahi hai (but `completed` status use ho raha hai)

### What Works:
- ✅ Tab logic correct hai
- ✅ Upcoming: Payment done + Future
- ✅ Approved: Payment pending
- ✅ Past: Past bookings

### What's Missing:
- ❌ Webhook mein booking status update
- ❌ Payment complete hone par `approved` → `completed` status change

### Next Steps:
1. Backend webhook mein Firestore update add karna hoga
2. Payment complete hone par booking status `completed` karna hoga
3. Tab logic automatically kaam karega (already implemented!)

---

**Conclusion:** Logic already perfect hai! Bas webhook update karna hoga. ✅
