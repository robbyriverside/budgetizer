import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgetizer_dart/budgetizer_dart.dart';
import '../../core/widgets/split_view.dart';
import '../../core/services/tag_service.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vendor Editor"),
        actions: [
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
        data: (vendors) {
          // Left: All Vendors (filtered by search)
          final leftList = vendors.where((v) {
            return v.name.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          // Right: Vendors with Selected Tag
          final rightList = _selectedTagFilter == null
              ? <Tag>[]
              : vendors
                    .where((v) => v.related.contains(_selectedTagFilter))
                    .toList();

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
                      return _buildVendorTile(
                        context,
                        leftList[index],
                        isLeft: true,
                      );
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
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _buildVendorTile(
    BuildContext context,
    Tag vendor, {
    required bool isLeft,
  }) {
    return DragTarget<String>(
      onWillAccept: (data) => data != null && !vendor.related.contains(data),
      onAccept: (tag) {
        ref
            .read(vendorControllerProvider.notifier)
            .addTagToVendor(vendor.name, tag);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          color: candidateData.isNotEmpty ? Colors.teal.withOpacity(0.3) : null,
          child: ListTile(
            title: Text(
              vendor.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Wrap(
              spacing: 4,
              children: vendor.related.map((tag) {
                return Draggable<String>(
                  data: tag,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Chip(label: Text(tag), backgroundColor: Colors.teal),
                  ),
                  childWhenDragging: Chip(
                    label: Text(tag),
                    backgroundColor: Colors.grey,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTagFilter = tag;
                      });
                    },
                    child: Chip(
                      label: Text(tag),
                      backgroundColor: _selectedTagFilter == tag
                          ? Colors.tealAccent.withOpacity(0.4)
                          : null,
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
