# Remaining Features - Task List (Step by Step)

**Project:** Tutor Finder App  
**Status:** 92-97% Complete  
**Remaining:** 3-8%  
**Last Updated:** December 2024

---

## 📋 Task Organization

Yeh document mein remaining features ko sections mein organize kiya gaya hai. Aap mujhe step by step instructions de sakte hain: "pehle Section 1 karo", "phir Section 2 karo", etc.

---

## 🔴 SECTION 1: Booking Details Screens (CRITICAL)

**Priority:** 🔴 Critical  
**Estimated Time:** Already Complete ✅  
**Status:** ✅ COMPLETE - Both screens already implemented!

### ✅ Task 1.1: Parent Booking Details Screen - COMPLETE
- ✅ **Already Exists:** `lib/views/parent/booking_view_detail_screen.dart`
- ✅ Shows booking information (date, time, subject, tutor info)
- ✅ Shows booking status (pending, approved, rejected, completed)
- ✅ Action buttons (Pay Now, Chat, Cancel, Complete Booking)
- ✅ Integrated with `BookingViewDetailViewModel`
- ✅ Navigation already added from bookings list
- ✅ Payment integration working
- ✅ Location with map display
- ✅ Special requests section

**Note:** File name is `booking_view_detail_screen.dart` (not `booking_details_screen.dart`)

---

### ✅ Task 1.2: Tutor Booking Details Screen - COMPLETE
- ✅ **Already Exists:** `lib/views/tutor/tutor_booking_request_detail_screen.dart`
- ✅ Shows booking information (date, time, subject, parent info, child info)
- ✅ Shows booking status
- ✅ Action buttons (approve/reject, chat with parent)
- ✅ Integrated with `TutorBookingRequestDetailViewModel`
- ✅ Navigation already added from tutor booking requests
- ✅ Parent profile section
- ✅ Location section with map

**Note:** File name is `tutor_booking_request_detail_screen.dart` (not `booking_details_screen.dart`)

**Conclusion:** Section 1 is 100% complete! No work needed.

---

### ✅ Task 1.3: Fix Tutor Detail Booking Request - COMPLETE
- [x] Removed unused `requestBooking()` method from `lib/viewmodels/tutor_detail_vm.dart`
- [x] Navigation to RequestBookingScreen already working properly
- [x] Booking flow from tutor detail page is functional

**Files Modified:**
- `lib/viewmodels/tutor_detail_vm.dart` ✅

**Note:** The unused method has been removed. Booking creation works through `RequestBookingScreen` which uses `RequestBookingViewModel`.

---

## 🟡 SECTION 2: Payment History Screen (HIGH PRIORITY)

**Priority:** 🟡 High  
**Estimated Time:** 2-3 days  
**Status:** ✅ COMPLETE

### ✅ Task 2.1: Payment History Screen - COMPLETE
- [x] Created `lib/views/parent/payment_history_screen.dart`
- [x] Shows list of all payments (completed, pending, failed)
- [x] Displays payment details (amount, date, booking ID, tutor name)
- [x] Added filters (all, completed, pending, failed)
- [x] Added search functionality
- [x] Shows payment status badges
- [x] Integrated with PaymentService
- [x] Added summary card with total payments and amount
- [x] Added navigation to booking details from payment card

**Files Created:**
- `lib/views/parent/payment_history_screen.dart` ✅
- `lib/parent_viewmodels/payment_history_vm.dart` ✅

**Files Modified:**
- `lib/data/services/payment_service.dart` ✅ (added Firestore methods)

---

### ✅ Task 2.2: Payment History Integration - COMPLETE
- [x] Added navigation from parent profile screen
- [x] Added payment history button in bookings screen AppBar
- [x] Proper error handling implemented
- [x] Loading states handled
- [x] Empty states handled

**Files Modified:**
- `lib/views/parent/parent_profile_screen.dart` ✅
- `lib/views/parent/bookings_screen_navbar.dart` ✅

---

