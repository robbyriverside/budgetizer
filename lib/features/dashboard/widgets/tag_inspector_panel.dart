import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  String? _frequency;
  bool _isLoading = false;
  Tag? _currentTag;

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
    _frequency = tag.frequency ?? 'Monthly';
    _currentTag = tag;

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveTag() async {
    final limit = double.tryParse(_limitController.text);

    await ref
        .read(dashboardControllerProvider.notifier)
        .updateTagLimit(widget.tagName, limit, _frequency);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Budget updated for ${widget.tagName}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate simple stats for this tag in current view
    final allTransactions =
        ref.watch(bankTransactionListProvider).asData?.value ?? [];
    final tagTransactions = allTransactions.where(
      (t) => t.tags.contains(widget.tagName),
    );
    double totalSpent = 0;
    for (var t in tagTransactions) {
      if (t.amount < 0) totalSpent += t.amount.abs();
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[900], // Dark panel background
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (widget.isVendor) ...[
                    const Icon(Icons.store, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.tagName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  ref
                      .read(dashboardControllerProvider.notifier)
                      .selectTag(null);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (widget.isVendor) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "VENDOR INFORMATION",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Regex: ${_currentTag?.regex ?? 'N/A'}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Text(
                    "Defaults: Groceries, Home",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_isLoading)
            const LinearProgressIndicator()
          else
            Column(
              children: [
                // Stack inputs vertically for narrow sidebar
                TextFormField(
                  controller: _limitController,
                  decoration: const InputDecoration(
                    labelText: 'Budget Limit',
                    isDense: true,
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _frequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: ['Weekly', 'Monthly', 'Yearly']
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setState(() => _frequency = v),
                ),
                const SizedBox(height: 20),
                Text(
                  "Total Spent: \$${totalSpent.toStringAsFixed(2)}",
                  style: TextStyle(color: Colors.grey),
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
        ],
      ),
    );
  }
}
