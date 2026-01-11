// lib/data/models/dashboard_metrics_model.dart

/// Model for admin dashboard summary metrics
class DashboardMetricsModel {
  final int totalUsers;
  final int pendingVerifications;
  final int activeBookings;
  final double totalRevenue; // In currency (e.g., PKR, USD)

  // Growth/change indicators
  final double? usersGrowthPercentage; // e.g., 12.0 for +12%
  final int? newBookingsToday;
  final double? revenueGrowthPercentage;
  
  final String? pendingVerifStatus; // e.g., "Requires action"

  const DashboardMetricsModel({
    required this.totalUsers,
    required this.pendingVerifications,
    required this.activeBookings,
    required this.totalRevenue,
    this.usersGrowthPercentage,
    this.newBookingsToday,
    this.revenueGrowthPercentage,
    this.pendingVerifStatus,
  });

  DashboardMetricsModel copyWith({
    int? totalUsers,
    int? pendingVerifications,
    int? activeBookings,
    double? totalRevenue,
    double? usersGrowthPercentage,
    int? newBookingsToday,
    double? revenueGrowthPercentage,
    String? pendingVerifStatus,
  }) {
    return DashboardMetricsModel(
      totalUsers: totalUsers ?? this.totalUsers,
      pendingVerifications: pendingVerifications ?? this.pendingVerifications,
      activeBookings: activeBookings ?? this.activeBookings,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      usersGrowthPercentage: usersGrowthPercentage ?? this.usersGrowthPercentage,
      newBookingsToday: newBookingsToday ?? this.newBookingsToday,
      revenueGrowthPercentage: revenueGrowthPercentage ?? this.revenueGrowthPercentage,
      pendingVerifStatus: pendingVerifStatus ?? this.pendingVerifStatus,
    );
  }

  /// Format revenue for display (e.g., "$12.4k", "$1.2M")
  String get formattedRevenue {
    if (totalRevenue >= 1000000) {
      return '\$${(totalRevenue / 1000000).toStringAsFixed(1)}M';
    } else if (totalRevenue >= 1000) {
      return '\$${(totalRevenue / 1000).toStringAsFixed(1)}k';
    } else {
      return '\$${totalRevenue.toStringAsFixed(0)}';
    }
  }

  /// Format users growth percentage (e.g., "+12% this week")
  String? get formattedUsersGrowth {
    if (usersGrowthPercentage == null) return null;
    final sign = usersGrowthPercentage! >= 0 ? '+' : '';
    return '$sign${usersGrowthPercentage!.toStringAsFixed(0)}% this week';
  }

  /// Format revenue growth percentage (e.g., "+5% vs last month")
  String? get formattedRevenueGrowth {
    if (revenueGrowthPercentage == null) return null;
    final sign = revenueGrowthPercentage! >= 0 ? '+' : '';
    return '$sign${revenueGrowthPercentage!.toStringAsFixed(0)}% vs last month';
  }
}
