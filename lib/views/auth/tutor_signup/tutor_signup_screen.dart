import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/widgets/app_textfield.dart';
import '../../../parent_viewmodels/auth_vm.dart';
import '../login_screen.dart';


class TutorSignupScreen extends StatelessWidget {
  const TutorSignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthViewModel>(
      create: (_) => AuthViewModel(),
      child: const _TutorSignupView(),
    );
  }
}

class _TutorSignupView extends StatefulWidget {
  const _TutorSignupView();

  @override
  State<_TutorSignupView> createState() => _TutorSignupViewState();
}

class _TutorSignupViewState extends State<_TutorSignupView> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectsExpController = TextEditingController();

  final _fullNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _subjectsExpFocusNode = FocusNode();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _subjectsExpController.dispose();
    _fullNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _phoneFocusNode.dispose();
    _subjectsExpFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: AppText(
          'Create Tutor Account',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            // Screen pe tap karne pe keyboard hide aur focus remove
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              AppText(
                'Become a Tutor',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),

              // Full Name
              AppTextField(
                label: 'Full Name',
                hintText: 'e.g., John Smith',
                controller: _fullNameController,
                focusNode: _fullNameFocusNode,
                onChanged: vm.updateTutorFullName,
                textInputAction: TextInputAction.next,
                errorText: vm.tutorFullNameError,
              ),
              const SizedBox(height: 16),

              // Email
              AppTextField(
                label: 'Email',
                hintText: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                focusNode: _emailFocusNode,
                onChanged: vm.updateTutorEmail,
                textInputAction: TextInputAction.next,
                errorText: vm.tutorEmailError,
              ),
              const SizedBox(height: 16),

              // Password
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'Password',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: !_passwordVisible,
                    onChanged: vm.updateTutorPassword,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      filled: true,
                      fillColor: AppColors.lightBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _passwordVisible = !_passwordVisible);
                        },
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: AppColors.iconGrey,
                        ),
                      ),
                      errorText: vm.tutorPasswordError,
                      errorStyle: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: vm.tutorPasswordError != null ? AppColors.error : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: vm.tutorPasswordError != null ? AppColors.error : AppColors.primary,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.error,
                          width: 2,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.error,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Confirm Password
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'Confirm Password',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocusNode,
                    obscureText: !_confirmPasswordVisible,
                    onChanged: vm.updateTutorConfirmPassword,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: 'Re-enter your password',
                      filled: true,
                      fillColor: AppColors.lightBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _confirmPasswordVisible = !_confirmPasswordVisible);
                        },
                        icon: Icon(
                          _confirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: AppColors.iconGrey,
                        ),
                      ),
                      errorText: vm.tutorConfirmPasswordError,
                      errorStyle: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: vm.tutorConfirmPasswordError != null ? AppColors.error : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: vm.tutorConfirmPasswordError != null ? AppColors.error : AppColors.primary,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.error,
                          width: 2,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.error,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Phone
              AppTextField(
                label: 'Phone Number',
                hintText: '(123) 456-7890',
                keyboardType: TextInputType.phone,
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                onChanged: vm.updateTutorPhone,
                textInputAction: TextInputAction.next,
                errorText: vm.tutorPhoneError,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                ],
              ),
              const SizedBox(height: 16),

              // Teaching Subjects & Experience (multiline)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'Teaching Subjects & Experience',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _subjectsExpController,
                    focusNode: _subjectsExpFocusNode,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    onChanged: vm.updateTutorSubjectsExp,
                    decoration: InputDecoration(
                      hintText: 'e.g., High School Math, Physics, SAT Prep',
                      filled: true,
                      fillColor: AppColors.lightBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      errorText: vm.tutorSubjectsExpError,
                      errorStyle: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: vm.tutorSubjectsExpError != null ? AppColors.error : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: vm.tutorSubjectsExpError != null ? AppColors.error : AppColors.primary,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.error,
                          width: 2,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.error,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Terms text
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textGrey,
                    ),
                    children: [
                      const TextSpan(
                        text: 'By signing up, you agree to our ',
                      ),
                      TextSpan(
                        text: 'Terms of Service.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Error (for server errors only)
              if (vm.errorMessage != null && 
                  vm.tutorFullNameError == null && 
                  vm.tutorEmailError == null && 
                  vm.tutorPasswordError == null && 
                  vm.tutorConfirmPasswordError == null &&
                  vm.tutorPhoneError == null && 
                  vm.tutorSubjectsExpError == null) ...[
                Text(
                  vm.errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Create Account button
              AppPrimaryButton(
                label: 'Create Account',
                isLoading: vm.isLoading,
                isDisabled: false,
                onPressed:() async {
                  final ok = await vm.registerTutor();
                  if (!context.mounted) return;

                  if (ok) {
                    // Navigate to login screen after signup
                    // User needs to verify email before logging in
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                    
                    // Show success message
                    Get.snackbar(
                      'Success',
                      'Account created! Please check your email to verify your account before logging in.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.primary,
                      colorText: Colors.white,
                      borderRadius: 12,
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 4),
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                    );
                  } else if (vm.errorMessage != null && 
                      vm.tutorFullNameError == null && 
                      vm.tutorEmailError == null && 
                      vm.tutorPasswordError == null && 
                      vm.tutorConfirmPasswordError == null &&
                      vm.tutorPhoneError == null && 
                      vm.tutorSubjectsExpError == null) {
                    Get.snackbar(
                      'Error',
                      vm.errorMessage!,
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.error,
                      colorText: Colors.white,
                      borderRadius: 12,
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 3),
                      icon: const Icon(Icons.error, color: Colors.white),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),

              // Already have account? Log In
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textGrey,
                    ),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Log In',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
