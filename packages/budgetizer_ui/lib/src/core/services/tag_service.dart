import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgetizer_dart/budgetizer_dart.dart';

class TagChange {
  final String id;
  final String description;
  final String type; // 'start', 'add', 'remove'
  final String vendorName;
  final String tagName;
  final DateTime timestamp;

  TagChange({
    required this.id,
    required this.description,
    required this.type,
    required this.vendorName,
    required this.tagName,
    required this.timestamp,
  });
}

class TagState {
  final List<Tag> tags;
  final List<TagChange> changes;

  TagState({this.tags = const [], this.changes = const []});

  TagState copyWith({List<Tag>? tags, List<TagChange>? changes}) {
    return TagState(tags: tags ?? this.tags, changes: changes ?? this.changes);
  }
}

final tagServiceProvider = AsyncNotifierProvider<TagService, TagState>(
  TagService.new,
);

class TagService extends AsyncNotifier<TagState> {
  List<Tag> _checkpointTags = [];
  List<TagChange> _checkpointChanges = [];

  @override
  Future<TagState> build() async {
    final tags = await _loadTags();
    return TagState(tags: tags);
  }

  Future<List<Tag>> _loadTags() async {
    try {
      final jsonString = await rootBundle.loadString(
        'packages/budgetizer_ui/assets/data/db_tags.json',
      );
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final List<dynamic> tagsList = jsonMap['tags'];
      return tagsList.map((t) => Tag.fromJson(t)).toList();
    } catch (e) {
      print('Error loading tags: $e');
      return [];
    }
  }

  void createCheckpoint() {
    if (state.hasValue) {
      _checkpointTags = List.from(
        state.value!.tags.map((t) => Tag.fromJson(t.toJson())).toList(),
      );
      _checkpointChanges = List.from(state.value!.changes);
    }
  }

  void revertToCheckpoint() {
    if (_checkpointTags.isNotEmpty) {
      state = AsyncData(
        TagState(
          tags: List.from(_checkpointTags.map((t) => Tag.fromJson(t.toJson()))),
          changes: List.from(_checkpointChanges),
        ),
      );
    }
  }

  Future<void> saveChanges() async {
    if (state.hasValue) {
      // Clear changes list on save
      state = AsyncData(state.value!.copyWith(changes: []));
      createCheckpoint();
      // TODO: Write to disk
    }
  }

  void addTagToVendor(String vendorName, String tagName) {
    if (!state.hasValue) return;

    final currentState = state.value!;
    final currentList = List<Tag>.from(currentState.tags);
    final vendorIndex = currentList.indexWhere((t) => t.name == vendorName);

    if (vendorIndex != -1) {
      final vendor = currentList[vendorIndex];
      if (!vendor.related.contains(tagName)) {
        final updatedVendor = vendor.copyWith(
          related: [...vendor.related, tagName],
        );
        currentList[vendorIndex] = updatedVendor;

        final newChange = TagChange(
          id: DateTime.now().toIso8601String(),
          description: "Added '$tagName' to '$vendorName'",
          type: 'add',
          vendorName: vendorName,
          tagName: tagName,
          timestamp: DateTime.now(),
        );

        state = AsyncData(
          currentState.copyWith(
            tags: currentList,
            changes: [newChange, ...currentState.changes],
          ),
        );
      }
    }
  }

  void removeTagFromVendor(String vendorName, String tagName) {
    if (!state.hasValue) return;

    final currentState = state.value!;
    final currentList = List<Tag>.from(currentState.tags);
    final vendorIndex = currentList.indexWhere((t) => t.name == vendorName);

    if (vendorIndex != -1) {
      final vendor = currentList[vendorIndex];
      if (vendor.related.contains(tagName)) {
        final updatedVendor = vendor.copyWith(
          related: vendor.related.where((t) => t != tagName).toList(),
        );
        currentList[vendorIndex] = updatedVendor;

        final newChange = TagChange(
          id: DateTime.now().toIso8601String(),
          description: "Removed '$tagName' from '$vendorName'",
          type: 'remove',
          vendorName: vendorName,
          tagName: tagName,
          timestamp: DateTime.now(),
        );

        state = AsyncData(
          currentState.copyWith(
            tags: currentList,
            changes: [newChange, ...currentState.changes],
          ),
        );
      }
    }
  }

  void undoSpecificChange(TagChange change) {
    if (!state.hasValue) return;

    // Reverse the action
    if (change.type == 'add') {
      // Undo add -> remove
      // We call the internal 'remove' logic but WITHOUT adding a new log entry
      // OR we just assume removeTagFromVendor adds a log entry, so "undoing a change" IS a change itself?
      // "provide a way to selectively undo the changes... remove from the changes list"
      // User said: "undo dialog should let the user delete changes in the list, and an undo button that reverses the changes to the list."
      // So we should remove this change from the log AND reverse the effect.

      _applyReverse(change);
    } else if (change.type == 'remove') {
      // Undo remove -> add
      _applyReverse(change);
    }

    // Remove from log
    final currentState = state.value!;
    final newChanges = currentState.changes
        .where((c) => c.id != change.id)
        .toList();
    state = AsyncData(currentState.copyWith(changes: newChanges));
  }

  void _applyReverse(TagChange change) {
    // Helper that modifies tags but NOT changes log
    if (!state.hasValue) return;
    final currentState = state.value!;
    final currentList = List<Tag>.from(currentState.tags);
    final vendorIndex = currentList.indexWhere(
      (t) => t.name == change.vendorName,
    );

    if (vendorIndex != -1) {
      final vendor = currentList[vendorIndex];
      Tag? updatedVendor;

      if (change.type == 'add') {
        // was add, so remove it
        updatedVendor = vendor.copyWith(
          related: vendor.related.where((t) => t != change.tagName).toList(),
        );
      } else if (change.type == 'remove') {
        // was remove, so add it
        if (!vendor.related.contains(change.tagName)) {
          updatedVendor = vendor.copyWith(
            related: [...vendor.related, change.tagName],
          );
        }
      }

      if (updatedVendor != null) {
        currentList[vendorIndex] = updatedVendor;
        state = AsyncData(currentState.copyWith(tags: currentList));
      }
    }
  }
}