## 🟡 SECTION 3: Reviews & Ratings System (HIGH PRIORITY)

**Priority:** 🟡 High  
**Estimated Time:** 3-5 days  
**Status:** ✅ COMPLETE

### ✅ Task 3.1: Review Service - COMPLETE
- [x] Created `lib/data/services/review_service.dart`
- [x] Implemented `createReview()` method
- [x] Implemented `getReviewsByTutorId()` method
- [x] Implemented `getReviewById()` method
- [x] Implemented `updateReview()` method
- [x] Implemented `deleteReview()` method (soft delete)
- [x] Implemented `getAverageRating()` method
- [x] Implemented `getReviewCount()` method
- [x] Implemented `getRatingDistribution()` method
- [x] Implemented `addReply()` and `updateReply()` methods (tutor replies)
- [x] Implemented `hasParentReviewedTutor()` validation
- [x] Implemented `hasParentReviewedBooking()` validation
- [x] Added real-time stream support
- [x] Firestore collection structure ready

**Files Created:**
- `lib/data/services/review_service.dart` ✅

---

### ✅ Task 3.2: Review Model - COMPLETE
- [x] Created `lib/data/models/review_model.dart`
- [x] Added all required fields: reviewId, tutorId, parentId, bookingId, rating, comment, createdAt, updatedAt
- [x] Added optional fields: isVisible, reply, repliedAt
- [x] Implemented `toMap()` and `fromFirestore()` methods
- [x] Added `copyWith()` method
- [x] Added validation helpers (hasComment, hasReply, isValidRating)
- [x] Rating validation (1-5 stars)

**Files Created:**
- `lib/data/models/review_model.dart` ✅

---

### ✅ Task 3.3: Review Submission Screen - COMPLETE
- [x] Created `lib/views/parent/review_screen.dart`
- [x] Added star rating widget (1-5 stars)
- [x] Added comment text field (optional, 500 char limit)
- [x] Added submit button with loading state
- [x] Integrated with ReviewService
- [x] Added validation (rating required, 1-5 stars)
- [x] Shows success/error messages
- [x] Navigate back after submission
- [x] Checks if already reviewed (prevents duplicates)
- [x] Beautiful UI matching app design
- [x] Tutor info card display

**Files Created:**
- `lib/views/parent/review_screen.dart` ✅
- `lib/parent_viewmodels/review_vm.dart` ✅

**Files Modified:**
- `lib/views/parent/booking_view_detail_screen.dart` ✅ (added "Write Review" button for completed bookings)

---

### ✅ Task 3.4: Display Reviews in Tutor Detail - COMPLETE
- [x] Updated `lib/viewmodels/tutor_detail_vm.dart`
- [x] Replaced mock rating (4.9) with real data from ReviewService
- [x] Replaced mock review count (82) with real count
- [x] Load and display actual reviews from Firestore
- [x] Shows review list in tutor detail screen
- [x] Added rating summary card with average rating and count
- [x] Shows review cards with star ratings, comments, dates
- [x] Shows tutor replies (if any) in styled container
- [x] Handles empty state (no reviews message)
- [x] Real-time review loading
- [x] Refresh reviews method for after submission

**Files Modified:**
- `lib/viewmodels/tutor_detail_vm.dart` ✅
- `lib/views/parent/tutor_detail_screen.dart` ✅

---

## 🟢 SECTION 4: Reports System (MEDIUM PRIORITY)

**Priority:** 🟢 Medium  
**Estimated Time:** 1 week  
**Status:** ✅ COMPLETE

### ✅ Task 4.1: Report Service - COMPLETE
- [x] Created `lib/data/services/report_service.dart`
- [x] Implemented `createReport()` method
- [x] Implemented `getReportsByUserId()` method
- [x] Implemented `getAllReports()` method (for admin)
- [x] Implemented `updateReportStatus()` method
- [x] Implemented `getReportsByStatus()` method
- [x] Implemented `getReportsByType()` method
- [x] Implemented `getReportsAgainstUser()` method
- [x] Implemented `getReportsByBookingId()` method
- [x] Implemented `getPendingReportsCount()` method
- [x] Implemented `addAdminNotes()` method
- [x] Implemented `assignReportToAdmin()` method
- [x] Added real-time streams for admin and user
- [x] Firestore collection structure ready

