// lib/views/admin/tutor_approve_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../admin_viewmodels/tutor_approve_vm.dart';
import '../../core/widgets/app_text.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/tutor_model.dart';
import '../../data/models/user_model.dart';
import 'package:intl/intl.dart';

class TutorApproveScreen extends StatefulWidget {
  final String tutorId;
  final String verificationId; // Optional verification ID for display

  const TutorApproveScreen({
    super.key,
    required this.tutorId,
    this.verificationId = '',
  });

  @override
  State<TutorApproveScreen> createState() => _TutorApproveScreenState();
}

class _TutorApproveScreenState extends State<TutorApproveScreen> {
  final TextEditingController _rejectionReasonController = TextEditingController();

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = TutorApproveViewModel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.loadTutorData(widget.tutorId);
        });
        return vm;
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: SafeArea(
          child: Consumer<TutorApproveViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading && vm.user == null) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              }

              if (vm.errorMessage != null && vm.user == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText(
                        vm.errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => vm.loadTutorData(widget.tutorId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const AppText(
                          'Retry',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (vm.user == null || vm.tutor == null) {
                return const Center(
                  child: AppText(
                    'Tutor data not found',
                    style: TextStyle(color: AppColors.error),
                  ),
                );
              }

              return Column(
                children: [
                  // Header
                  _buildHeader(context, vm),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tutor Profile Section
                          _buildTutorProfile(context, vm),
                          const SizedBox(height: 24),
                          // Identity Verification Section
                          _buildIdentityVerification(context, vm),
                          const SizedBox(height: 24),
                          // Academic Credentials Section
                          _buildAcademicCredentials(context, vm),
                          const SizedBox(height: 24),
                          // Certifications Section
                          _buildCertifications(context, vm),
                          const SizedBox(height: 24),
                          // Portfolio & Documents Section
                          _buildPortfolioSection(context, vm),
                          const SizedBox(height: 24),
                          // Rejection Reason Section
                          _buildRejectionReason(context, vm),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  // Footer Buttons
                  _buildFooterButtons(context, vm),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------- Header ----------
  Widget _buildHeader(BuildContext context, TutorApproveViewModel vm) {
    final verificationId = widget.verificationId.isNotEmpty
        ? widget.verificationId
        : '#${widget.tutorId.substring(0, 4).toUpperCase()}';
    
    final status = vm.user?.status ?? UserStatus.pending;
    final statusText = status == UserStatus.pending
        ? 'Pending'
        : status == UserStatus.active
            ? 'Approved'
            : 'Rejected';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          // Title
          Expanded(
            child: AppText(
              'Verification $verificationId',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: status == UserStatus.pending
                  ? const Color(0xFFE3F2FD)
                  : status == UserStatus.active
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: AppText(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: status == UserStatus.pending
                    ? AppColors.primary
                    : status == UserStatus.active
                        ? AppColors.success
                        : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Tutor Profile ----------
  Widget _buildTutorProfile(BuildContext context, TutorApproveViewModel vm) {
    final user = vm.user!;
    final tutor = vm.tutor!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Picture
          Container(
            width: isTablet ? 80 : 64,
            height: isTablet ? 80 : 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
              image: user.imageUrl != null && user.imageUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(user.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: user.imageUrl == null || user.imageUrl!.isEmpty
                ? Center(
                    child: AppText(
                      user.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: isTablet ? 32 : 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          // Name and Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  user.name,
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: isTablet ? 16 : 14,
                      color: AppColors.textGrey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: AppText(
                        user.email,
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: AppColors.textGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (tutor.subjects.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  AppText(
                    '${tutor.subjects.first} Tutor',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    AppText(
                      tutor.experience != null
                          ? '${tutor.experience} Years Experience'
                          : 'New Tutor',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Identity Verification ----------
  Widget _buildIdentityVerification(BuildContext context, TutorApproveViewModel vm) {
    final tutor = vm.tutor!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    if (tutor.cnicFrontUrl == null && tutor.cnicBackUrl == null) {
      return const SizedBox.shrink();
    }

    final hasBoth = tutor.cnicFrontUrl != null && tutor.cnicBackUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Identity Verification',
          style: TextStyle(
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.badge_outlined,
                      color: AppColors.primary,
                      size: isTablet ? 28 : 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Government ID (CNIC)',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AppText(
                          'Uploaded ${DateFormat('MMM dd, yyyy').format(DateTime.now().subtract(const Duration(days: 5)))}',
                          style: TextStyle(
                            fontSize: isTablet ? 13 : 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // CNIC Images
              if (hasBoth) ...[
                // Front Image
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Front Side',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildImagePreview(tutor.cnicFrontUrl!, isTablet),
                    const SizedBox(height: 16),
                  ],
                ),
                // Back Image
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Back Side',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildImagePreview(tutor.cnicBackUrl!, isTablet),
                    const SizedBox(height: 16),
                  ],
                ),
              ] else ...[
                _buildImagePreview(
                  tutor.cnicFrontUrl ?? tutor.cnicBackUrl!,
                  isTablet,
                ),
                const SizedBox(height: 16),
              ],
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: vm.cnicApproved ? null : () => vm.approveCnic(),
                      icon: const Icon(Icons.check, size: 18),
                      label: const AppText(
                        'Approve',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 12 : 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: vm.cnicRejected ? null : () => vm.rejectCnic(),
                      icon: const Icon(Icons.close, size: 18),
                      label: const AppText(
                        'Reject',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: vm.cnicRejected
                            ? AppColors.error
                            : AppColors.textDark,
                        side: BorderSide(
                          color: vm.cnicRejected
                              ? AppColors.error
                              : AppColors.border,
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 12 : 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Image Preview Widget ----------
  Widget _buildImagePreview(String imageUrl, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: isTablet ? 200 : 150,
          decoration: BoxDecoration(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: AppColors.primary,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      AppText(
                        'Failed to load image',
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            // TODO: Open full size image/document viewer
          },
          child: Row(
            children: [
              const Icon(
                Icons.visibility,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 6),
              AppText(
                'View Full Size',
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Academic Credentials ----------
  Widget _buildAcademicCredentials(BuildContext context, TutorApproveViewModel vm) {
    final tutor = vm.tutor!;
    
    if (tutor.education.isEmpty) {
      return const SizedBox.shrink();
    }

    final education = tutor.education.first;
    final uploadDate = DateTime.now().subtract(const Duration(days: 7)); // Mock date

    return _buildDocumentSection(
      context: context,
      title: 'Academic Credentials',
      documentTitle: education.degree,
      uploadDate: uploadDate,
      fileUrl: null, // Education doesn't have file URL in model
      isApproved: vm.academicApproved,
      isRejected: vm.academicRejected,
      onApprove: () => vm.approveAcademic(),
      onReject: () => vm.rejectAcademic(),
      icon: Icons.school_outlined,
    );
  }

  // ---------- Certifications ----------
  Widget _buildCertifications(BuildContext context, TutorApproveViewModel vm) {
    final tutor = vm.tutor!;
    
    if (tutor.certifications.isEmpty) {
      return const SizedBox.shrink();
    }

    final certification = tutor.certifications.first;
    final uploadDate = DateTime.now().subtract(const Duration(days: 3)); // Mock date

    return _buildDocumentSection(
      context: context,
      title: 'Certifications',
      documentTitle: certification.title,
      uploadDate: uploadDate,
      fileUrl: null, // Certifications don't have file URL in model
      isApproved: vm.certificationApproved,
      isRejected: vm.certificationRejected,
      onApprove: () => vm.approveCertification(),
      onReject: () => vm.rejectCertification(),
      icon: Icons.verified_outlined,
    );
  }

  // ---------- Portfolio & Documents ----------
  Widget _buildPortfolioSection(BuildContext context, TutorApproveViewModel vm) {
    final tutor = vm.tutor!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    if (tutor.portfolioDocuments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Portfolio & Documents',
          style: TextStyle(
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.folder_outlined,
                      color: AppColors.primary,
                      size: isTablet ? 28 : 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          '${tutor.portfolioDocuments.length} Document${tutor.portfolioDocuments.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AppText(
                          'Portfolio files uploaded by tutor',
                          style: TextStyle(
                            fontSize: isTablet ? 13 : 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Portfolio Documents List
              ...tutor.portfolioDocuments.asMap().entries.map((entry) {
                final index = entry.key;
                final document = entry.value;
                return Column(
                  children: [
                    _buildPortfolioDocumentItem(document, isTablet),
                    if (index < tutor.portfolioDocuments.length - 1)
                      Divider(
                        height: 24,
                        color: AppColors.border,
                        thickness: 1,
                      ),
                  ],
                );
              }),
              const SizedBox(height: 16),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: vm.portfolioApproved ? null : () => vm.approvePortfolio(),
                      icon: const Icon(Icons.check, size: 18),
                      label: const AppText(
                        'Approve',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 12 : 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: vm.portfolioRejected ? null : () => vm.rejectPortfolio(),
                      icon: const Icon(Icons.close, size: 18),
                      label: const AppText(
                        'Reject',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: vm.portfolioRejected
                            ? AppColors.error
                            : AppColors.textDark,
                        side: BorderSide(
                          color: vm.portfolioRejected
                              ? AppColors.error
                              : AppColors.border,
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 12 : 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Portfolio Document Item ----------
  Widget _buildPortfolioDocumentItem(PortfolioDocument document, bool isTablet) {
    IconData iconData;
    Color iconColor;
    if (document.fileType.toLowerCase() == 'pdf') {
      iconData = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (document.fileType.toLowerCase().contains('image') ||
               document.fileType.toLowerCase() == 'jpg' ||
               document.fileType.toLowerCase() == 'jpeg' ||
               document.fileType.toLowerCase() == 'png') {
      iconData = Icons.image;
      iconColor = AppColors.primary;
    } else {
      iconData = Icons.insert_drive_file;
      iconColor = AppColors.primary;
    }

    return InkWell(
      onTap: () {
        // TODO: Open document viewer or download
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: isTablet ? 48 : 40,
              height: isTablet ? 48 : 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                iconData,
                color: iconColor,
                size: isTablet ? 24 : 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    document.fileName,
                    style: TextStyle(
                      fontSize: isTablet ? 15 : 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      AppText(
                        document.fileSize,
                        style: TextStyle(
                          fontSize: isTablet ? 12 : 11,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: AppText(
                          document.fileType.toUpperCase(),
                          style: TextStyle(
                            fontSize: isTablet ? 10 : 9,
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.download_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              onPressed: () {
                // TODO: Implement download functionality
              },
              tooltip: 'Download',
            ),
            IconButton(
              icon: const Icon(
                Icons.open_in_new,
                color: AppColors.primary,
                size: 20,
              ),
              onPressed: () {
                // TODO: Open document in viewer
              },
              tooltip: 'View',
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Document Section Builder ----------
  Widget _buildDocumentSection({
    required BuildContext context,
    required String title,
    required String documentTitle,
    required DateTime uploadDate,
    String? fileUrl,
    required bool isApproved,
    required bool isRejected,
    required VoidCallback onApprove,
    required VoidCallback onReject,
    required IconData icon,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          title,
          style: TextStyle(
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primary,
                      size: isTablet ? 28 : 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Document Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          documentTitle,
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AppText(
                          'Uploaded ${dateFormat.format(uploadDate)}',
                          style: TextStyle(
                            fontSize: isTablet ? 13 : 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (fileUrl != null) ...[
                const SizedBox(height: 12),
                // Image Preview
                Container(
                  width: double.infinity,
                  height: isTablet ? 200 : 150,
                  decoration: BoxDecoration(
                    color: AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      fileUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppColors.primary,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              AppText(
                                'Failed to load image',
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 12,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    // TODO: Open full size image/document viewer
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.visibility,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      AppText(
                        'View Full Size',
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isApproved ? null : onApprove,
                      icon: const Icon(Icons.check, size: 18),
                      label: const AppText(
                        'Approve',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isApproved
                            ? AppColors.success
                            : AppColors.success,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 12 : 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isRejected ? null : onReject,
                      icon: const Icon(Icons.close, size: 18),
                      label: const AppText(
                        'Reject',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isRejected
                            ? AppColors.error
                            : AppColors.textDark,
                        side: BorderSide(
                          color: isRejected
                              ? AppColors.error
                              : AppColors.border,
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 12 : 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Rejection Reason ----------
  Widget _buildRejectionReason(BuildContext context, TutorApproveViewModel vm) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Rejection Reason (Optional for Approval)',
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _rejectionReasonController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Please specify why the application is being rejected...',
              hintStyle: TextStyle(
                color: AppColors.textGrey,
                fontSize: isTablet ? 14 : 12,
              ),
              border: InputBorder.none,
            ),
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: AppColors.textDark,
            ),
            onChanged: (value) => vm.setRejectionReason(value.isEmpty ? null : value),
          ),
        ),
      ],
    );
  }

  // ---------- Footer Buttons ----------
  Widget _buildFooterButtons(BuildContext context, TutorApproveViewModel vm) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: vm.isLoading
                    ? null
                    : () async {
                        final success = await vm.rejectTutor();
                        if (success && context.mounted) {
                          Navigator.of(context).pop(true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tutor rejected successfully'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        } else if (!success && context.mounted && vm.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(vm.errorMessage!),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: EdgeInsets.symmetric(
                    vertical: isTablet ? 16 : 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: AppText(
                  'Reject Tutor',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: vm.isLoading
                    ? null
                    : () async {
                        final success = await vm.approveTutor();
                        if (success && context.mounted) {
                          Navigator.of(context).pop(true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tutor approved successfully'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } else if (!success && context.mounted && vm.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(vm.errorMessage!),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(
                    vertical: isTablet ? 16 : 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: AppText(
                  'Approve Tutor',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
