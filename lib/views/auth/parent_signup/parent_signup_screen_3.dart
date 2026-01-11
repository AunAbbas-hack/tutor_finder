import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/widgets/app_textfield.dart';
import '../../../parent_viewmodels/parent_signup_vm.dart';
import '../location_selection_screen.dart';
import '../step_indicator/step_indicator.dart';


class ParentPreferencesStepScreen extends StatelessWidget {
  const ParentPreferencesStepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ParentSignupViewModel>(
      builder: (context, vm, _) {
        final theme = Theme.of(context);

        return Scaffold(
          backgroundColor: AppColors.lightBackground,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
              onPressed: () {
                vm.previousStep();
                Navigator.of(context).maybePop();
              },
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
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // StepIndicator(
                  //   currentIndex: vm.currentStepIndex,
                  // ),
                  const SizedBox(height: 24),

                  AppText(
                    'Tutoring Preferences',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    'Share your location so we can match tutors nearby or for online lessons.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 24),

                  AppTextField(
                    label: 'Home Address',
                    hintText: 'Street, city, area',
                    onChanged: vm.updateAddress,
                    textInputAction: TextInputAction.newline,
                    errorText: vm.addressError,
                  ),
                  const SizedBox(height: 16),

                  AppText(
                    'Additional Notes (Optional)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    maxLines: 4,
                    onChanged: vm.updateNotes,
                    decoration: InputDecoration(
                      hintText:
                      'e.g., Preferred days, time, online/home, special needs, etc.',
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

                  // Error (for server errors only)
                  if (vm.errorMessage != null && vm.addressError == null) ...[
                    Text(
                      vm.errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  AppPrimaryButton(
                    label: 'Continue',
                    isLoading: vm.isLoading,
                    isDisabled: false,
                    onPressed: () {
                      final ok = vm.continueFromStep3();
                      if (ok) {
                        Navigator.push(context, MaterialPageRoute(builder: (_)=>ChangeNotifierProvider.value(value: vm,child: const LocationSelectionScreen(
                          showStepIndicator: true,
                        ),)));
                      }
                    },
                  ),
                ],
              ),
              ),
            ),
          ),
        );
      },
    );
  }
}
