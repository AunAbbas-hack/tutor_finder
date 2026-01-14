# Student Dashboard - User Flow Documentation

## 📋 Overview

The Student Dashboard allows students to view their assigned tutors, upcoming sessions, completed sessions, and track their learning progress. Students are linked to their parent's account and can see bookings made by their parents that include them.

---

## 🎯 User Flow

### 1. **Student Login & Authentication**

**Entry Point:** Login Screen → Student Role Login

**Flow:**
1. Student logs in with credentials (if student account exists)
2. AuthWrapper checks user role
3. If role = `UserRole.student`, navigates to `StudentMainScreen`
4. `StudentDashboardScreen` loads automatically

**Technical Details:**
- Student authentication uses Firebase Auth
- Student data is stored in `users` collection with `role: 'student'`
- Student profile data in `students` collection linked via `studentId`
- Students are linked to parent via `parentId` in `StudentModel`

---

### 2. **Dashboard Initialization**

**What Happens:**
1. `StudentDashboardViewModel` loads:
   - Student's `UserModel` from Firestore
   - Student's `StudentModel` from Firestore
   - Parent's `UserModel` (for reference)
   - All bookings where student's ID is in `childrenIds`
   - Tutor information for all assigned tutors

**Data Loading:**
- Loads student profile (name, grade, image)
- Loads parent information
- Filters bookings: `booking.childrenIds.contains(studentId)`
- Loads tutor data for all bookings
- Categorizes bookings (upcoming, completed, pending)

---

### 3. **Dashboard Display**

**Screen Layout:**

```
┌─────────────────────────────────┐
│  Welcome Header (Profile Card)  │
│  - Student Name                 │
│  - Grade                        │
│  - Profile Image                │
└─────────────────────────────────┘
┌─────────────────────────────────┐
│  Statistics Cards               │
│  [Total] [Completed] [Upcoming] │
└─────────────────────────────────┘
┌─────────────────────────────────┐
│  My Tutors (Horizontal List)    │
│  - Tutor Avatars                │
│  - Tutor Names                  │
└─────────────────────────────────┘
┌─────────────────────────────────┐
│  Upcoming Sessions              │
│  - Booking Cards                │
└─────────────────────────────────┘
┌─────────────────────────────────┐
│  Completed Sessions             │
│  - Booking Cards                │
└─────────────────────────────────┘
┌─────────────────────────────────┐
│  Pending Sessions               │
│  - Booking Cards                │
└─────────────────────────────────┘
```

---

### 4. **Student Views**

#### **A. Welcome Header**
- **Displays:**
  - Student name: "Welcome, [Name]!"
  - Grade: "Grade [X]"
  - Profile image (if available)

#### **B. Statistics Cards**
- **Total Sessions:** Count of all bookings
- **Completed:** Count of completed bookings
- **Upcoming:** Count of approved future bookings

#### **C. My Tutors Section**
- **Horizontal scrollable list** of assigned tutors
- Shows tutor avatar and name
- Tutors are extracted from all bookings
- Unique tutors only (no duplicates)

#### **D. Sessions Lists**
- **Upcoming Sessions:**
  - Status: `approved`
  - Date: Future dates
  - Sorted: Oldest first (next session first)

- **Completed Sessions:**
  - Status: `completed`
  - Sorted: Newest first (recently completed first)

- **Pending Sessions:**
  - Status: `pending`
  - Sorted: Newest first

**Each Booking Card Shows:**
- Tutor avatar and name
- Subject name
- Date and time
- Status badge (color-coded)
- Clickable → Opens booking detail screen

---

### 5. **Booking Detail View**

**Navigation:** Tap on any booking card

**Flow:**
1. Opens `BookingViewDetailScreen` (shared with parent view)
2. Shows full booking details:
   - Tutor information
   - Session date & time
   - Subject details
   - Student information
   - Parent information
   - Status and payment info
   - Location (if available)

**Note:** Student can view but cannot edit bookings (parent manages bookings)

---

### 6. **Data Flow Architecture**

```
Student Login
    ↓
AuthWrapper (checks role)
    ↓
StudentMainScreen
    ↓
StudentDashboardScreen
    ↓
StudentDashboardViewModel
    ├─→ UserService.getUserById(studentId)
    ├─→ StudentService.getStudentById(studentId)
    ├─→ UserService.getUserById(parentId)
    ├─→ BookingService.getBookingsByParentId(parentId)
    │   └─→ Filter: booking.childrenIds.contains(studentId)
    └─→ UserService.getUserById(tutorId) [for each tutor]
        ↓
Display Dashboard
```

---

### 7. **Booking Filtering Logic**

**How bookings are loaded:**

1. **Fetch all parent bookings:**
   ```dart
   getBookingsByParentId(parentId)
   ```

2. **Filter for student:**
   ```dart
   bookings.where((booking) =>
       booking.childrenIds != null &&
       booking.childrenIds!.contains(studentId)
   )
   ```

3. **Result:** Only bookings where this student is included

**Why this approach:**
- Students don't have their own booking collection
- Bookings belong to parents
- Students are associated via `childrenIds` array
- Client-side filtering (could be optimized with Cloud Function)

