# Parent Signup Flow - Complete Documentation

## Overview
The parent signup process is a **4-step multi-screen flow** that collects parent account information, child details, preferences/address, and location data before creating the account in Firebase.

---

## Architecture

### Files Structure
```
lib/
├── parent_viewmodels/
│   └── parent_signup_vm.dart          # Main ViewModel managing all steps
├── views/auth/parent_signup/
│   ├── parent_signup_screen_1.dart    # Step 1: Parent Account Info
│   ├── parent_signup_screen_2.dart    # Step 2: Child Details
│   └── parent_signup_screen_3.dart    # Step 3: Preferences/Address
└── views/auth/
    └── location_selection_screen.dart # Step 4: Location Selection & Final Submit
```

### Key Components
- **ParentSignupViewModel**: Manages state, validation, and submission for all 4 steps
- **ParentSignupFlow**: Root widget that initializes the ViewModel
- **AuthRepository**: Handles Firebase authentication and data creation
- **LocationViewModel**: Manages location selection (separate ViewModel)

---

## Step-by-Step Flow

### **STEP 1: Parent Account Information**
**File:** `parent_signup_screen_1.dart`  
**ViewModel Method:** `continueFromStep1()`

#### Fields Collected:
1. **Parent Full Name** (`_parentName`)
   - Required field
   - No specific validation (just non-empty)

2. **Email Address** (`_email`)
   - Required field
   - Validated with regex: `^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$`
   - Error: "Please enter a valid email address."

