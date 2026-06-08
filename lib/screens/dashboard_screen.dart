// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final stats = provider.dashboardStats;
    final currency = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  Text('Computer Laboratory Overview', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                ],
              ),
              const Spacer(),
              Text(DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 24),
          // Stats Cards
          Row(
            children: [
              _StatCard(
                title: 'Total Items',
                value: '${stats['totalItems'] ?? 0}',
                icon: Icons.inventory_2_rounded,
                color: AppTheme.primary,
                subtitle: '${stats['totalEquipmentRecords'] ?? 0} equipment types',
              ),
              const SizedBox(width: 16),
              _StatCard(
                title: 'Total Value',
                value: currency.format(stats['totalValue'] ?? 0),
                icon: Icons.attach_money_rounded,
                color: AppTheme.secondary,
                subtitle: 'Inventory asset value',
              ),
              const SizedBox(width: 16),
              _StatCard(
                title: 'Active Items',
                value: '${stats['activeItems'] ?? 0}',
                icon: Icons.check_circle_rounded,
                color: AppTheme.success,
                subtitle: 'Currently operational',
              ),
              const SizedBox(width: 16),
              _StatCard(
                title: 'Under Repair',
                value: '${stats['underRepair'] ?? 0}',
                icon: Icons.build_rounded,
                color: AppTheme.warning,
                subtitle: 'Awaiting repair',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatCard(
                title: 'Borrowed',
                value: '${stats['borrowed'] ?? 0}',
                icon: Icons.swap_horiz_rounded,
                color: AppTheme.accent,
                subtitle: 'Currently checked out',
              ),
              const SizedBox(width: 16),
              _StatCard(
                title: 'Overdue',
                value: '${stats['overdue'] ?? 0}',
                icon: Icons.warning_rounded,
                color: AppTheme.error,
                subtitle: 'Past return date',
              ),
              const SizedBox(width: 16),
              _StatCard(
                title: 'Scheduled Maintenance',
                value: '${stats['scheduledMaintenance'] ?? 0}',
                icon: Icons.event_rounded,
                color: AppTheme.primaryLight,
                subtitle: 'Upcoming maintenance',
              ),
              const SizedBox(width: 16),
              _StatCard(
                title: 'Laboratories',
                value: '${provider.laboratories.length}',
                icon: Icons.meeting_room_rounded,
                color: const Color(0xFF0891B2),
                subtitle: 'Active labs',
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Charts Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _StatusPieChart(provider: provider)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _RecentActivity(provider: provider)),
            ],
          ),
          const SizedBox(height: 16),
          // Recent Equipment
          _RecentEquipmentTable(provider: provider),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                  Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPieChart extends StatelessWidget {
  final AppProvider provider;
  const _StatusPieChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final equipment = provider.equipment;
    final counts = <String, int>{};
    for (var eq in equipment) {
      counts[eq.status] = (counts[eq.status] ?? 0) + 1;
    }

    final colors = {
      'active': AppTheme.success,
      'inactive': AppTheme.textSecondary,
      'under_repair': AppTheme.warning,
      'disposed': AppTheme.error,
    };

    final sections = counts.entries.map((e) => PieChartSectionData(
      value: e.value.toDouble(),
      color: colors[e.key] ?? Colors.grey,
      title: '${e.value}',
      radius: 80,
      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
    )).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Equipment Status Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 20),
          sections.isEmpty
              ? const Center(child: Text('No data', style: TextStyle(color: AppTheme.textSecondary)))
              : SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChart(PieChartData(
                          sections: sections,
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        )),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: counts.entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 12, height: 12,
                                decoration: BoxDecoration(
                                  color: colors[e.key],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppConstants.formatStatus(e.key),
                                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(width: 8),
                              Text('${e.value}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final AppProvider provider;
  const _RecentActivity({required this.provider});

  @override
  Widget build(BuildContext context) {
    final records = provider.borrowingRecords.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Borrowing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('No borrowing records', style: TextStyle(color: AppTheme.textSecondary))),
            )
          else
            ...records.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppConstants.statusColor(r.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.swap_horiz_rounded, color: AppConstants.statusColor(r.status), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.borrowerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary), overflow: TextOverflow.ellipsis),
                        Text(r.equipmentName ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppConstants.statusColor(r.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      AppConstants.formatStatus(r.status),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppConstants.statusColor(r.status)),
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }
}

class _RecentEquipmentTable extends StatelessWidget {
  final AppProvider provider;
  const _RecentEquipmentTable({required this.provider});

  @override
  Widget build(BuildContext context) {
    final equipment = provider.equipment.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Equipment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(2),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.border)),
                ),
                children: ['Equipment', 'Category', 'Laboratory', 'Qty', 'Status']
                    .map((h) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(h, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                        ))
                    .toList(),
              ),
              ...equipment.map((eq) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(eq.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(eq.categoryName ?? '-', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(eq.laboratoryName ?? '-', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text('${eq.quantity}', style: const TextStyle(fontSize: 13)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppConstants.statusColor(eq.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AppConstants.formatStatus(eq.status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.statusColor(eq.status),
                        ),
                      ),
                    ),
                  ),
                ],
              )),
            ],
          ),
          if (equipment.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('No equipment found', style: TextStyle(color: AppTheme.textSecondary))),
            ),
        ],
      ),
    );
  }
}
