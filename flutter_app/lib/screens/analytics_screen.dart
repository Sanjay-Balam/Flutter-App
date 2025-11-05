import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sale_record.dart';
import '../models/menu_item.dart';
import '../providers/sales_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/date_range_picker_dialog.dart';
import '../services/pdf_export_service.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimePeriod = 'All Time'; // Default to All Time
  DateTime? _customStartDate;
  DateTime? _customEndDate;

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

  void _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      // Navigation will be handled automatically by AuthGate
    }
  }

  @override
  Widget build(BuildContext context) {
    final todaysRevenue = ref.watch(todaysRevenueProvider);
    final todaysSalesAsync = ref.watch(todaysSalesProvider);
    final thisWeekSalesAsync = ref.watch(thisWeekSalesProvider);
    final thisMonthSalesAsync = ref.watch(thisMonthSalesProvider);
    final thisYearSalesAsync = ref.watch(thisYearSalesProvider);
    final allSalesAsync = ref.watch(salesProvider);
    final currencyFormatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
    );

    // Check if any data is loading
    final isLoading =
        todaysSalesAsync.isLoading ||
        thisWeekSalesAsync.isLoading ||
        thisMonthSalesAsync.isLoading ||
        thisYearSalesAsync.isLoading ||
        allSalesAsync.isLoading;

    // Check if any data has error
    final hasError =
        todaysSalesAsync.hasError ||
        thisWeekSalesAsync.hasError ||
        thisMonthSalesAsync.hasError ||
        thisYearSalesAsync.hasError ||
        allSalesAsync.hasError;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export Report',
            onPressed: () => _showExportDialog(
              allSalesAsync.value ?? [],
              todaysSalesAsync.value ?? [],
              thisWeekSalesAsync.value ?? [],
              thisMonthSalesAsync.value ?? [],
              thisYearSalesAsync.value ?? [],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(salesProvider.notifier).refresh();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Profile',
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (BuildContext context) {
              final user = ref.read(currentUserProvider);
              return [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
          ? _buildErrorState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(
                  currencyFormatter,
                  todaysRevenue,
                  todaysSalesAsync.value ?? [],
                  thisWeekSalesAsync.value ?? [],
                  thisMonthSalesAsync.value ?? [],
                  thisYearSalesAsync.value ?? [],
                  allSalesAsync.value ?? [],
                ),
                _buildChartsTab(
                  thisWeekSalesAsync.value ?? [],
                  thisMonthSalesAsync.value ?? [],
                ),
                _buildReportsTab(
                  currencyFormatter,
                  thisWeekSalesAsync.value ?? [],
                  thisMonthSalesAsync.value ?? [],
                  thisYearSalesAsync.value ?? [],
                ),
              ],
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Failed to load analytics data',
            style: TextStyle(fontSize: 18, color: Colors.red[700]),
          ),
          const SizedBox(height: 8),
          Text(
            'Unable to fetch sales data from the server',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(salesProvider.notifier).refresh();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    NumberFormat currencyFormatter,
    double todaysRevenue,
    List<SaleRecord> todaysSales,
    List<SaleRecord> thisWeekSales,
    List<SaleRecord> thisMonthSales,
    List<SaleRecord> thisYearSales,
    List<SaleRecord> allSales,
  ) {
    // Calculate top selling items based on selected time period
    List<SaleRecord> selectedSales;
    switch (_selectedTimePeriod) {
      case 'Today':
        selectedSales = todaysSales;
        break;
      case 'This Week':
        selectedSales = thisWeekSales;
        break;
      case 'This Month':
        selectedSales = thisMonthSales;
        break;
      case 'This Year':
        selectedSales = thisYearSales;
        break;
      case 'Custom':
        if (_customStartDate != null && _customEndDate != null) {
          selectedSales = allSales.where((sale) {
            return sale.timestamp.isAfter(
                  _customStartDate!.subtract(const Duration(seconds: 1)),
                ) &&
                sale.timestamp.isBefore(
                  _customEndDate!.add(const Duration(seconds: 1)),
                );
          }).toList();
        } else {
          selectedSales = allSales;
        }
        break;
      case 'All Time':
      default:
        selectedSales = allSales;
    }

    // Calculate top selling items for selected period
    final Map<String, int> topSellingItems = {};
    for (final sale in selectedSales) {
      if (sale.isMultiItem && sale.items != null) {
        for (final item in sale.items!) {
          final itemName = item.itemName;
          topSellingItems[itemName] =
              (topSellingItems[itemName] ?? 0) + item.quantity;
        }
      } else {
        final itemName = sale.itemName ?? 'Unknown';
        final quantity = sale.quantity ?? 0;
        topSellingItems[itemName] = (topSellingItems[itemName] ?? 0) + quantity;
      }
    }

    // Sort by quantity and take top items
    final sortedItems = topSellingItems.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
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

          // Top Selling Items with Time Period Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Selling Items',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ),
                child: DropdownButton<String>(
                  value: _selectedTimePeriod,
                  underline: const SizedBox(),
                  isDense: true,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(context).primaryColor,
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                  selectedItemBuilder: (context) {
                    return [
                      const Text('Today'),
                      const Text('Week'),
                      const Text('Month'),
                      const Text('Year'),
                      const Text('All'),
                      Text(
                        _customStartDate != null && _customEndDate != null
                            ? '${DateFormat('MMM d').format(_customStartDate!)} - ${DateFormat('MMM d').format(_customEndDate!)}'
                            : 'Custom',
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ];
                  },
                  items: const [
                    DropdownMenuItem(value: 'Today', child: Text('Today')),
                    DropdownMenuItem(
                      value: 'This Week',
                      child: Text('This Week'),
                    ),
                    DropdownMenuItem(
                      value: 'This Month',
                      child: Text('This Month'),
                    ),
                    DropdownMenuItem(
                      value: 'This Year',
                      child: Text('This Year'),
                    ),
                    DropdownMenuItem(
                      value: 'All Time',
                      child: Text('All Time'),
                    ),
                    DropdownMenuItem(
                      value: 'Custom',
                      child: Text('Custom Range...'),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == 'Custom') {
                      final result = await showDialog<Map<String, DateTime>>(
                        context: context,
                        builder: (context) => CustomDateRangeDialog(
                          initialStartDate: _customStartDate,
                          initialEndDate: _customEndDate,
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          _selectedTimePeriod = 'Custom';
                          _customStartDate = result['startDate'];
                          _customEndDate = result['endDate'];
                        });
                      }
                    } else if (value != null) {
                      setState(() {
                        _selectedTimePeriod = value;
                        _customStartDate = null;
                        _customEndDate = null;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (sortedItems.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No sales data available for this period',
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
                  children: sortedItems
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

    // Group sales by category name
    final Map<String, double> categoryRevenue = {};
    for (final sale in monthSales) {
      if (sale.isMultiItem && sale.items != null) {
        // For multi-item sales, distribute revenue by item
        for (final item in sale.items!) {
          final categoryName = item.categoryName;
          categoryRevenue[categoryName] =
              (categoryRevenue[categoryName] ?? 0) + item.subtotal;
        }
      } else {
        // For single-item sales
        final categoryName = sale.categoryName ?? 'Uncategorized';
        categoryRevenue[categoryName] =
            (categoryRevenue[categoryName] ?? 0) + sale.totalAmount;
      }
    }

    final sections = categoryRevenue.entries.map((entry) {
      final color = _getCategoryColorByName(entry.key);
      return PieChartSectionData(
        value: entry.value,
        title: '${entry.key}\n₹${entry.value.toInt()}',
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

  Color _getCategoryColorByName(String categoryName) {
    // Generate a consistent color based on category name hash
    final hash = categoryName.hashCode;
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[hash.abs() % colors.length];
  }

  Widget _buildReportCard(
    String title,
    List<SaleRecord> sales,
    NumberFormat currencyFormatter,
    IconData icon,
    Color color,
  ) {
    final totalRevenue = sales.fold(0.0, (sum, sale) => sum + sale.totalAmount);
    final totalItems = sales.fold<int>(0, (sum, sale) {
      if (sale.isMultiItem && sale.items != null) {
        return sum +
            sale.items!.fold<int>(
              0,
              (itemSum, item) => itemSum + item.quantity,
            );
      } else {
        return sum + (sale.quantity ?? 0);
      }
    });
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

  void _showExportDialog(
    List<SaleRecord> allSales,
    List<SaleRecord> todaysSales,
    List<SaleRecord> thisWeekSales,
    List<SaleRecord> thisMonthSales,
    List<SaleRecord> thisYearSales,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select the time period for your report:'),
            const SizedBox(height: 16),
            _buildExportOption(
              'Today\'s Report',
              todaysSales,
              'Today - ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
            ),
            _buildExportOption(
              'This Week\'s Report',
              thisWeekSales,
              'This Week',
            ),
            _buildExportOption(
              'This Month\'s Report',
              thisMonthSales,
              'This Month - ${DateFormat('MMMM yyyy').format(DateTime.now())}',
            ),
            _buildExportOption(
              'This Year\'s Report',
              thisYearSales,
              'This Year - ${DateTime.now().year}',
            ),
            _buildExportOption('All Time Report', allSales, 'All Time'),
            if (_selectedTimePeriod == 'Custom' &&
                _customStartDate != null &&
                _customEndDate != null)
              _buildExportOption(
                'Custom Range Report',
                allSales.where((sale) {
                  return sale.timestamp.isAfter(
                        _customStartDate!.subtract(const Duration(seconds: 1)),
                      ) &&
                      sale.timestamp.isBefore(
                        _customEndDate!.add(const Duration(seconds: 1)),
                      );
                }).toList(),
                '${DateFormat('MMM dd, yyyy').format(_customStartDate!)} - ${DateFormat('MMM dd, yyyy').format(_customEndDate!)}',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption(
    String title,
    List<SaleRecord> sales,
    String dateRange,
  ) {
    return ListTile(
      leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
      title: Text(title),
      subtitle: Text('${sales.length} sales'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () async {
        // Close the dialog first
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Wait a frame before showing snackbar to avoid navigator assertion
        await Future.delayed(const Duration(milliseconds: 100));

        if (!mounted) return;

        if (sales.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No sales data available for this period'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        try {
          await PdfExportService.exportSalesReport(
            sales: sales,
            reportTitle: title,
            dateRange: dateRange,
            businessName: 'Your Business', // TODO: Get from settings
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Report exported successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error exporting report: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }
}
