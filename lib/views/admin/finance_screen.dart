// lib/views/admin/finance_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../admin_viewmodels/finance_vm.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text.dart';

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
              if (vm.isLoading && vm.pendingPayments.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (vm.errorMessage != null && vm.pendingPayments.isEmpty) {
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
                      if (vm.pendingPayments.isEmpty)
                        _buildEmptyState(spacing)
                      else
                        ...vm.pendingPayments.map(
                          (paymentDisplay) => Padding(
                            padding: EdgeInsets.only(bottom: spacing.itemGap),
                            child: _buildPaymentCard(context, paymentDisplay, vm, spacing),
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
                'Payment Management',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: spacing.smallGap * 0.6),
              AppText(
                'Pay tutors for completed bookings',
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
                  'Total Pending Payments',
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
                'Pending Payments',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
              ),
              SizedBox(height: spacing.smallGap * 0.5),
              AppText(
                'Mark payments as paid to tutors',
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
          child: PopupMenuButton<PaymentSort>(
            initialValue: vm.sortBy,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(spacing.cardRadius),
            ),
            onSelected: vm.updateSort,
            position: PopupMenuPosition.under,
            itemBuilder: (context) => [
              _buildSortItem('Newest first', PaymentSort.dateDesc, vm.sortBy),
              _buildSortItem('Amount high → low', PaymentSort.amountDesc, vm.sortBy),
              _buildSortItem('Name A → Z', PaymentSort.nameAsc, vm.sortBy),
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

  PopupMenuItem<PaymentSort> _buildSortItem(String label, PaymentSort value, PaymentSort selected) {
    return PopupMenuItem<PaymentSort>(
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

  Widget _buildPaymentCard(
    BuildContext context,
    PaymentDisplayModel paymentDisplay,
    FinanceViewModel vm,
    _FinanceSpacing spacing,
  ) {
    final payment = paymentDisplay.payment;
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
                name: paymentDisplay.tutorName,
                colors: [paymentDisplay.avatarColor1, paymentDisplay.avatarColor2],
                size: spacing.avatarSize,
              ),
              SizedBox(width: spacing.smallGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      paymentDisplay.tutorName,
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
                          'Paid on ${vm.formatDate(payment.completedAt ?? payment.createdAt)}',
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
                    vm.formatAmount(payment.amount, symbol: 'Rs '),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: spacing.smallGap * 0.5),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.smallGap * 0.7,
                      vertical: spacing.smallGap * 0.3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(spacing.cardRadius * 0.5),
                    ),
                    child: AppText(
                      'Paid by ${paymentDisplay.parentName}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                label: 'Booking ID',
                value: payment.bookingId.substring(0, 8),
                spacing: spacing,
              ),
              _buildInfoTile(
                label: 'Payment ID',
                value: payment.paymentId.substring(0, 8),
                spacing: spacing,
              ),
              if (payment.stripeSessionId != null)
                _buildInfoTile(
                  label: 'Stripe Session',
                  value: payment.stripeSessionId!.substring(0, 12),
                  spacing: spacing,
                ),
            ],
          ),
          SizedBox(height: spacing.itemGap),
          if (!payment.tutorPaid)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await vm.markAsPaidToTutor(payment.paymentId);
                  if (vm.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(vm.errorMessage!),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment marked as paid to tutor'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size.fromHeight(spacing.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(spacing.cardRadius),
                  ),
                ),
                child: const Text(
                  'Mark as Paid to Tutor',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(spacing.cardPadding * 0.7),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(spacing.cardRadius),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  SizedBox(width: spacing.smallGap * 0.5),
                  AppText(
                    'Paid to Tutor on ${vm.formatDate(payment.tutorPaidAt!)}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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