---

### 8. **Real-time Updates**

**Current Implementation:**
- Pull-to-refresh available
- Manual refresh: `vm.refresh()`
- No real-time stream (can be added later)

**Future Enhancement:**
- Stream bookings: `getBookingsByParentIdStream()`
- Auto-update when parent creates/updates bookings
- Real-time status changes

---

### 9. **Empty States**

**When No Bookings:**
- Shows empty state message:
  - "No Sessions Yet"
  - "Your parent will book sessions for you."
  - "You'll see them here once booked."

**When No Tutors:**
- Tutors section hidden if empty
- No error shown (normal state)

---

### 10. **Error Handling**

**Error States:**
- **Authentication Error:** Shows "User not authenticated"
- **Student Data Missing:** Shows "Student data not found"
- **Loading Error:** Shows error message with "Retry" button
- **Network Error:** Gracefully handles, shows cached data if available

---

## 🔄 User Journey Examples

### **Scenario 1: First-time Student Login**

1. Student logs in
2. Dashboard loads (empty state)
3. Shows: "No Sessions Yet" message
4. Parent books session for student
5. Student refreshes or logs in again
6. Booking appears in "Pending Sessions"
7. Tutor approves → Moves to "Upcoming Sessions"
8. Session completed → Moves to "Completed Sessions"

### **Scenario 2: Active Student**

1. Student logs in
2. Dashboard shows:
   - 3 assigned tutors
   - 2 upcoming sessions (this week)
   - 5 completed sessions (past month)
3. Student views upcoming session details
4. Sees tutor info, date, time, subject
5. Can track progress via completed sessions

### **Scenario 3: Multiple Subjects**

1. Parent books multiple sessions for student
2. Different subjects (Math, Science, English)
3. Different tutors for each subject
4. Student sees all sessions in one dashboard
5. Organized by status (upcoming, completed, pending)
6. Can view details for each session

---

## 📁 Files Created/Modified

### **New Files:**
1. `lib/student_viewmodels/student_dashboard_vm.dart`
   - ViewModel for student dashboard
   - Data loading and state management
   - Booking filtering logic

2. `lib/views/student/student_dashboard_screen.dart`
   - Main dashboard UI
   - Statistics cards
   - Tutors list
   - Sessions lists
   - Empty states

3. `lib/views/student/student_main_screen.dart`
   - Main screen wrapper for student
   - Entry point from AuthWrapper

### **Modified Files:**
1. `lib/core/widgets/auth_wrapper.dart`
   - Added `StudentMainScreen` import
   - Updated `UserRole.student` case to navigate to `StudentMainScreen`
   - Removed "Coming Soon" placeholder

---

## 🎨 UI/UX Features

- **Gradient Welcome Header:** Eye-catching profile card
- **Color-coded Statistics:** Quick overview
- **Horizontal Tutor List:** Easy browsing
- **Status Badges:** Clear visual indicators
- **Pull-to-Refresh:** Manual data update
- **Empty States:** Friendly messaging
- **Loading States:** Smooth transitions
- **Error Handling:** User-friendly error messages

---

## 🔐 Security & Permissions

- **Student Access:**
  - ✅ View own bookings
  - ✅ View assigned tutors
  - ✅ View booking details (read-only)
  - ❌ Cannot create/edit bookings (parent only)
  - ❌ Cannot contact tutors directly (parent manages)

- **Data Privacy:**
  - Students only see their own data
  - Filtered by `studentId` in `childrenIds`
  - Parent information shown for context only

---

## 🚀 Future Enhancements

1. **Real-time Updates:**
   - Stream bookings for live updates
   - Push notifications for new bookings

2. **Progress Tracking:**
   - Session completion statistics
   - Subject-wise progress
   - Performance metrics

3. **Student-Tutor Communication:**
   - Direct messaging (if approved by parent)
   - Session feedback
   - Notes and assignments

4. **Calendar View:**
   - Monthly/weekly calendar
   - Visual session timeline
   - Reminders and notifications

5. **Profile Management:**
   - Edit profile (name, grade)
   - Update preferences
   - View academic progress

---

## ✅ Testing Checklist

- [x] Student login works
- [x] Dashboard loads correctly
- [x] Statistics show correct counts
- [x] Tutors list displays correctly
- [x] Bookings are filtered correctly (student only)
- [x] Booking detail screen opens
- [x] Empty states show when no data
- [x] Error handling works
- [x] Pull-to-refresh works
- [x] Status badges show correct colors
- [x] Date formatting is correct

---

## 📝 Notes

- Students are children of parents in the system
- Bookings are created by parents, not students
- Student ID must be in `booking.childrenIds` to be visible
- Dashboard shows all bookings where student is included
- Tutors are extracted from bookings (unique list)
- No direct booking creation by students (parent manages)

---

## 🎓 Summary

The Student Dashboard provides a comprehensive view of a student's learning journey:
- **Overview:** Statistics and welcome message
- **Tutors:** All assigned tutors
- **Sessions:** Organized by status (upcoming, completed, pending)
- **Details:** Click to view full booking information

Students can track their progress, view upcoming sessions, and see their learning history, all in one place! 📚✨
