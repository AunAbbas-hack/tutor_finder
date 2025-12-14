// lib/views/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:tutor_finder/views/initial/role_selection_screen.dart';

import '../../core/widgets/app_primary_button.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_textfield.dart';
import '../../core/widgets/social_login_button.dart';
import '../../parent_viewmodels/auth_vm.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthViewModel>(
      create: (_) => AuthViewModel(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailPhoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _focusScopeNode = FocusScopeNode();

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    _emailPhoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _focusScopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        // Unfocus when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top icon
              Center(
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFF1A73E8),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Heading + subtitle
              AppText.heading('Welcome back!', context),
              const SizedBox(height: 8),
              AppText.subtitle('Log in to your account', context),
              const SizedBox(height: 32),

              // Email / phone
              AppTextField(
                label: 'Email or Phone Number',
                hintText: 'Enter your email or phone number',
                keyboardType: TextInputType.emailAddress,
                controller: _emailPhoneController,
                focusNode: _emailPhoneFocusNode,
                onChanged: vm.updateEmailOrPhone,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 16),

              // Password + Forgot password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Password',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: AppText.link('Forgot Password?', context),
                  ),
                ],
              ),
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                obscureText: !vm.isPasswordVisible,
                onChanged: vm.updatePassword,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  suffixIcon: IconButton(
                    onPressed: vm.togglePasswordVisibility,
                    icon: Icon(
                      vm.isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
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
                      color: Color(0xFF1A73E8),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Error message (if any)
              if (vm.errorMessage != null) ...[
                Text(
                  vm.errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Login button
              AppPrimaryButton(
                label: 'Log In',
                isLoading: vm.isLoading,
                isDisabled: !vm.canSubmitLogin,
                onPressed: () async {
                  final success = await vm.login();
                  if (success && mounted) {
                    // AuthWrapper automatically handles navigation based on role
                    // No need to manually navigate here
                  } else if (vm.errorMessage != null && mounted) {
                    Get.snackbar(
                      'Error',
                      vm.errorMessage!,
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 3),
                    );
                  }
                },
              ),

              const SizedBox(height: 24),

              // Divider "OR"
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'OR',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 24),

              // Google button
              SocialLoginButton(
                icon: Image.asset(
                  'assets/images/icons-google-logo.png', // apni asset path ke mutabiq change karo
                  height: 20,
                  width: 20,
                ),
                label: 'Continue with Google',
                onPressed: () {
                  // TODO: Google sign-in
                },
              ),

              const SizedBox(height: 12),

              // Facebook button
              SocialLoginButton(
                icon: const Icon(
                  Icons.facebook,
                  color: Color(0xFF1877F2),
                ),
                label: 'Continue with Facebook',
                onPressed: () {
                  // TODO: Facebook sign-in
                },
              ),

              const SizedBox(height: 24),

              // Sign Up link
              Center(
                child: GestureDetector(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>RoleSelectionScreen()));
                  },
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                      children: [
                         TextSpan(text: 'Don\'t have an account? '),
                        TextSpan(
                          text: 'Sign Up',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF1A73E8),
                            fontWeight: FontWeight.w600,
                          ),
                          // recognizer add kar sakte ho for tap if needed
                        ),
                      ],
                    ),
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
