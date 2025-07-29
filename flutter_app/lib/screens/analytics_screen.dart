import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sale_record.dart';
import '../models/menu_item.dart';
import '../providers/sales_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todaysRevenue = ref.watch(todaysRevenueProvider);
    final thisWeekSales = ref.watch(thisWeekSalesProvider);
    final thisMonthSales = ref.watch(thisMonthSalesProvider);
    final thisYearSales = ref.watch(thisYearSalesProvider);
    final topSellingItems = ref.watch(topSellingItemsProvider);
    final currencyFormatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Charts', icon: Icon(Icons.bar_chart)),
            Tab(text: 'Reports', icon: Icon(Icons.assessment)),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(
            currencyFormatter,
            todaysRevenue,
            thisWeekSales,
            thisMonthSales,
            thisYearSales,
            topSellingItems,
          ),
          _buildChartsTab(thisWeekSales, thisMonthSales),
          _buildReportsTab(
            currencyFormatter,
            thisWeekSales,
            thisMonthSales,
            thisYearSales,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    NumberFormat currencyFormatter,
    double todaysRevenue,
    List<SaleRecord> thisWeekSales,
    List<SaleRecord> thisMonthSales,
    List<SaleRecord> thisYearSales,
    Map<String, int> topSellingItems,
  ) {
    final weekRevenue = thisWeekSales.fold(
      0.0,
      (sum, sale) => sum + sale.totalAmount,
    );
    final monthRevenue = thisMonthSales.fold(
      0.0,
      (sum, sale) => sum + sale.totalAmount,
    );
    final yearRevenue = thisYearSales.fold(
      0.0,
      (sum, sale) => sum + sale.totalAmount,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue Cards
          const Text(
            'Revenue Overview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildRevenueCard(
                  'Today',
                  currencyFormatter.format(todaysRevenue),
                  Icons.today,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRevenueCard(
                  'This Week',
                  currencyFormatter.format(weekRevenue),
                  Icons.date_range,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildRevenueCard(
                  'This Month',
                  currencyFormatter.format(monthRevenue),
                  Icons.calendar_month,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRevenueCard(
                  'This Year',
                  currencyFormatter.format(yearRevenue),
                  Icons.calendar_today,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Sales Count Overview
          const Text(
            'Sales Count',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildSalesCountCard(
                  'Week',
                  '${thisWeekSales.length} sales',
                  Icons.assessment,
                  Colors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSalesCountCard(
                  'Month',
                  '${thisMonthSales.length} sales',
                  Icons.trending_up,
                  Colors.indigo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSalesCountCard(
                  'Year',
                  '${thisYearSales.length} sales',
                  Icons.show_chart,
                  Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Top Selling Items
          const Text(
            'Top Selling Items',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (topSellingItems.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No sales data available yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: topSellingItems.entries
                      .take(5)
                      .map((entry) => _buildTopItemRow(entry.key, entry.value))
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChartsTab(
    List<SaleRecord> thisWeekSales,
    List<SaleRecord> thisMonthSales,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly Sales Chart
          const Text(
            'Weekly Sales Revenue',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 200,
                child: _buildWeeklyChart(thisWeekSales),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Category Distribution Chart
          const Text(
            'Sales by Category (This Month)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 200,
                child: _buildCategoryChart(thisMonthSales),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab(
    NumberFormat currencyFormatter,
    List<SaleRecord> thisWeekSales,
    List<SaleRecord> thisMonthSales,
    List<SaleRecord> thisYearSales,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detailed Reports',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildReportCard(
            'Weekly Report',
            thisWeekSales,
            currencyFormatter,
            Icons.date_range,
            Colors.green,
          ),

          const SizedBox(height: 16),

          _buildReportCard(
            'Monthly Report',
            thisMonthSales,
            currencyFormatter,
            Icons.calendar_month,
            Colors.orange,
          ),

          const SizedBox(height: 16),

          _buildReportCard(
            'Yearly Report',
            thisYearSales,
            currencyFormatter,
            Icons.calendar_today,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesCountCard(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              count,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopItemRow(String itemName, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              itemName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count sold',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(List<SaleRecord> weekSales) {
    if (weekSales.isEmpty) {
      return const Center(
        child: Text(
          'No sales data for this week',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Group sales by day of week
    final Map<int, double> dailyRevenue = {};
    for (int i = 1; i <= 7; i++) {
      dailyRevenue[i] = 0.0;
    }

    for (final sale in weekSales) {
      final dayOfWeek = sale.timestamp.weekday;
      dailyRevenue[dayOfWeek] =
          (dailyRevenue[dayOfWeek] ?? 0) + sale.totalAmount;
    }

    final spots = dailyRevenue.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 50),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = [
                  '',
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                  'Sun',
                ];
                return Text(days[value.toInt()]);
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart(List<SaleRecord> monthSales) {
    if (monthSales.isEmpty) {
      return const Center(
        child: Text(
          'No sales data for this month',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Group sales by category
    final Map<MenuCategory, double> categoryRevenue = {};
    for (final sale in monthSales) {
      categoryRevenue[sale.category] =
          (categoryRevenue[sale.category] ?? 0) + sale.totalAmount;
    }

    final sections = categoryRevenue.entries.map((entry) {
      final color = _getCategoryColor(entry.key);
      return PieChartSectionData(
        value: entry.value,
        title: '${entry.key.displayName}\n₹${entry.value.toInt()}',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        borderData: FlBorderData(show: false),
        centerSpaceRadius: 40,
      ),
    );
  }

  Color _getCategoryColor(MenuCategory category) {
    switch (category) {
      case MenuCategory.milkCakes:
        return Colors.blue;
      case MenuCategory.cheeseCakes:
        return Colors.orange;
      case MenuCategory.chocolateBrownie:
        return Colors.green;
    }
  }

  Widget _buildReportCard(
    String title,
    List<SaleRecord> sales,
    NumberFormat currencyFormatter,
    IconData icon,
    Color color,
  ) {
    final totalRevenue = sales.fold(0.0, (sum, sale) => sum + sale.totalAmount);
    final totalItems = sales.fold(0, (sum, sale) => sum + sale.quantity);
    final avgSale = sales.isNotEmpty ? totalRevenue / sales.length : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildReportStat('Total Sales', '${sales.length}'),
                _buildReportStat('Items Sold', '$totalItems'),
                _buildReportStat(
                  'Revenue',
                  currencyFormatter.format(totalRevenue),
                ),
                _buildReportStat('Avg Sale', currencyFormatter.format(avgSale)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
