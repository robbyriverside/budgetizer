import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/dashboard_controller.dart';
import '../../../../core/services/bank_service.dart';

class TagInspectorPanel extends ConsumerStatefulWidget {
  final String tagName;
  final bool isVendor;

  const TagInspectorPanel({
    super.key,
    required this.tagName,
    this.isVendor = false,
  });

  @override
  ConsumerState<TagInspectorPanel> createState() => _TagInspectorPanelState();
}

class _TagInspectorPanelState extends ConsumerState<TagInspectorPanel> {
  final _limitController = TextEditingController();
  final _freqController = TextEditingController(); // New controller for Days
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTagData();
  }

  @override
  void didUpdateWidget(TagInspectorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tagName != oldWidget.tagName) {
      _loadTagData();
    }
  }

  Future<void> _loadTagData() async {
    setState(() => _isLoading = true);
    final service = ref.read(bankServiceProvider);
    final tags = await service.fetchTags();

    // Find tag or default
    final tag = tags.firstWhere(
      (t) => t.name == widget.tagName,
      orElse: () => Tag(name: widget.tagName),
    );

    _limitController.text = tag.budgetLimit?.toString() ?? '';
    // Display 0 as "0" (Monthly) or just number
    _freqController.text = (tag.frequency ?? 0).toString();

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveTag() async {
    final limit = double.tryParse(_limitController.text);
    final freq = int.tryParse(_freqController.text) ?? 0;

    // Validation: 0 = Monthly, 1-15 = Valid custom days.
    // > 15 is invalid (User request: Upper bound 15).
    if (freq > 15) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Frequency must be 15 days or less (or 0 for Monthly)',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    await ref
        .read(dashboardControllerProvider.notifier)
        .updateTagLimit(widget.tagName, limit, freq);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Budget updated for ${widget.tagName}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate stats
    final allTransactions =
        ref.watch(bankTransactionListProvider).asData?.value ?? [];

    // Filter transactions for this tag
    final tagTransactions = allTransactions
        .where((t) => t.tags.contains(widget.tagName))
        .toList();

    // Calculate Total Spent (current cycle - mocked as all for now or last 30 days)
    // For V1, let's treat "All Transactions" as "Current Cycle" for the main stat,
    // but proper trend requires historical data.
    // We will simulate 6 months of data for the chart by hashing the date or just randomizing for mock.

    double totalSpent = 0;
    for (var t in tagTransactions) {
      if (t.amount < 0) totalSpent += t.amount.abs();
    }

    // Prorated Logic (Mocked)
    final budgetLimit = double.tryParse(_limitController.text) ?? 0;
    final freq = int.tryParse(_freqController.text) ?? 0;

    // Calculate Cycle Progress
    // If freq=0 (Monthly), use 30 days.
    // Mocking "Day 15" of the cycle.
    final cycleLength = freq == 0 ? 30 : freq;
    // Mock current day in cycle as 50% for 30 days, or min(15, cycleLength)
    final currentDay = 15;
    final cycleProgress = (currentDay / cycleLength).clamp(0.0, 1.0);

    final proratedBudget = budgetLimit * cycleProgress;
    final isOverProrated = totalSpent > proratedBudget;
    final isMonthly = freq == 0;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: const Border(left: BorderSide(color: Colors.white12)),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.zero,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            widget.isVendor ? Icons.store : Icons.label,
                            color: widget.isVendor
                                ? Colors.blueAccent
                                : Colors.tealAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.tagName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        ref
                            .read(dashboardControllerProvider.notifier)
                            .selectTag(null);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 1. Budget Config
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "BUDGET CONFIGURATION",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _limitController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Limit',
                                prefixText: '\$ ',
                                isDense: true,
                                filled: true,
                                fillColor: Colors.black26,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _freqController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Days (0=Mth)',
                                isDense: true,
                                filled: true,
                                fillColor: Colors.black26,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                suffixText: isMonthly ? 'Monthly' : 'Days',
                                suffixStyle: TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 10,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) =>
                                  setState(() {}), // Refresh UI for suffix
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonal(
                          onPressed: _saveTag,
                          child: const Text("Update Budget"),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Report & Status
                Text(
                  "CURRENT CYCLE (OCT)",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "\$${totalSpent.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (budgetLimit > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          "/ \$${budgetLimit.toStringAsFixed(0)}",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                  ],
                ),

                if (budgetLimit > 0) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (totalSpent / budgetLimit).clamp(0.0, 1.0),
                    backgroundColor: Colors.white12,
                    color: totalSpent > budgetLimit
                        ? Colors.redAccent
                        : Colors.tealAccent,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isOverProrated
                        ? "⚠️ ${((totalSpent / budgetLimit) * 100).toStringAsFixed(0)}% used (Ahead of schedule)" // "Ahead" means spending too fast
                        : "✅ On Track (48% through cycle)",
                    style: TextStyle(
                      color: isOverProrated
                          ? Colors.orangeAccent
                          : Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],

                const SizedBox(height: 30),

                // 3. Trend Chart
                Text(
                  "6 MONTH TREND",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 180,
                  child: _buildTrendChart(totalSpent, budgetLimit),
                ),
              ],
            ),
    );
  }

  Widget _buildTrendChart(double currentTotal, double limit) {
    // Mock Data Generator relative to current Total
    // 0: Current Month, 1: Last Month ...
    List<BarChartGroupData> barGroups = [];
    for (int i = 5; i >= 0; i--) {
      // Mock variations
      double val = (currentTotal * (0.8 + (i % 3) * 0.1));
      if (i == 0) val = currentTotal; // Current is exact

      barGroups.add(
        BarChartGroupData(
          x: 5 - i,
          barRods: [
            BarChartRodData(
              toY: val,
              color: val > limit && limit > 0
                  ? Colors.redAccent.withValues(alpha: 0.7)
                  : Colors.blueAccent.withValues(alpha: 0.7),
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (limit > currentTotal ? limit : currentTotal) * 1.2,
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const months = ['May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct'];
                if (value.toInt() < months.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      months[value.toInt()],
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: limit > 0
            ? ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: limit,
                    color: Colors.white30,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ],
              )
            : null,
        barGroups: barGroups,
      ),
    );
  }
}
