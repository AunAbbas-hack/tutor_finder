// lib/views/admin/finance_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../admin_viewmodels/finance_vm.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';
import '../../data/models/payout_request_model.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  @override
  Widget build(BuildContext context) {
    final spacing = _FinanceSpacing.fromSize(MediaQuery.of(context).size);

    return ChangeNotifierProvider(
      create: (_) {
        final vm = FinanceViewModel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          vm.initialize();
        });
        return vm;
      },
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: SafeArea(
          child: Consumer<FinanceViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading && vm.pendingRequests.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (vm.errorMessage != null && vm.pendingRequests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        vm.errorMessage ?? 'Failed to load data',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: spacing.itemGap),
                      ElevatedButton(
                        onPressed: vm.initialize,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: Size(spacing.buttonHeight * 2.4, spacing.buttonHeight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(spacing.cardRadius),
                          ),
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

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: vm.initialize,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.horizontal,
                    vertical: spacing.vertical,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, spacing),
                      SizedBox(height: spacing.sectionGap),
                      _buildSummaryCard(context, vm, spacing),
                      SizedBox(height: spacing.sectionGap),
                      _buildPendingHeader(context, vm, spacing),
                      SizedBox(height: spacing.itemGap),
                      if (vm.pendingRequests.isEmpty)
                        _buildEmptyState(spacing)
                      else
                        ...vm.pendingRequests.map(
                          (request) => Padding(
                            padding: EdgeInsets.only(bottom: spacing.itemGap),
                            child: _buildRequestCard(context, request, vm, spacing),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, _FinanceSpacing spacing) {
    final textTheme = Theme.of(context).textTheme;
    final canPop = Navigator.of(context).canPop();

    return Row(
      children: [
        if (canPop)
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        if (canPop) SizedBox(width: spacing.smallGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                'Withdrawal Requests',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: spacing.smallGap * 0.6),
              AppText(
                'Manage tutor payouts',
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textGrey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, FinanceViewModel vm, _FinanceSpacing spacing) {
    final totalAmount = vm.formatAmount(vm.totalPendingAmount);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacing.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4FACFE), Color(0xFF2596FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(spacing.cardRadius * 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: spacing.cardRadius,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'Total Pending Payouts',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: spacing.smallGap),
                AppText(
                  totalAmount,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: (Theme.of(context).textTheme.headlineSmall?.fontSize ?? 24) * 1.1,
                      ),
                ),
                SizedBox(height: spacing.smallGap),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.chipPadding,
                    vertical: spacing.smallGap * 0.6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(spacing.cardRadius),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: AppText(
                    '${vm.pendingCount} Requests',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: spacing.smallGap),
          Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white.withOpacity(0.9),
            size: spacing.avatarSize * 0.8,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingHeader(BuildContext context, FinanceViewModel vm, _FinanceSpacing spacing) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                'Pending Requests',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
              ),
              SizedBox(height: spacing.smallGap * 0.5),
              AppText(
                'Review and approve payouts',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textGrey,
                    ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(spacing.cardRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: spacing.cardRadius * 0.7,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: PopupMenuButton<PayoutSort>(
            initialValue: vm.sortBy,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(spacing.cardRadius),
            ),
            onSelected: vm.updateSort,
            position: PopupMenuPosition.under,
            itemBuilder: (context) => [
              _buildSortItem('Newest first', PayoutSort.dateDesc, vm.sortBy),
              _buildSortItem('Amount high → low', PayoutSort.amountDesc, vm.sortBy),
              _buildSortItem('Name A → Z', PayoutSort.nameAsc, vm.sortBy),
            ],
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.chipPadding,
                vertical: spacing.smallGap * 0.7,
              ),
              child: Row(
                children: [
                  const Icon(Icons.sort_rounded, color: AppColors.textDark, size: 22),
                  SizedBox(width: spacing.smallGap * 0.7),
                  AppText(
                    'Sort By',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textDark,
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
  }

  PopupMenuItem<PayoutSort> _buildSortItem(String label, PayoutSort value, PayoutSort selected) {
    return PopupMenuItem<PayoutSort>(
      value: value,
      child: Row(
        children: [
          Icon(
            value == selected ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
            color: value == selected ? AppColors.primary : AppColors.textLight,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    PayoutRequestModel request,
    FinanceViewModel vm,
    _FinanceSpacing spacing,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacing.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(spacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: spacing.cardRadius,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvatarBadge(
                name: request.tutorName,
                colors: request.avatarColors,
                size: spacing.avatarSize,
              ),
              SizedBox(width: spacing.smallGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      request.tutorName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: spacing.smallGap * 0.5),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textLight),
                        SizedBox(width: spacing.smallGap * 0.5),
                        AppText(
                          'Requested on ${vm.formatDate(request.requestedAt)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppText(
                    request.formattedAmount,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: spacing.smallGap * 0.5),
                  Row(
                    children: [
                      Icon(request.methodIcon, size: 18, color: AppColors.primary),
                      SizedBox(width: spacing.smallGap * 0.4),
                      AppText(
                        request.methodLabel,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: spacing.itemGap),
          Wrap(
            runSpacing: spacing.smallGap,
            spacing: spacing.itemGap,
            children: [
              _buildInfoTile(
                label: request.method == PayoutMethod.bankTransfer ? 'Account Title' : 'Wallet Name',
                value: request.accountTitle,
                spacing: spacing,
              ),
              _buildInfoTile(
                label: request.method == PayoutMethod.bankTransfer ? 'Account / IBAN' : 'Wallet Number',
                value: request.accountNumber,
                spacing: spacing,
              ),
              if (request.phoneNumber != null && request.phoneNumber!.isNotEmpty)
                _buildInfoTile(
                  label: 'Phone Number',
                  value: request.phoneNumber!,
                  spacing: spacing,
                ),
            ],
          ),
          SizedBox(height: spacing.itemGap),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => vm.reject(request.id),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    foregroundColor: const Color(0xFFB91C1C),
                    backgroundColor: const Color(0xFFFFF1F2),
                    minimumSize: Size.fromHeight(spacing.buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(spacing.cardRadius),
                    ),
                  ),
                  child: const Text(
                    'Reject',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: spacing.smallGap),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => vm.approve(request.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: Size.fromHeight(spacing.buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(spacing.cardRadius),
                    ),
                  ),
                  child: const Text(
                    'Approve Payout',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    required _FinanceSpacing spacing,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: spacing.avatarSize * 1.6,
        maxWidth: spacing.avatarSize * 3.6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            label,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: spacing.smallGap * 0.4),
          AppText(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(_FinanceSpacing spacing) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacing.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(spacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: spacing.cardRadius,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            color: AppColors.textLight,
            size: spacing.avatarSize,
          ),
          SizedBox(height: spacing.itemGap),
          const AppText(
            'No pending requests',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: spacing.smallGap),
          const AppText(
            'Approved or rejected requests will appear here',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  final String name;
  final List<Color> colors;
  final double size;

  const _AvatarBadge({
    required this.name,
    required this.colors,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFromName(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: size * 0.2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.32,
          ),
        ),
      ),
    );
  }

  String _initialsFromName(String fullName) {
    final parts = fullName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _FinanceSpacing {
  final double horizontal;
  final double vertical;
  final double sectionGap;
  final double itemGap;
  final double cardRadius;
  final double cardPadding;
  final double avatarSize;
  final double chipPadding;
  final double buttonHeight;
  final double smallGap;

  _FinanceSpacing({
    required this.horizontal,
    required this.vertical,
    required this.sectionGap,
    required this.itemGap,
    required this.cardRadius,
    required this.cardPadding,
    required this.avatarSize,
    required this.chipPadding,
    required this.buttonHeight,
    required this.smallGap,
  });

  factory _FinanceSpacing.fromSize(Size size) {
    final width = size.width;
    final height = size.height;

    double clamp(double value, double min, double max) => value.clamp(min, max);

    return _FinanceSpacing(
      horizontal: clamp(width * 0.06, 16, 28),
      vertical: clamp(height * 0.02, 12, 24),
      sectionGap: clamp(height * 0.025, 16, 28),
      itemGap: clamp(height * 0.018, 10, 22),
      cardRadius: clamp(width * 0.03, 12, 18),
      cardPadding: clamp(width * 0.04, 14, 24),
      avatarSize: clamp(width * 0.16, 48, 64),
      chipPadding: clamp(width * 0.02, 8, 12),
      buttonHeight: clamp(height * 0.055, 46, 56),
      smallGap: clamp(height * 0.01, 6, 12),
    );
  }
}
