import 'package:flutter/material.dart';

class CustomDateRangeDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const CustomDateRangeDialog({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<CustomDateRangeDialog> createState() => _CustomDateRangeDialogState();
}

class _CustomDateRangeDialogState extends State<CustomDateRangeDialog> {
  DateTime? _startDate;
  DateTime? _endDate;

  // For custom dropdowns
  int? _startMonth;
  int? _startYear;
  int? _startDay;
  int? _endMonth;
  int? _endYear;
  int? _endDay;

  final List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;

    if (_startDate != null) {
      _startMonth = _startDate!.month;
      _startYear = _startDate!.year;
      _startDay = _startDate!.day;
    } else {
      // Initialize with current date if no initial date provided
      final now = DateTime.now();
      _startMonth = now.month;
      _startYear = now.year;
      _startDay = now.day;
      _startDate = DateTime(now.year, now.month, now.day);
    }

    if (_endDate != null) {
      _endMonth = _endDate!.month;
      _endYear = _endDate!.year;
      _endDay = _endDate!.day;
    } else {
      // Initialize with current date if no initial date provided
      final now = DateTime.now();
      _endMonth = now.month;
      _endYear = now.year;
      _endDay = now.day;
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    }
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _updateStartDate() {
    if (_startMonth != null && _startYear != null && _startDay != null) {
      final maxDay = _getDaysInMonth(_startYear!, _startMonth!);
      if (_startDay! > maxDay) {
        _startDay = maxDay;
      }
      setState(() {
        _startDate = DateTime(_startYear!, _startMonth!, _startDay!);
        // If end date is before start date, reset it
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
          _endMonth = null;
          _endYear = null;
          _endDay = null;
        }
      });
    }
  }

  void _updateEndDate() {
    if (_endMonth != null && _endYear != null && _endDay != null) {
      final maxDay = _getDaysInMonth(_endYear!, _endMonth!);
      if (_endDay! > maxDay) {
        _endDay = maxDay;
      }
      setState(() {
        _endDate = DateTime(_endYear!, _endMonth!, _endDay!);
      });
    }
  }

  void _applyQuickFilter(String filter) {
    final now = DateTime.now();
    setState(() {
      switch (filter) {
        case 'Today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'Yesterday':
          final yesterday = now.subtract(const Duration(days: 1));
          _startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
          _endDate = DateTime(
            yesterday.year,
            yesterday.month,
            yesterday.day,
            23,
            59,
            59,
          );
          break;
        case 'Last 7 Days':
          _startDate = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(days: 6));
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'Last 30 Days':
          _startDate = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(days: 29));
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'This Month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
        case 'Last Month':
          final lastMonth = DateTime(now.year, now.month - 1, 1);
          _startDate = lastMonth;
          _endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
          break;
      }

      // Update dropdown values
      if (_startDate != null) {
        _startMonth = _startDate!.month;
        _startYear = _startDate!.year;
        _startDay = _startDate!.day;
      }
      if (_endDate != null) {
        _endMonth = _endDate!.month;
        _endYear = _endDate!.year;
        _endDay = _endDate!.day;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _startDate != null && _endDate != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Date Range',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Quick Filters
                const Text(
                  'Quick Filters',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickFilterChip('Today'),
                    _buildQuickFilterChip('Yesterday'),
                    _buildQuickFilterChip('Last 7 Days'),
                    _buildQuickFilterChip('Last 30 Days'),
                    _buildQuickFilterChip('This Month'),
                    _buildQuickFilterChip('Last Month'),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),

                // Custom Date Selection
                const Text(
                  'Custom Range',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),

                // Start Date
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Start Date',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Day Dropdown
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int>(
                              value: _startDay,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Day',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                isDense: true,
                              ),
                              items: List.generate(
                                _startMonth != null && _startYear != null
                                    ? _getDaysInMonth(_startYear!, _startMonth!)
                                    : 31,
                                (index) => DropdownMenuItem(
                                  value: index + 1,
                                  child: Text('${index + 1}'),
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _startDay = value;
                                  _updateStartDate();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Month Dropdown
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<int>(
                              value: _startMonth,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Month',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                isDense: true,
                              ),
                              items: List.generate(
                                12,
                                (index) => DropdownMenuItem(
                                  value: index + 1,
                                  child: Text(_monthNames[index]),
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _startMonth = value;
                                  _updateStartDate();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Year Dropdown
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int>(
                              value: _startYear,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Year',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                isDense: true,
                              ),
                              items: List.generate(
                                DateTime.now().year - 2020 + 1,
                                (index) => DropdownMenuItem(
                                  value: 2020 + index,
                                  child: Text('${2020 + index}'),
                                ),
                              ).reversed.toList(),
                              onChanged: (value) {
                                setState(() {
                                  _startYear = value;
                                  _updateStartDate();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // End Date
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'End Date',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Day Dropdown
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int>(
                              value: _endDay,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Day',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                isDense: true,
                              ),
                              items: List.generate(
                                _endMonth != null && _endYear != null
                                    ? _getDaysInMonth(_endYear!, _endMonth!)
                                    : 31,
                                (index) => DropdownMenuItem(
                                  value: index + 1,
                                  child: Text('${index + 1}'),
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _endDay = value;
                                  _updateEndDate();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Month Dropdown
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<int>(
                              value: _endMonth,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Month',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                isDense: true,
                              ),
                              items: List.generate(
                                12,
                                (index) => DropdownMenuItem(
                                  value: index + 1,
                                  child: Text(_monthNames[index]),
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _endMonth = value;
                                  _updateEndDate();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Year Dropdown
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int>(
                              value: _endYear,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Year',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                isDense: true,
                              ),
                              items: List.generate(
                                DateTime.now().year - 2020 + 1,
                                (index) => DropdownMenuItem(
                                  value: 2020 + index,
                                  child: Text('${2020 + index}'),
                                ),
                              ).reversed.toList(),
                              onChanged: (value) {
                                setState(() {
                                  _endYear = value;
                                  _updateEndDate();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: isValid
                          ? () {
                              Navigator.of(context).pop(<String, DateTime>{
                                'startDate': _startDate!,
                                'endDate': _endDate!,
                              });
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () => _applyQuickFilter(label),
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: Theme.of(context).primaryColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
