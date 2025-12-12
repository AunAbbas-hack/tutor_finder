import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutor_finder/views/auth/parent_signup/parent_signup_screen_3.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_text.dart';
import '../../../core/widgets/app_textfield.dart';
import '../../../parent_viewmodels/parent_signup_vm.dart';


class ParentChildDetailsStepScreen extends StatelessWidget {
  const ParentChildDetailsStepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ParentSignupViewModel>(
      builder: (context, vm, _) {
        final theme = Theme.of(context);

        return Scaffold(
          backgroundColor: AppColors.background,
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
                    'Tell us about your child',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    'We’ll use this info to find tutors that match your child’s level.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 24),

                  AppTextField(
                    label: 'Child’s Full Name',
                    hintText: 'Enter your child’s name',
                    onChanged: vm.updateChildName,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    label: 'Grade / Class',
                    hintText: 'e.g., 5th Grade, O-Levels',
                    onChanged: vm.updateChildGrade,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  AppTextField(
                    label: 'School / College',
                    hintText: 'Enter school or college name',
                    onChanged: vm.updateChildSchool,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 16),

                  if (vm.errorMessage != null) ...[
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
                    isDisabled: !vm.isStep2Valid,
                    onPressed: () {
                      final ok = vm.continueFromStep2();
                      if (ok) {
                        Navigator.push(context, MaterialPageRoute(builder:
                        (context) => ChangeNotifierProvider.value(value: vm,child: const ParentPreferencesStepScreen(),)));
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
