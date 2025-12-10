import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_text.dart';

/// Reusable subject button for "Explore by Subject" section
class SubjectButton extends StatelessWidget {
  final String subject;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const SubjectButton({
    super.key,
    required this.subject,
    required this.icon,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textDark,
              size: 20,
            ),
            const SizedBox(width: 8),
            AppText(
              subject,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

