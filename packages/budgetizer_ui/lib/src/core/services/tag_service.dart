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
  final Map<String, String> tagTypeMap;

  TagState({
    this.tags = const [],
    this.changes = const [],
    this.tagTypeMap = const {},
  });

  TagState copyWith({
    List<Tag>? tags,
    List<TagChange>? changes,
    Map<String, String>? tagTypeMap,
  }) {
    return TagState(
      tags: tags ?? this.tags,
      changes: changes ?? this.changes,
      tagTypeMap: tagTypeMap ?? this.tagTypeMap,
    );
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
    final typeMap = {
      for (var t in tags)
        if (t.type != null) t.name: t.type!,
    };
    return TagState(tags: tags, tagTypeMap: typeMap);
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

  /// Returns true if the removal is valid (keeps at least 1 Market tag).
  /// Returns false if it violates the rule.
  bool validateTagRemoval(List<String> currentTags, String tagToRemove) {
    if (!state.hasValue) return true; // Fail safe
    final map = state.value!.tagTypeMap;
    final typeToRemove = map[tagToRemove];

    if (typeToRemove == null) return true; // Unknown type, allow removal

    // We only care if we are removing a Market tag
    if (!['Market'].contains(typeToRemove)) return true;

    // Check if there are any *other* Market tags remaining
    bool hasMarket = false;
    for (final tag in currentTags) {
      if (tag == tagToRemove) continue; // Skip the one we are removing
      final type = map[tag];
      if (type == 'Market') {
        hasMarket = true;
        break;
      }
    }

    if (!hasMarket) {
      return false;
    }

    return true;
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
          tagTypeMap: state.value?.tagTypeMap ?? {},
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
      // Also update map if it's a new tag? No, this only links them.
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
      _applyReverse(change);
    } else if (change.type == 'remove') {
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
