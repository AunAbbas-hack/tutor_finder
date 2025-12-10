import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_text.dart';

/// Reusable card for recommended tutors (vertical list)
class RecommendedTutorCard extends StatelessWidget {
  final String name;
  final double rating;
  final int reviewCount;
  final String specialization;
  final String imageUrl;
  final bool isSaved;
  final VoidCallback? onTap;
  final VoidCallback? onSaveTap;

  const RecommendedTutorCard({
    super.key,
    required this.name,
    required this.rating,
    required this.reviewCount,
    required this.specialization,
    this.imageUrl = '',
    this.isSaved = false,
    this.onTap,
    this.onSaveTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.lightBackground,
                image: imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl.isEmpty
                  ? const Icon(
                      Icons.person,
                      size: 40,
                      color: AppColors.iconGrey,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Rating
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      AppText(
                        '$rating ($reviewCount reviews)',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AppText(
                    'Specializes in $specialization',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Save Icon
            GestureDetector(
              onTap: onSaveTap,
              child: Icon(
                isSaved ? Icons.favorite : Icons.favorite_border,
                color: isSaved ? AppColors.primary : AppColors.iconGrey,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

