import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgetizer_dart/budgetizer_dart.dart';
import '../../core/widgets/split_view.dart';
import '../../core/services/tag_service.dart';
import '../../widgets/tag_chip.dart';
import 'vendor_controller.dart';

class VendorScreen extends ConsumerStatefulWidget {
  const VendorScreen({super.key});

  @override
  ConsumerState<VendorScreen> createState() => _VendorScreenState();
}

class _VendorScreenState extends ConsumerState<VendorScreen> {
  String? _selectedTagFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Create checkpoint on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tagServiceProvider.notifier).createCheckpoint();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(vendorControllerProvider);
    final tagStateAsync = ref.watch(tagServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vendor Editor"),
        actions: [
          // Changes Log Button (New Feature)
          tagStateAsync.when(
            data: (state) => IconButton(
              icon: Badge(
                isLabelVisible: state.changes.isNotEmpty,
                label: Text('${state.changes.length}'),
                child: const Icon(Icons.history),
              ),
              onPressed: () => _showChangesDialog(context, ref, state.changes),
              tooltip: "View Changes Log",
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () {
              ref.read(vendorControllerProvider.notifier).undoChanges();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Reverted to checkpoint")),
              );
            },
            icon: const Icon(Icons.undo),
            label: const Text("Undo All"),
            style: TextButton.styleFrom(foregroundColor: Colors.orangeAccent),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () async {
              ref.read(vendorControllerProvider.notifier).saveChanges();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Changes Saved")));
            },
            icon: const Icon(Icons.save),
            label: const Text("Save"),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: vendorsAsync.when(
        data: (vendors) => _buildSplitView(context, vendors),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _buildSplitView(BuildContext context, List<Tag> vendors) {
    // Left: All Vendors (filtered by search)
    final leftList = vendors.where((v) {
      return v.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Right: Vendors with Selected Tag
    final rightList = _selectedTagFilter == null
        ? <Tag>[]
        : vendors.where((v) => v.related.contains(_selectedTagFilter)).toList();

    return SplitView(
      axis: Axis.horizontal,
      initialRatio: 0.5,
      child1: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search Vendors...",
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: leftList.length,
              itemBuilder: (context, index) {
                return _buildVendorTile(context, leftList[index], isLeft: true);
              },
            ),
          ),
        ],
      ),
      child2: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _selectedTagFilter == null
                  ? "Select a tag to see related vendors"
                  : "Vendors with tag: '$_selectedTagFilter'",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: rightList.length,
              itemBuilder: (context, index) {
                return _buildVendorTile(
                  context,
                  rightList[index],
                  isLeft: false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showChangesDialog(
    BuildContext context,
    WidgetRef ref,
    List<TagChange> changes,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Changes Log"),
        content: SizedBox(
          width: 500,
          height: 400,
          child: changes.isEmpty
              ? const Center(child: Text("No changes made yet."))
              : ListView.builder(
                  itemCount: changes.length,
                  itemBuilder: (context, index) {
                    final change = changes[index]; // Most recent first
                    return ListTile(
                      leading: Icon(
                        change.type == 'add'
                            ? Icons.add_circle
                            : Icons.remove_circle,
                        color: change.type == 'add' ? Colors.green : Colors.red,
                      ),
                      title: Text(change.description),
                      subtitle: Text(change.timestamp.toString().split('.')[0]),
                      trailing: IconButton(
                        icon: const Icon(Icons.undo),
                        tooltip: "Undo this change",
                        onPressed: () {
                          ref
                              .read(tagServiceProvider.notifier)
                              .undoSpecificChange(change);
                          Navigator.pop(
                            ctx,
                          ); // Close to refresh or rebuild needed?
                          // Dialog assumes state is watched by parent, but here we might need to rebuild dialogue content
                          // Ideally, we keep dialog open and it updates, but simple way is close.
                          // Or use Consumer in dialog.
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorTile(
    BuildContext context,
    Tag vendor, {
    required bool isLeft,
  }) {
    // Determine background color based on whether it effectively has the filtered tag
    final isRelated =
        _selectedTagFilter != null &&
        vendor.related.contains(_selectedTagFilter);
    final cardColor = isRelated && isLeft
        ? Colors.tealAccent.withValues(alpha: 0.1)
        : null;

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) =>
          !vendor.related.contains(details.data),
      onAcceptWithDetails: (details) {
        ref
            .read(vendorControllerProvider.notifier)
            .addTagToVendor(vendor.name, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          color: candidateData.isNotEmpty
              ? Colors.teal.withValues(alpha: 0.3)
              : cardColor,
          child: ListTile(
            title: Text(
              vendor.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: vendor.related.map((tag) {
                // Determine Tag Type from provider state?
                // The widget doesn't easily access the type map here unless we pass it down
                // OR we can read it from the provider again.
                // But efficient way is to read it once in build.
                // Let's modify the signature or assume context read is ok?
                // Actually _buildVendorTile has context.
                // We will use ref.read inside build... wait, ref is not available in _buildVendorTile easily unless passed or using ConsumerWidget.
                // _VendorScreenState is a ConsumerState, so we have 'ref'.

                final tagState = ref.read(tagServiceProvider).value;
                final type = tagState?.tagTypeMap[tag];

                return Draggable<String>(
                  data: tag,
                  feedback: Material(
                    color: Colors.transparent,
                    child: TagChip(label: tag, type: type), // Simple feedback
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.5,
                    child: TagChip(label: tag, type: type),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTagFilter = tag;
                      });
                    },
                    child: TagChip(
                      label: tag,
                      type: type,
                      onDeleted: () {
                        ref
                            .read(tagServiceProvider.notifier)
                            .removeTagFromVendor(vendor.name, tag);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
