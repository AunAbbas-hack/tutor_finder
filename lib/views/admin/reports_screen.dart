// lib/views/admin/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../admin_viewmodels/reports_vm.dart';
import '../../core/widgets/app_text.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/report_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = ReportsViewModel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.initialize();
        });
        return vm;
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: SafeArea(
          child: Consumer<ReportsViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading && vm.reports.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              }

              if (vm.errorMessage != null && vm.reports.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText(
                          vm.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => vm.initialize(),
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
                  ),
                );
              }

              return Column(
                children: [
                  // Header
                  _buildHeader(context, vm),
                  const SizedBox(height: 16),
                  // Search Bar
                  _buildSearchBar(context, vm),
                  const SizedBox(height: 16),
                  // Filter Tabs
                  _buildFilterTabs(context, vm),
                  const SizedBox(height: 16),
                  // Summary Card
                  _buildSummaryCard(context, vm),
                  const SizedBox(height: 16),
                  // Reports List
                  Expanded(
                    child: _buildReportsList(context, vm),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------- Header ----------
  Widget _buildHeader(BuildContext context, ReportsViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const AppText(
            'Reports',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textDark),
            onPressed: vm.isLoading ? null : () => vm.refresh(),
          ),
        ],
      ),
    );
  }

  // ---------- Search Bar ----------
  Widget _buildSearchBar(BuildContext context, ReportsViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search,
              color: AppColors.iconGrey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search reports...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
                onChanged: (value) => vm.setSearchQuery(value),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                color: AppColors.iconGrey,
                onPressed: () {
                  _searchController.clear();
                  vm.setSearchQuery('');
                },
              ),
          ],
        ),
      ),
    );
  }

  // ---------- Filter Tabs ----------
  Widget _buildFilterTabs(BuildContext context, ReportsViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              context,
              label: 'All',
              isSelected: vm.selectedStatus == null,
              onTap: () => vm.setStatusFilter(null),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              context,
              label: 'Pending',
              isSelected: vm.selectedStatus == ReportStatus.pending,
              onTap: () => vm.setStatusFilter(ReportStatus.pending),
              count: vm.pendingCount,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              context,
              label: 'In Progress',
              isSelected: vm.selectedStatus == ReportStatus.inProgress,
              onTap: () => vm.setStatusFilter(ReportStatus.inProgress),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              context,
              label: 'Resolved',
              isSelected: vm.selectedStatus == ReportStatus.resolved,
              onTap: () => vm.setStatusFilter(ReportStatus.resolved),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              context,
              label: 'Rejected',
              isSelected: vm.selectedStatus == ReportStatus.rejected,
              onTap: () => vm.setStatusFilter(ReportStatus.rejected),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int? count,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textGrey,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AppText(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------- Summary Card ----------
  Widget _buildSummaryCard(BuildContext context, ReportsViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A73E8), Color(0xFF4285F4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    'Total Reports',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    '${vm.totalReports}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    'Pending',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    '${vm.pendingCount}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Reports List ----------
  Widget _buildReportsList(BuildContext context, ReportsViewModel vm) {
    if (vm.reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.report_problem_outlined,
              size: 64,
              color: AppColors.iconGrey,
            ),
            const SizedBox(height: 16),
            const AppText(
              'No reports found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const AppText(
              'Reports will appear here',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => vm.refresh(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: vm.reports.length,
        itemBuilder: (context, index) {
          final report = vm.reports[index];
          return _buildReportCard(context, report, vm);
        },
      ),
    );
  }

  // ---------- Report Card ----------
  Widget _buildReportCard(
    BuildContext context,
    ReportModel report,
    ReportsViewModel vm,
  ) {
    final statusColor = vm.getStatusColor(report.status);
    final statusText = vm.getStatusText(report.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showReportDetails(context, report, vm),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Type Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTypeIcon(report.type),
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Type and Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          ReportModel.typeToString(report.type).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AppText(
                          vm.formatDate(report.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: AppText(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Description Preview
              AppText(
                report.description.length > 100
                    ? '${report.description.substring(0, 100)}...'
                    : report.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textGrey,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Report ID
              AppText(
                'ID: ${report.reportId.substring(0, 8)}...',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textLight,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(ReportType type) {
    switch (type) {
      case ReportType.tutor:
        return Icons.person_outline;
      case ReportType.booking:
        return Icons.calendar_today_outlined;
      case ReportType.payment:
        return Icons.payment_outlined;
      case ReportType.other:
        return Icons.report_problem_outlined;
    }
  }

  // ---------- Show Report Details Dialog ----------
  void _showReportDetails(
    BuildContext context,
    ReportModel report,
    ReportsViewModel vm,
  ) async {
    // Load user info
    final createdByUser = await vm.getUserInfo(report.createdByUser);
    final againstUser = report.againstUser != null
        ? await vm.getUserInfo(report.againstUser!)
        : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppText(
          'Report Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type
              _buildDetailRow('Type', ReportModel.typeToString(report.type)),
              const SizedBox(height: 12),
              // Status
              _buildDetailRow(
                'Status',
                vm.getStatusText(report.status),
                color: vm.getStatusColor(report.status),
              ),
              const SizedBox(height: 12),
              // Created By
              _buildDetailRow(
                'Reported By',
                createdByUser?.name ?? 'Unknown User',
              ),
              if (againstUser != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Reported Against',
                  againstUser.name,
                ),
              ],
              const SizedBox(height: 12),
              // Date
              _buildDetailRow('Date', vm.formatDate(report.createdAt)),
              const SizedBox(height: 12),
              // Description
              const AppText(
                'Description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              AppText(
                report.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
              ),
              if (report.adminNotes != null) ...[
                const SizedBox(height: 12),
                const AppText(
                  'Admin Notes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                AppText(
                  report.adminNotes!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const AppText('Close'),
          ),
          if (report.status == ReportStatus.pending ||
              report.status == ReportStatus.inProgress) ...[
            TextButton(
              onPressed: () async {
                final success = await vm.updateReportStatus(
                  reportId: report.reportId,
                  status: ReportStatus.resolved,
                );
                if (success && context.mounted) {
                  Get.back();
                  Get.snackbar(
                    'Success',
                    'Report marked as resolved',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.success,
                    colorText: Colors.white,
                  );
                }
              },
              child: const AppText(
                'Mark Resolved',
                style: TextStyle(color: AppColors.success),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: AppText(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textGrey,
            ),
          ),
        ),
        Expanded(
          child: AppText(
            value,
            style: TextStyle(
              fontSize: 13,
              color: color ?? AppColors.textDark,
              fontWeight: color != null ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
