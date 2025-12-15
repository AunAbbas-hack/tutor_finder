import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutor_finder/views/auth/parent_signup/parent_signup_screen_2.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/widgets/app_textfield.dart';
import '../../../parent_viewmodels/parent_signup_vm.dart';


/// Root widget for the whole Parent signup flow
/// Isko routes mein use karo.
class ParentSignupFlow extends StatelessWidget {
  const ParentSignupFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ParentSignupViewModel>(
      create: (_) => ParentSignupViewModel(),
      child: const ParentAccountStepScreen(),
    );
  }
}

/// STEP 1 – Parent account info
class ParentAccountStepScreen extends StatefulWidget {
  const ParentAccountStepScreen({super.key});

  @override
  State<ParentAccountStepScreen> createState() =>
      _ParentAccountStepScreenState();
}

class _ParentAccountStepScreenState extends State<ParentAccountStepScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _phoneController = TextEditingController();
  
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _phoneController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ParentSignupViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: AppText(
          'Create Parent Account',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: GestureDetector(
            onTap: FocusScope.of(context).unfocus,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step indicator
                // StepIndicator(
                //   currentIndex: vm.currentStepIndex,
                // ),
                const SizedBox(height: 24),

                // Heading + subtitle
                AppText(
                  'Create Your Parent Account',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                AppText(
                  'Let’s get you set up to find the perfect tutor for your child.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 24),

                // Parent name
                AppTextField(
                  label: 'Parents Full Name',
                  hintText: 'Enter your full name',
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  onChanged: vm.updateParentName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Email
                AppTextField(
                  label: 'Email Address',
                  hintText: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  onChanged: vm.updateEmail,
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
                  onChanged: vm.updatePassword,
                  decoration: InputDecoration(
                    hintText: 'Create a strong password',
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
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Confirm password
                AppText(
                  'Confirm Password',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmController,
                  focusNode: _confirmFocusNode,
                  obscureText: !_confirmPasswordVisible,
                  onChanged: vm.updateConfirmPassword,
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
                        setState(
                              () => _confirmPasswordVisible =
                          !_confirmPasswordVisible,
                        );
                      },
                      icon: Icon(
                        _confirmPasswordVisible
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
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Phone
                AppTextField(
                  label: 'Phone Number',
                  hintText: '(123) 456-7890',
                  keyboardType: TextInputType.phone,
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  onChanged: vm.updatePhone,
                  textInputAction: TextInputAction.done,
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
                          text:
                          'By continuing, you agree to our ',
                        ),
                        TextSpan(
                          text: 'Terms of Service',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy.',
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

                // Continue button
                AppPrimaryButton(
                  label: 'Continue',
                  isLoading: vm.isLoading,
                  isDisabled: !vm.isStep1Valid,
                  onPressed: () {
                    final ok = vm.continueFromStep1();
                    if (ok) {
                      // Step 2 pe jao – same ViewModel reuse hoga
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider<ParentSignupViewModel>.value(
                              value: vm,child: const ParentChildDetailsStepScreen(),),
                        ),
                      );
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Already have account
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