**Files Created:**
- `lib/data/services/report_service.dart` ✅

---

### ✅ Task 4.2: Report Model - COMPLETE
- [x] Updated `lib/data/models/report_model.dart`
- [x] Added `ReportType` enum (tutor, booking, payment, other)
- [x] Added `ReportStatus` enum (pending, inProgress, resolved, rejected)
- [x] Added `createdAt` and `updatedAt` fields
- [x] Added `adminNotes` field
- [x] Added `imageUrls` field for attachments
- [x] Added `fromFirestore()` method
- [x] Added enum conversion helpers
- [x] Improved date handling
- [x] Better structure for admin handling

**Files Modified:**
- `lib/data/models/report_model.dart` ✅

---

### ✅ Task 4.3: Report Submission Screen (Parent) - COMPLETE
- [x] Created `lib/views/parent/report_screen.dart`
- [x] Added report type selection (tutor, booking, payment, other)
- [x] Added description text field (1000 char limit)
- [x] Added submit button with loading state
- [x] Integrated with ReportService
- [x] Added validation (type and description required)
- [x] Shows success/error messages
- [x] Beautiful UI matching app design
- [x] Context card for reporting specific users/bookings

**Files Created:**
- `lib/views/parent/report_screen.dart` ✅
- `lib/parent_viewmodels/report_vm.dart` ✅

---

### ✅ Task 4.4: Report Submission Screen (Tutor) - COMPLETE
- [x] Created `lib/views/tutor/report_screen.dart`
- [x] Similar UI to parent report screen
- [x] Added report type selection
- [x] Added description field
- [x] Integrated with ReportService
- [x] Tutor-specific report types (Parent/Student, Booking, Payment, Other)
- [x] Context card for reporting specific users/bookings

**Files Created:**
- `lib/views/tutor/report_screen.dart` ✅
- `lib/tutor_viewmodels/report_vm.dart` ✅

---

### ✅ Task 4.5: Admin Report Viewing - COMPLETE
- [x] Added reports section in admin dashboard
- [x] Created reports list screen (`lib/views/admin/reports_screen.dart`)
- [x] Shows report details in dialog
- [x] Added status update functionality (mark as resolved)
- [x] Added filters (All, Pending, In Progress, Resolved, Rejected)
- [x] Added search functionality
- [x] Added summary card with total and pending counts
- [x] Real-time report loading
- [x] User info caching for performance

**Files Created:**
- `lib/views/admin/reports_screen.dart` ✅
- `lib/admin_viewmodels/reports_vm.dart` ✅

**Files Modified:**
- `lib/views/admin/admin_dashboard_screen.dart` ✅ (added Reports section)

---

## 🟢 SECTION 5: Student Dashboard (MEDIUM PRIORITY)

**Priority:** 🟢 Medium  
**Estimated Time:** 1-2 weeks  
**Status:** ✅ **COMPLETE**

### Task 5.1: Student Dashboard Screen
- [x] Create `lib/views/student/student_dashboard_screen.dart`
- [x] Show student profile
- [x] Show assigned tutors
- [x] Show upcoming sessions
- [x] Show completed sessions
- [x] Show progress/statistics
- [x] Add navigation to sessions

**Files Created:**
- `lib/views/student/student_dashboard_screen.dart` ✅
- `lib/views/student/student_main_screen.dart` ✅

---

### Task 5.2: Student ViewModels
- [x] Create `lib/student_viewmodels/student_dashboard_vm.dart`
- [x] Implement data loading
- [x] Implement session management
- [x] Add state management

**Files Created:**
- `lib/student_viewmodels/student_dashboard_vm.dart` ✅

