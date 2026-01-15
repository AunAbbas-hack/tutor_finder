import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/tutor_model.dart';
import '../models/parent_model.dart';
import '../models/student_model.dart';

import '../services/auth_services.dart';
import '../services/user_services.dart';
import '../services/tutor_services.dart';
import '../services/parent_services.dart';
import '../services/student_services.dart';

class AuthRepository {
  final AuthService _authService;
  final UserService _userService;
  final TutorService _tutorService;
  final ParentService _parentService;
  final StudentService _studentService;

  AuthRepository({
    AuthService? authService,
    UserService? userService,
    TutorService? tutorService,
    ParentService? parentService,
    StudentService? studentService,
  })  : _authService = authService ?? AuthService(),
        _userService = userService ?? UserService(),
        _tutorService = tutorService ?? TutorService(),
        _parentService = parentService ?? ParentService(),
        _studentService = studentService ?? StudentService();

  // ---------- LOGIN ----------
  Future<User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _authService.signInWithEmail(
      email: email,
      password: password,
    );
    final user = credential.user;
    
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'User not found after login.',
      );
    }
    
    // Reload user to get latest email verification status
    try {
      await user.reload();
    } catch (e) {
      // If reload fails, continue anyway - user is already authenticated
      if (kDebugMode) {
        print('⚠️ Could not reload user: $e');
      }
    }
    
    final refreshedUser = _authService.currentUser ?? user;
    
    // Ensure user is properly loaded and auth state is updated
    try {
      await refreshedUser.reload();
      // Get the latest user instance after reload
      final latestUser = _authService.currentUser ?? refreshedUser;
      
      // Check if user exists in Firestore (completed signup)
      try {
        final userModel = await _userService.getUserById(latestUser.uid);
        
        if (userModel != null) {
          // User exists in Firestore - allow login regardless of email verification
          // This allows existing tutor/parent accounts to login
          if (kDebugMode) {
            print('✅ User exists in Firestore - allowing login');
            if (!latestUser.emailVerified) {
              print('   Note: Email not verified, but user has completed signup');
            }
          }
          return latestUser;
        } else {
          // User doesn't exist in Firestore - might be incomplete signup
          // Check email verification for new/incomplete accounts
          if (!latestUser.emailVerified) {
            if (kDebugMode) {
              print('⚠️ User not found in Firestore and email not verified');
            }
            await _authService.signOut();
            throw FirebaseAuthException(
              code: 'email-not-verified',
              message: 'Please verify your email before logging in.',
            );
          }
          // Email is verified but user not in Firestore - allow login
          // (might be a race condition or data sync issue)
          if (kDebugMode) {
            print('⚠️ User not in Firestore but email verified - allowing login');
          }
          return latestUser;
        }
      } catch (e) {
        // If error fetching user data, check if it's a FirebaseAuthException
        if (e is FirebaseAuthException) {
          rethrow;
        }
        
        // For other errors (network issues, etc.), allow login if email is verified
        // This prevents blocking legitimate users due to temporary Firestore issues
        if (latestUser.emailVerified) {
          if (kDebugMode) {
            print('⚠️ Could not check user data in Firestore: $e');
            print('⚠️ Allowing login (email verified)');
          }
          return latestUser;
        }
        
        // If email not verified and can't check Firestore, require verification
        if (kDebugMode) {
          print('⚠️ Could not check user data and email not verified');
        }
        await _authService.signOut();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Please verify your email before logging in.',
        );
      }
    } catch (e) {
      // If reload fails, use the original user
      if (e is FirebaseAuthException) {
        rethrow;
      }
      if (kDebugMode) {
        print('⚠️ Could not reload user after login: $e');
      }
      // Still check Firestore even if reload failed
      try {
        final userModel = await _userService.getUserById(refreshedUser.uid);
        if (userModel != null) {
          if (kDebugMode) {
            print('✅ User exists in Firestore - allowing login (reload failed but user data found)');
          }
          return refreshedUser;
        }
      } catch (firestoreError) {
        if (kDebugMode) {
          print('⚠️ Could not check Firestore: $firestoreError');
        }
      }
      return refreshedUser;
    }
    
    // Final fallback - return the user if we get here
    // This should not normally be reached, but ensures we always return a user
    return _authService.currentUser ?? user;
  }

  // ---------- COMMON USER SIGNUP (for Parent etc.) ----------
  /// Sirf base user create karta hai (users collection),
  /// separate role-specific collection (parent/tutor) ka kaam
  /// alag methods me hota hai.
  Future<User?> registerBaseUser({
    required UserModel baseUser,
    required String password,
  }) async {
    final cred = await _authService.signUpWithEmail(
      email: baseUser.email,
      password: password,
    );
    final uid = cred.user!.uid;

    final userWithId = baseUser.copyWith(userId: uid);
    await _userService.createUser(userWithId);

    // Send email verification
    if (cred.user != null) {
      await _authService.sendEmailVerification(cred.user!);
    }

    return cred.user;
  }

  // ---------- PARENT SIGNUP (Simple - without student) ----------
  /// Simple parent signup: users + parents collections me data save karega.
  /// Use this for basic parent signup without child details.
  Future<User?> registerParent({
    required UserModel baseUser,
    required ParentModel parent,
    required String password,
  }) async {
    // 1) Auth user create
    final cred = await _authService.signUpWithEmail(
      email: baseUser.email,
      password: password,
    );
    final uid = cred.user!.uid;

    // 2) users collection
    final userWithId = baseUser.copyWith(userId: uid);
    await _userService.createUser(userWithId);

    // 3) parents collection
    final parentWithId = parent.copyWith(parentId: uid);
    await _parentService.createParent(parentWithId);

    // 4) Send email verification
    if (cred.user != null) {
      await _authService.sendEmailVerification(cred.user!);
    }

    return cred.user;
  }

  // ---------- COMPLETE PARENT SIGNUP (with Student) ----------
  /// Complete parent signup: users + parents + students collections me data save karega.
  /// SRS ke according: Parent signup me User, Parent, aur Student dono create hone chahiye.
  /// Child ke liye unique studentId generate karta hai (parentId ke equal nahi) taake manage_children_screen mein show ho.
  Future<User?> registerParentWithStudent({
    required UserModel baseUser,
    required ParentModel parent,
    required StudentModel student,
    required String password,
    required String childName, // Child's name for UserModel
  }) async {
    // 1) Auth user create (for parent)
    final cred = await _authService.signUpWithEmail(
      email: baseUser.email,
      password: password,
    );
    final uid = cred.user!.uid;

    // 2) users collection (parent's user record)
    if (kDebugMode) {
      print('📍 AuthRepository.registerParentWithStudent:');
      print('   Before copyWith - latitude: ${baseUser.latitude}, longitude: ${baseUser.longitude}');
    }
    final userWithId = baseUser.copyWith(userId: uid);
    if (kDebugMode) {
      print('   After copyWith - latitude: ${userWithId.latitude}, longitude: ${userWithId.longitude}');
    }
    await _userService.createUser(userWithId);

    // 3) parents collection
    final parentWithId = parent.copyWith(parentId: uid);
    await _parentService.createParent(parentWithId);

    // 4) Create child with unique studentId (different from parentId)
    // Generate unique student ID using Firestore document reference (same as new_child_sheet)
    final studentDocRef = FirebaseFirestore.instance.collection('users').doc();
    final studentId = studentDocRef.id;

    if (kDebugMode) {
      print('📍 Creating child:');
      print('   Parent ID: $uid');
      print('   Child Student ID: $studentId');
      print('   Child Name: $childName');
    }

    // 5) Create UserModel for child (student role)
    final childUserModel = UserModel(
      userId: studentId,
      name: childName,
      email: '', // Students don't need email
      role: UserRole.student,
      status: UserStatus.active,
    );
    await _userService.createUser(childUserModel);

    // 6) Create StudentModel with unique studentId
    final studentWithId = student.copyWith(
      studentId: studentId, // Unique ID, not equal to parentId
      parentId: uid, // Link to parent
    );
    await _studentService.createStudent(studentWithId);

    if (kDebugMode) {
      print('✅ Child created successfully with studentId: $studentId');
    }

    // 7) Send email verification
    if (cred.user != null) {
      await _authService.sendEmailVerification(cred.user!);
    }

    return cred.user;
  }

  // ---------- TUTOR SIGNUP ----------
  Future<User?> registerTutor({
    required UserModel baseUser,
    required TutorModel tutor,
    required String password,
  }) async {
    // 1) Auth user create
    final cred = await _authService.signUpWithEmail(
      email: baseUser.email,
      password: password,
    );
    final uid = cred.user!.uid;

    // 2) users collection
    final userWithId = baseUser.copyWith(userId: uid);
    await _userService.createUser(userWithId);

    // 3) tutors collection
    final tutorWithId = tutor.copyWith(tutorId: uid);
    await _tutorService.createTutor(tutorWithId);

    // 4) Send email verification
    if (cred.user != null) {
      await _authService.sendEmailVerification(cred.user!);
    }

    // 5) Sign out user after sending verification email
    // User needs to verify email before logging in
    await _authService.signOut();

    return cred.user;
  }

  // ---------- EMAIL VERIFICATION ----------
  Future<void> resendEmailVerification(String email, String password) async {
    // First sign in to get the user
    final credential = await _authService.signInWithEmail(
      email: email,
      password: password,
    );
    final user = credential.user;
    
    if (user != null) {
      // Reload user to get latest verification status
      await user.reload();
      final refreshedUser = _authService.currentUser;
      
      if (refreshedUser != null && !refreshedUser.emailVerified) {
        await _authService.resendEmailVerification(refreshedUser);
      }
      
      // Sign out after sending verification
      await _authService.signOut();
    }
  }

  // ---------- LOGOUT / CURRENT USER ----------
  Future<void> logout() => _authService.signOut();

  User? get currentUser => _authService.currentUser;
}
