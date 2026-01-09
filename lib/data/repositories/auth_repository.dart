import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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
    return credential.user;
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

    return cred.user;
  }

  // ---------- COMPLETE PARENT SIGNUP (with Student) ----------
  /// Complete parent signup: users + parents + students collections me data save karega.
  /// SRS ke according: Parent signup me User, Parent, aur Student dono create hone chahiye.
  Future<User?> registerParentWithStudent({
    required UserModel baseUser,
    required ParentModel parent,
    required StudentModel student,
    required String password,
  }) async {
    // 1) Auth user create
    final cred = await _authService.signUpWithEmail(
      email: baseUser.email,
      password: password,
    );
    final uid = cred.user!.uid;

    // 2) users collection
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

    // 4) students collection (SRS requirement)
    // Note: During signup, studentId = parentId (same uid), but parentId is set to link to parent
    final studentWithId = student.copyWith(
      studentId: uid,
      parentId: uid, // Parent's uid (same as studentId during initial signup)
    );
    await _studentService.createStudent(studentWithId);

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

    return cred.user;
  }

  // ---------- LOGOUT / CURRENT USER ----------
  Future<void> logout() => _authService.signOut();

  User? get currentUser => _authService.currentUser;
}
