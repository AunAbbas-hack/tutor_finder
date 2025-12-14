// lib/views/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../core/widgets/app_textfield.dart';
import '../../parent_viewmodels/forgot_password_vm.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ForgotPasswordViewModel(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const AppText(
            'Reset Password',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.background,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Consumer<ForgotPasswordViewModel>(
              builder: (context, vm, _) {
                // Show success message if email sent
                if (vm.isEmailSent) {
                  return _buildSuccessView(context, vm);
                }

                return _buildResetForm(context, vm);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm(BuildContext context, ForgotPasswordViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),

        // Icon
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_reset,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Heading
        const AppText(
          'Forgot Password?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Instructions
        AppText(
          'Enter the email associated with your account, and we\'ll send a link to reset your password.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textGrey,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        // Email Input Field
        AppTextField(
          label: 'Email Address',
          hintText: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          onChanged: vm.updateEmail,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 8),

        // Error Message
        if (vm.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: AppText(
              vm.errorMessage!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),
        const SizedBox(height: 32),

        // Send Reset Link Button
        AppPrimaryButton(
          label: 'Send Reset Link',
          isLoading: vm.isLoading,
          isDisabled: !vm.isValidEmail,
          onPressed: () async {
            final success = await vm.sendResetLink();
            if (!success && vm.errorMessage != null) {
              Get.snackbar(
                'Error',
                vm.errorMessage!,
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.error,
                colorText: Colors.white,
                borderRadius: 12,
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 3),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildSuccessView(
    BuildContext context,
    ForgotPasswordViewModel vm,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 60),

        // Success Icon
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 60,
              color: AppColors.success,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Success Heading
        const AppText(
          'Check Your Email',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Success Message
        AppText(
          'We\'ve sent a password reset link to\n${vm.email}',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textGrey,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                'Next Steps:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              _buildInstructionStep('1', 'Check your email inbox'),
              _buildInstructionStep('2', 'Check spam mails if needed'),
              _buildInstructionStep('3', 'Click on the reset link'),
              _buildInstructionStep('4', 'Create a new password'),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Back to Login Button
        AppPrimaryButton(
          label: 'Back to Login',
          isLoading: false,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        const SizedBox(height: 16),

        // Resend Link
        TextButton(
          onPressed: () {
            vm.reset();
          },
          child: const AppText(
            'Resend Link',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AppText(
                number,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppText(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