---

### Task 5.3: Student Services (if needed)
- [x] Check if `lib/data/services/student_services.dart` exists
- [x] Service already exists (no changes needed)
- [x] Student data fetching methods available
- [x] Session fetching via BookingService

**Files:**
- `lib/data/services/student_services.dart` ✅ (already exists)

---

### Task 5.4: Update Auth Wrapper
- [x] Update `lib/core/widgets/auth_wrapper.dart`
- [x] Replace "Coming Soon" with actual StudentDashboardScreen
- [x] Test student login flow

**Files Modified:**
- `lib/core/widgets/auth_wrapper.dart` ✅

**Summary:**
- ✅ Created `StudentDashboardViewModel` for data loading and state management
- ✅ Created `StudentDashboardScreen` with welcome header, statistics, tutors list, and sessions
- ✅ Created `StudentMainScreen` as entry point
- ✅ Updated `AuthWrapper` to navigate to `StudentMainScreen` for student role
- ✅ Dashboard shows assigned tutors, upcoming sessions, completed sessions, and pending sessions
- ✅ Integrated with existing `BookingService` to filter bookings by `childrenIds`
- ✅ Statistics cards show total, completed, and upcoming sessions
- ✅ Pull-to-refresh functionality
- ✅ Empty states and error handling
- ✅ User flow documented in `STUDENT_DASHBOARD_USER_FLOW.md`

**Files Created:**
- `lib/student_viewmodels/student_dashboard_vm.dart` ✅
- `lib/views/student/student_dashboard_screen.dart` ✅
- `lib/views/student/student_main_screen.dart` ✅
- `STUDENT_DASHBOARD_USER_FLOW.md` ✅

**Files Modified:**
- `lib/core/widgets/auth_wrapper.dart` ✅

---

## 🟢 SECTION 6: Additional Features & Polish (LOW PRIORITY)

**Priority:** 🟢 Low  
**Estimated Time:** 1 week  
**Status:** Not Started

### Task 6.1: Online Status Backend
- [x] Update `lib/viewmodels/individual_chat_vm.dart`
- [x] Implement online status tracking
- [x] Add Firebase Realtime Database presence system
- [x] Update UI to show real online status

**Files Created:**
- `lib/data/services/presence_service.dart` ✅

**Files Modified:**
- `lib/viewmodels/individual_chat_vm.dart` ✅

**Summary:**
- ✅ Created `PresenceService` for online/offline status tracking
- ✅ Integrated presence system in `IndividualChatViewModel`
- ✅ Real-time online status updates via Firebase Realtime Database
- ✅ UI already shows online status (green dot indicator and "Online" text)
- ✅ Automatic offline detection when user disconnects

---

### Task 6.2: File/Image Picker for Chat
- [x] Update `lib/views/chat/individual_chat_screen.dart` ✅ (Already implemented)
- [x] Integrate file picker service ✅ (Already implemented)
- [x] Add file upload functionality ✅ (Already implemented)
- [x] Add file download functionality ✅ (Already implemented)
- [x] Show file previews ✅ (Already implemented)

**Files:**
- `lib/views/chat/individual_chat_screen.dart` ✅ (Already had file/image picker integration)
- `lib/viewmodels/individual_chat_vm.dart` ✅ (Already had sendImageMessage, sendFileMessage, downloadFile, openFile methods)
- `lib/core/services/image_picker_service.dart` ✅ (Already exists)
- `lib/core/services/file_picker_service.dart` ✅ (Already exists)

**Summary:**
- ✅ Image picker from gallery and camera working
- ✅ File picker for documents working
- ✅ File upload to Cloudinary working
- ✅ File download functionality working
- ✅ File opening functionality working
- ✅ File and image preview in chat working
- ✅ All features already implemented!

---

### Task 6.3: Admin Settings Screen
- [ ] Create `lib/views/admin/settings_screen.dart`
- [ ] Add app settings
- [ ] Add system configuration
- [ ] Add admin preferences

