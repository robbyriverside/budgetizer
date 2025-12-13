import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/bank_service.dart';
import '../controllers/dashboard_controller.dart';

class InspectorPanel extends ConsumerStatefulWidget {
  final DashboardState state;

  const InspectorPanel({super.key, required this.state});

  @override
  ConsumerState<InspectorPanel> createState() => _InspectorPanelState();
}

class _InspectorPanelState extends ConsumerState<InspectorPanel> {
  // Form State
  final _formKey = GlobalKey<FormState>();
  TransactionType? _selectedType;
  final _tagsController = TextEditingController();

  // Track the ID being edited to reset form on selection change
  String? _activeId;

  @override
  void didUpdateWidget(InspectorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.selection.length == 1) {
      final newId = widget.state.selection.first;
      if (_activeId != newId) {
        // Reset form when selection changes
        _activeId = newId;
        _selectedType = null;
        _tagsController.clear();
      }
    } else {
      _activeId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.selection.isEmpty) {
      return Center(
        child: Text(
          "Select a transaction to inspect",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (widget.state.selection.length > 1) {
      return _buildMultiSelectionView();
    }

    // Single Selection Logic
    final selectedId = widget.state.selection.first;
    final transactionsAsync = ref.watch(bankTransactionListProvider);

    return transactionsAsync.when(
      data: (transactions) {
        final tx = transactions.firstWhere(
          (t) => t.id == selectedId,
          orElse: () => transactions[0],
        ); // Fallback safe

        // If initialized, show Read-Only (for now)
        if (tx.isInitialized) {
          return _buildReadOnlyView(tx);
        }

        // If Uninitialized, show Editor
        return _buildEditorView(tx);
      },
      error: (e, s) => Text("Error loading selection"),
      loading: () => CircularProgressIndicator(),
    );
  }

  Widget _buildEditorView(BankTransaction tx) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            "Initialize Transaction",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(height: 10),
          Text(tx.name, style: TextStyle(fontSize: 16)),
          Text(
            "\$${tx.amount.abs().toStringAsFixed(2)}",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Divider(height: 30),

          // 1. Type Dropdown
          DropdownButtonFormField<TransactionType>(
            // ignore: deprecated_member_use
            value: _selectedType,
            decoration: InputDecoration(labelText: "Type"),
            items: TransactionType.values
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.name.toUpperCase()),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedType = val),
            validator: (val) => val == null ? 'Required' : null,
          ),
          SizedBox(height: 10),

          // 2. Tags
          TextFormField(
            controller: _tagsController,
            decoration: InputDecoration(
              labelText: "Tags (comma separated)",
              hintText: "e.g. Target, Groceries, Home Goods",
            ),
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          SizedBox(height: 10),

          // 3. Limit (REMOVED - Managed in Tag Inspector)
          if (_selectedType == TransactionType.variable)
            const Text(
              "Note: Limits are now managed per Tag.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),

          SizedBox(height: 20),
          FilledButton.icon(
            icon: Icon(Icons.save),
            label: Text("Save & Initialize"),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _saveTransaction(tx.id);
              }
            },
          ),
        ],
      ),
    );
  }

  void _saveTransaction(String id) {
    final tagsString = _tagsController.text;
    final tags = tagsString
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Call Controller to Initialize
    ref
        .read(dashboardControllerProvider.notifier)
        .initializeTransaction(id: id, type: _selectedType!, tags: tags);

    // Clear selection after save
    ref.read(dashboardControllerProvider.notifier).clearSelection();
  }

  Widget _buildReadOnlyView(BankTransaction tx) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Transaction Details",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(height: 20),
          _detailRow("Name", tx.name),
          _detailRow("Amount", "\$${tx.amount.abs().toStringAsFixed(2)}"),
          _buildTagsRow(tx.tags),
          _detailRow("Date", "${tx.date.month}/${tx.date.day}"),
          Spacer(),
          OutlinedButton(onPressed: () {}, child: Text("Edit (Coming Soon)")),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTagsRow(List<String> tags) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Tags", style: TextStyle(color: Colors.grey)),
          Row(
            children: tags
                .map(
                  (tag) => Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: ActionChip(
                      label: Text(tag),
                      onPressed: () {
                        // Trigger selection in controller
                        ref
                            .read(dashboardControllerProvider.notifier)
                            .selectTag(tag);
                      },
                      padding: EdgeInsets.zero,
                      labelStyle: TextStyle(fontSize: 11),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectionView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.copy, size: 48, color: Colors.grey),
          SizedBox(height: 10),
          Text("${widget.state.selection.length} items selected"),
        ],
      ),
    );
  }
}
