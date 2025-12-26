import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:budgetizer_dart/budgetizer_dart.dart';

part 'tag_service.g.dart';

@Riverpod(keepAlive: true)
class TagService extends _$TagService {
  List<Tag> _originalTags = [];
  List<Tag> _checkpointTags = [];

  @override
  Future<List<Tag>> build() async {
    return _loadTags();
  }

  Future<List<Tag>> _loadTags() async {
    // In a real app, this might read from a writable file.
    // For now, we load from assets, but treat it as our "database".
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/db_tags.json',
      );
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final List<dynamic> tagsList = jsonMap['tags'];
      _originalTags = tagsList.map((t) => Tag.fromJson(t)).toList();
      return List.from(_originalTags);
    } catch (e) {
      print('Error loading tags: $e');
      return [];
    }
  }

  /// Creates a checkpoint of the current state.
  /// Call this when entering the Vendor Editor.
  void createCheckpoint() {
    if (state.hasValue) {
      _checkpointTags = state.value!
          .map((t) => Tag.fromJson(t.toJson()))
          .toList();
    }
  }

  /// Reverts to the last checkpoint.
  /// Call this on "Undo Changes".
  void revertToCheckpoint() {
    if (_checkpointTags.isNotEmpty) {
      state = AsyncData(List.from(_checkpointTags));
      // Re-clone to ensure safe subsequent edits if we don't clear checkpoint
      _checkpointTags = _checkpointTags
          .map((t) => Tag.fromJson(t.toJson()))
          .toList();
    }
  }

  /// Commits changes (simulated save).
  /// In a real app, this would write to disk.
  Future<void> saveChanges() async {
    if (state.hasValue) {
      _originalTags = List.from(state.value!);
      // Clear checkpoint after save? Or keep it?
      // Usually save implies "tags are now safe", so maybe we update checkpoint too.
      _checkpointTags = state.value!
          .map((t) => Tag.fromJson(t.toJson()))
          .toList();

      // TODO: Implement actual writing to file system if needed.
      // print("Saved ${state.value!.length} tags to storage.");
    }
  }

  /// Adds a tag to a vendor.
  void addTagToVendor(String vendorName, String tagName) {
    if (!state.hasValue) return;

    final currentList = List<Tag>.from(state.value!);
    final vendorIndex = currentList.indexWhere((t) => t.name == vendorName);

    if (vendorIndex != -1) {
      final vendor = currentList[vendorIndex];
      if (!vendor.related.contains(tagName)) {
        final updatedVendor = vendor.copyWith(
          related: [...vendor.related, tagName],
        );
        currentList[vendorIndex] = updatedVendor;
        state = AsyncData(currentList);
      }
    }
  }

  /// Removes a tag from a vendor.
  void removeTagFromVendor(String vendorName, String tagName) {
    if (!state.hasValue) return;

    final currentList = List<Tag>.from(state.value!);
    final vendorIndex = currentList.indexWhere((t) => t.name == vendorName);

    if (vendorIndex != -1) {
      final vendor = currentList[vendorIndex];
      if (vendor.related.contains(tagName)) {
        final updatedVendor = vendor.copyWith(
          related: vendor.related.where((t) => t != tagName).toList(),
        );
        currentList[vendorIndex] = updatedVendor;
        state = AsyncData(currentList);
      }
    }
  }
}