**Files to Create:**
- `lib/views/admin/settings_screen.dart`

**Files to Modify:**
- `lib/views/admin/admin_main_screen.dart` (replace "Coming Soon")

---

### Task 6.4: Navigation TODOs
- [ ] Complete notification navigation in admin dashboard
- [ ] Add "View All Activities" navigation
- [ ] Fix any remaining navigation TODOs

**Files to Modify:**
- `lib/views/admin/admin_dashboard_screen.dart`
- Other files with navigation TODOs

---

## 📊 Summary by Section

| Section | Priority | Tasks | Estimated Time | Status |
|---------|----------|-------|----------------|--------|
| Section 1: Booking Details | 🔴 Critical | 3 tasks | ✅ 100% Complete | ✅ All Tasks Done |
| Section 2: Payment History | 🟡 High | 2 tasks | ✅ Complete | ✅ All Tasks Done |
| Section 3: Reviews System | 🟡 High | 4 tasks | ✅ Complete | ✅ All Tasks Done |
| Section 4: Reports System | 🟢 Medium | 5 tasks | ✅ Complete | ✅ All Tasks Done |
| Section 5: Student Dashboard | 🟢 Medium | 4 tasks | ✅ Complete | ✅ All Tasks Done |
| Section 6: Additional Features | 🟢 Low | 4 tasks | 1 week | Not Started |

**Total Estimated Time:** 3-4 weeks (with 1 developer)  
**With Team (2-3 developers):** 2-3 weeks

---

## 🎯 How to Use This Document

1. **Mujhe bolo:** "Pehle Section 1 karo" - Main Section 1 ke saare tasks complete kar dunga
2. **Ya specific task:** "Task 1.1 karo" - Main sirf woh task karunga
3. **Ya multiple:** "Section 1 aur Section 2 karo" - Dono sections complete kar dunga

**Example Instructions:**
- "Pehle Section 1 karo"
- "Phir Section 2 karo"
- "Ab Section 3 karo"

---

## ✅ Completion Checklist

### Section 1: Booking Details
- [x] Task 1.1: Parent Booking Details Screen ✅ COMPLETE
- [x] Task 1.2: Tutor Booking Details Screen ✅ COMPLETE
- [x] Task 1.3: Fix Tutor Detail Booking Request ✅ COMPLETE

### Section 2: Payment History
- [x] Task 2.1: Payment History Screen ✅ COMPLETE
- [x] Task 2.2: Payment History Integration ✅ COMPLETE

### Section 3: Reviews System
- [x] Task 3.1: Review Service ✅ COMPLETE
- [x] Task 3.2: Review Model ✅ COMPLETE
- [x] Task 3.3: Review Submission Screen ✅ COMPLETE
- [x] Task 3.4: Display Reviews in Tutor Detail ✅ COMPLETE

### Section 4: Reports System
- [x] Task 4.1: Report Service ✅ COMPLETE
- [x] Task 4.2: Report Model ✅ COMPLETE
- [x] Task 4.3: Report Submission Screen (Parent) ✅ COMPLETE
- [x] Task 4.4: Report Submission Screen (Tutor) ✅ COMPLETE
- [x] Task 4.5: Admin Report Viewing ✅ COMPLETE

### Section 5: Student Dashboard
- [x] Task 5.1: Student Dashboard Screen ✅ COMPLETE
- [x] Task 5.2: Student ViewModels ✅ COMPLETE
- [x] Task 5.3: Student Services ✅ COMPLETE
- [x] Task 5.4: Update Auth Wrapper ✅ COMPLETE

### Section 6: Additional Features
- [x] Task 6.1: Online Status Backend ✅ COMPLETE
- [x] Task 6.2: File/Image Picker for Chat ✅ COMPLETE (was already implemented)
- [ ] Task 6.3: Admin Settings Screen
- [ ] Task 6.4: Navigation TODOs

---

**Document Status:** Ready for Step-by-Step Implementation  
**Last Updated:** December 2024