3. **Password** (`_password`)
   - Required field
   - **Strong password requirements:**
     - Minimum 8 characters
     - At least one capital letter (A-Z)
     - At least one number (0-9)
     - At least one special symbol (!@#$%^&*(),.?":{}|<>)
   - Password visibility toggle available

4. **Confirm Password** (`_confirmPassword`)
   - Required field
   - Must match password exactly
   - Error: "Passwords do not match."

5. **Phone Number** (`_phone`)
   - Required field
   - Only numeric input allowed (FilteringTextInputFormatter)
   - No specific format validation

#### Validation Logic:
```dart
bool continueFromStep1() {
  // Validates all fields
  // Sets error messages if invalid
  // Calls nextStep() if valid
  // Returns true/false
}
```

#### Navigation:
- On "Continue" button press → Navigates to `ParentChildDetailsStepScreen` (Step 2)
- ViewModel state is preserved using `ChangeNotifierProvider.value`

---

### **STEP 2: Child Details**
**File:** `parent_signup_screen_2.dart`  
**ViewModel Method:** `continueFromStep2()`

#### Fields Collected:
1. **Child's Full Name** (`_childName`)
   - Required field
   - Error: "Child's name is required."

2. **Grade/Class** (`_childGrade`)
   - Required field
   - Free text input (e.g., "5th Grade", "O-Levels")
   - Error: "Grade/Class is required."

3. **School/College** (`_childSchool`)
   - Required field
   - Free text input
   - Error: "School/College is required."

#### Validation Logic:
```dart
bool continueFromStep2() {
  // Validates all child fields
  // Sets error messages if invalid
  // Calls nextStep() if valid
  // Returns true/false
}
```

#### Navigation:
- On "Continue" button press → Navigates to `ParentPreferencesStepScreen` (Step 3)
- Back button → Returns to Step 1 (calls `vm.previousStep()`)

---

### **STEP 3: Preferences/Address**
**File:** `parent_signup_screen_3.dart`  
**ViewModel Method:** `continueFromStep3()`

#### Fields Collected:
1. **Home Address** (`_address`)
   - Required field
   - Multi-line text input
   - Error: "Address is required."
   - Used to build `ParentModel`

2. **Additional Notes** (`_notes`)
   - **Optional** field
   - Multi-line text input (4 lines)
   - Placeholder: "e.g., Preferred days, time, online/home, special needs, etc."
   - Currently stored but not used in model building

#### Validation Logic:
```dart
bool continueFromStep3() {
  // Validates address field
  // Sets error message if invalid
  // Calls nextStep() if valid
  // Returns true/false
}
```

#### Navigation:
- On "Continue" button press → Navigates to `LocationSelectionScreen` (Step 4)
- Back button → Returns to Step 2

---

### **STEP 4: Location Selection & Final Submission**
**File:** `location_selection_screen.dart`  
**ViewModel Method:** `submitParentSignup(latitude, longitude)`

#### Features:
1. **Google Maps Integration**
   - Interactive map for location selection
   - Tap on map to select location
   - Drag marker to adjust position
   - "Use My Current Location" button
   - Address reverse geocoding (shows selected address)

2. **Location Data**
   - Latitude and Longitude (required)
   - Selected address (displayed below map)

3. **Validation**
   - Location must be selected (latitude/longitude must be valid)
   - Error: "Please enter valid coordinates."

#### Final Submission Process:

```dart
// In location_selection_screen.dart (line 437)
final ok = await pvm.submitParentSignup(
  latitude: lat,
  longitude: lng,
);
```

**What happens in `submitParentSignup()`:**

1. **Validation Check:**
   ```dart
   if (!isStep1Valid || !isStep2Valid || !isStep3Valid) {
     _errorMessage = 'Please complete all steps.';
     return false;
   }
   ```

2. **Build Models:**
   ```dart
   // Build UserModel with location
   final baseUser = buildParentUserBase(
     latitude: latitude,
     longitude: longitude,
   );
   
   // Build ParentModel
   final parent = buildParentModel('');
   
   // Build StudentModel
   final student = buildStudentModel('');
   ```

3. **Firebase Registration:**
   ```dart
   final user = await _authRepository.registerParentWithStudent(
     baseUser: baseUser,
     parent: parent,
     student: student,
     password: _password,
   );
   ```

4. **Welcome Notification:**
   ```dart
   await notificationService.sendWelcomeNotificationToParent(
     parentId: user.uid,
   );
   ```

5. **Navigation:**
   - On success → Navigate to `LoginScreen` (clears navigation stack)
   - On error → Show error snackbar

---

## Data Models Created

### 1. UserModel (users collection)
```dart
UserModel(
  userId: uid,                    // Firebase Auth UID
  name: _parentName,               // From Step 1
  email: _email,                   // From Step 1
  password: null,                  // Not stored (Firebase Auth handles it)
  phone: _phone,                   // From Step 1
  role: UserRole.parent,           // Fixed
  status: UserStatus.pending,      // Fixed (needs admin approval)
  latitude: latitude,              // From Step 4
  longitude: longitude,            // From Step 4
)
```

### 2. ParentModel (parents collection)
```dart
ParentModel(
  parentId: uid,                   // Same as userId
  address: _address,                // From Step 3
)
```

### 3. StudentModel (students collection)
```dart
StudentModel(
  studentId: uid,                  // Same as userId (during signup)
  parentId: uid,                   // Links to parent (same as userId)
  schoolCollege: _childSchool,      // From Step 2
  grade: _childGrade,               // From Step 2
)
```

**Note:** During signup, `studentId` and `parentId` are the same (both use the parent's UID). This is by design - the parent account is linked to a student profile.

---

## Firebase Collections Updated

### 1. Firebase Authentication
- Creates new user account with email/password
- Returns Firebase Auth `User` object with UID

### 2. `users` Collection
- Document ID: `uid` (Firebase Auth UID)
- Contains: UserModel data

### 3. `parents` Collection
- Document ID: `uid` (same as userId)
- Contains: ParentModel data

### 4. `students` Collection
- Document ID: `uid` (same as userId during signup)
- Contains: StudentModel data

---

## ViewModel State Management

### Step Control
```dart
enum ParentSignupStep {
  account,      // Step 1
  childDetails, // Step 2
  preferences,  // Step 3
  summary,      // Step 4 (not used as separate screen)
}

// Navigation methods:
void nextStep()           // Move to next step
void previousStep()       // Move to previous step
void goToStep(step)       // Jump to specific step
```

### State Variables
- `_currentStep`: Current step in the flow
- `_isLoading`: Loading state during submission
- `_errorMessage`: General error message
- Step-specific error fields (e.g., `_emailError`, `_childNameError`)

### Validation
- Real-time validation on field changes
- Full validation on "Continue" button press
- Error messages displayed inline below fields

---

## Error Handling

### Client-Side Validation
- Field-level errors (displayed below input fields)
- Step-level errors (displayed at bottom of form)
- Password strength requirements
- Email format validation

### Server-Side Errors
- Email already in use → "This email is already registered."
- Generic errors → "Something went wrong. Please try again."
- Displayed via snackbar (Get.snackbar)

### Network Errors
- Handled in try-catch blocks
- Loading state managed during async operations

---

## Navigation Flow

```
ParentSignupFlow (Root)
    ↓
ParentAccountStepScreen (Step 1)
    ↓ [Continue]
ParentChildDetailsStepScreen (Step 2)
    ↓ [Continue]
ParentPreferencesStepScreen (Step 3)
    ↓ [Continue]
LocationSelectionScreen (Step 4)
    ↓ [Submit]
LoginScreen (Success)
```

### Navigation Details
- Each step uses `Navigator.push()` to next screen
- ViewModel is passed via `ChangeNotifierProvider.value` to preserve state
- Back button calls `vm.previousStep()` before `Navigator.pop()`
- Final success navigates with `pushAndRemoveUntil()` to clear stack

---

## Key Methods Reference

### ParentSignupViewModel

#### Step 1 Methods:
- `updateParentName(String)` - Updates parent name
- `updateEmail(String)` - Updates email with validation
- `updatePassword(String)` - Updates password with validation
- `updateConfirmPassword(String)` - Updates confirm password
- `updatePhone(String)` - Updates phone number
- `continueFromStep1()` - Validates and moves to Step 2

#### Step 2 Methods:
- `updateChildName(String)` - Updates child name
- `updateChildGrade(String)` - Updates grade/class
- `updateChildSchool(String)` - Updates school/college
- `continueFromStep2()` - Validates and moves to Step 3

#### Step 3 Methods:
- `updateAddress(String)` - Updates home address
- `updateNotes(String)` - Updates optional notes
- `continueFromStep3()` - Validates and moves to Step 4

#### Model Building:
- `buildParentUserBase(latitude, longitude)` - Creates UserModel
- `buildParentModel(userId)` - Creates ParentModel
- `buildStudentModel(userId, parentId)` - Creates StudentModel

#### Final Submission:
- `submitParentSignup(latitude, longitude)` - Complete signup process

---

## Important Notes

1. **Password Requirements:**
   - Minimum 8 characters
   - At least one uppercase letter
   - At least one number
   - At least one special character

2. **Location is Required:**
   - Must select location on map or use current location
   - Latitude/longitude are stored in UserModel

3. **User Status:**
   - All new parents start with `UserStatus.pending`
   - Requires admin approval before full access

4. **Student-Parent Link:**
   - During signup, studentId = parentId (same UID)
   - This links the student profile to the parent account

5. **Welcome Notification:**
   - Sent automatically after successful signup
   - Uses NotificationService
   - Failure doesn't block signup

6. **State Persistence:**
   - ViewModel state persists across navigation
   - Uses Provider pattern with ChangeNotifierProvider.value

---

## Testing Checklist

### Step 1 Validation:
- [ ] Empty fields show errors
- [ ] Invalid email format shows error
- [ ] Weak password shows error
- [ ] Mismatched passwords show error
- [ ] Valid data allows progression

### Step 2 Validation:
- [ ] Empty child fields show errors
- [ ] Valid data allows progression

### Step 3 Validation:
- [ ] Empty address shows error
- [ ] Notes field is optional
- [ ] Valid data allows progression

### Step 4 Submission:
- [ ] Location selection works
- [ ] Current location button works
- [ ] Invalid coordinates show error
- [ ] Successful submission creates all 3 models
- [ ] Welcome notification sent
- [ ] Navigation to login screen

### Error Handling:
- [ ] Duplicate email shows error
- [ ] Network errors handled gracefully
- [ ] Loading states work correctly

---

## Future Enhancements (Optional)

1. **Step Indicator UI:**
   - Currently commented out
   - Could add visual progress indicator

2. **Summary Screen:**
   - Step 4 enum exists but not used
   - Could add review screen before submission

3. **Phone Number Formatting:**
   - Currently accepts any numeric input
   - Could add format validation/masking

4. **Address Autocomplete:**
   - Currently free text input
   - Could integrate Google Places API

5. **Multiple Children:**
   - Currently supports one child
   - Could extend to multiple children

---

## Code References

- **ViewModel:** `lib/parent_viewmodels/parent_signup_vm.dart`
- **Step 1 Screen:** `lib/views/auth/parent_signup/parent_signup_screen_1.dart`
- **Step 2 Screen:** `lib/views/auth/parent_signup/parent_signup_screen_2.dart`
- **Step 3 Screen:** `lib/views/auth/parent_signup/parent_signup_screen_3.dart`
- **Step 4 Screen:** `lib/views/auth/location_selection_screen.dart`
- **Repository:** `lib/data/repositories/auth_repository.dart`
- **Models:** 
  - `lib/data/models/user_model.dart`
  - `lib/data/models/parent_model.dart`
  - `lib/data/models/student_model.dart`

---

**Last Updated:** December 2024  
**Document Version:** 1.0
