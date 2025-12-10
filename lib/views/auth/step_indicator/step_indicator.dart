import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

// class StepIndicator extends StatelessWidget {
//   final int currentIndex; // 0-based
//
//   const StepIndicator({
//     super.key,
//     required this.currentIndex,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final int totalSteps=4;
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: List.generate(totalSteps, (index) {
//         final isActive = index == currentIndex;
//
//         return AnimatedContainer(
//           duration: const Duration(milliseconds: 200),
//           margin: const EdgeInsets.symmetric(horizontal: 4),
//           height: 6,
//           width: isActive ? 28 : 20,
//           decoration: BoxDecoration(
//             color: isActive ? AppColors.primary : AppColors.border,
//             borderRadius: BorderRadius.circular(8),
//           ),
//         );
//       }),
//     );
//   }
// }
