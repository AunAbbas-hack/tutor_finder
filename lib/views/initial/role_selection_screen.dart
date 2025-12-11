import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutor_finder/views/auth/parent_signup/parent_signup_screen_1.dart';
import 'package:tutor_finder/views/auth/tutor_signup/tutor_signup_screen.dart';

import '../../core/widgets/app_primary_button.dart';
import '../../core/widgets/role_option_card.dart';
import '../../data/models/user_model.dart';
import '../../parent_viewmodels/auth_vm.dart';



class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthViewModel>(
      create: (_) => AuthViewModel(),
      child: const _RoleSelectionView(),
    );
  }
}

class _RoleSelectionView extends StatelessWidget {
  const _RoleSelectionView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.black87,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Text(
          'How will you be using our app?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Consumer<AuthViewModel>(
            builder: (context, vm, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // Parent card
                  RoleOptionCard(
                    icon: Icons.family_restroom,
                    title: 'Parent',
                    subtitle: 'Find and manage tutors for your child',
                    isSelected: vm.selectedRole == UserRole.parent,
                    onTap: () => vm.selectRole(UserRole.parent),
                  ),

                  const SizedBox(height: 16),

                  // Tutor card
                  RoleOptionCard(
                    icon: Icons.school,
                    title: 'Tutor',
                    subtitle: 'Offer your expertise and start tutoring',
                    isSelected: vm.selectedRole == UserRole.tutor,
                    onTap: () => vm.selectRole(UserRole.tutor),
                  ),

                  const Spacer(),

                  // Continue button
                  AppPrimaryButton(
                    label: 'Continue',
                    isLoading: vm.isLoading,
                    isDisabled: !vm.hasSelectedRole,
                    onPressed: () {
                      // yahan sirf navigation hoga
                      final role = vm.selectedRole;
                      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
                      if (role == UserRole.parent) {
                        Navigator.push(context, MaterialPageRoute(builder: (_)=>ParentSignupFlow()));
                      } else if (role == UserRole.tutor) {
                        // TODO: Tutor signup screen pr jao
                        Navigator.push(context, MaterialPageRoute(builder: (_)=>TutorSignupScreen()));

                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  // Already have account? Log in
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Login screen route
                        // Navigator.pushNamed(context, AppRoutes.login);
                      },
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Already have an account? ',
                            ),
                            TextSpan(
                              text: 'Log in',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF1A73E8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
