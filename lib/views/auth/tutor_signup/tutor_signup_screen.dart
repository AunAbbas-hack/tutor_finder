import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:tutor_finder/views/tutor/tutor_dashboard_screen.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/widgets/app_textfield.dart';
import '../../../parent_viewmodels/auth_vm.dart';


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
  final _phoneController = TextEditingController();
  final _subjectsExpController = TextEditingController();

  final _fullNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _subjectsExpFocusNode = FocusNode();

  bool _passwordVisible = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _subjectsExpController.dispose();
    _fullNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _phoneFocusNode.dispose();
    _subjectsExpFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
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
              ),
              const SizedBox(height: 16),

              // Password
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
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
              ),
              const SizedBox(height: 16),

              // Teaching Subjects & Experience (multiline)
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
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

              // Error
              if (vm.errorMessage != null) ...[
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
                isDisabled: !vm.canSubmitTutorSignup,
                onPressed:() async {
                  final ok = await vm.registerTutor();
                  if (!context.mounted) return;

                  if (ok) {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>TutorDashboardScreen()));
                  } else if (vm.errorMessage != null) {
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
