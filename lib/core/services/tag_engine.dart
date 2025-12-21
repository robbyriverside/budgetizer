import 'dart:convert';
import '../models/financial_entities.dart';

class TagEngine {
  final List<Tag> _tags = [];

  // Cache regexes for performance
  final Map<String, RegExp> _regexCache = {};

  TagEngine(List<Tag> initialTags) {
    _tags.addAll(initialTags);
    _compileRegexes();
  }

  void _compileRegexes() {
    for (var tag in _tags) {
      if (tag.regex != null && tag.regex!.isNotEmpty) {
        try {
          var pattern = tag.regex!;
          var caseSensitive = true;
          // Handle (?i) manually as Dart RegExp doesn't support inline flags in some environments
          if (pattern.startsWith('(?i)')) {
            pattern = pattern.substring(4);
            caseSensitive = false;
          }
          _regexCache[tag.name] = RegExp(pattern, caseSensitive: caseSensitive);
        } catch (e) {
          print('Error compiling regex for ${tag.name}: ${tag.regex}');
        }
      }
    }
  }

  static TagEngine fromJson(String jsonStr) {
    final Map<String, dynamic> data = jsonDecode(jsonStr);
    final List<dynamic> tagList = data['tags'];
    final tags = tagList.map((t) => Tag.fromJson(t)).toList();
    return TagEngine(tags);
  }

  static TagEngine fromMap(Map<String, dynamic> data) {
    final List<dynamic> tagList = data['tags'];
    final tags = tagList.map((t) => Tag.fromJson(t)).toList();
    return TagEngine(tags);
  }

  /// Analyzes a transaction and returns an updated one with tags applied.
  BankTransaction applyTags(BankTransaction tx) {
    final Set<String> newTags = {};
    String? matchedVendor;

    // 1. Tagging based on Regex (Vendor Matching)
    for (var tag in _tags) {
      if (tag.regex != null && tag.regex!.isNotEmpty) {
        final regex = _regexCache[tag.name];
        if (regex != null && regex.hasMatch(tx.description)) {
          newTags.add(tag.name);
          newTags.addAll(tag.related);

          if (tag.type == 'Vendor') {
            matchedVendor = tag.name;
          }
        }
      }
    }

    // 2. Add existing tags (e.g. from Plaid categories)
    newTags.addAll(tx.tags);

    // 3. Filter out removed tags
    newTags.removeWhere((t) => tx.removedTags.contains(t));

    return tx.copyWith(
      vendorName: matchedVendor ?? tx.vendorName, // Update vendor if matched
      tags: newTags.toList(),
    );
  }

  Map<String, dynamic> analyzeDescription(String description) {
    final Set<String> tags = {};
    String vendor = description;

    for (var tag in _tags) {
      if (tag.regex != null && tag.regex!.isNotEmpty) {
        final regex = _regexCache[tag.name];
        if (regex != null && regex.hasMatch(description)) {
          tags.add(tag.name);
          tags.addAll(tag.related);
          if (tag.type == 'Vendor') {
            vendor = tag.name;
          }
        }
      }
    }

    return {'vendor': vendor, 'tags': tags.toList()};
  }

  List<Tag> get tags => List.unmodifiable(_tags);

  /// Adds a new tag to the engine and compiles its regex.
  /// This is used when the AI identifies a new vendor.
  void learnTag(Tag newTag) {
    _tags.add(newTag);
    if (newTag.regex != null && newTag.regex!.isNotEmpty) {
      try {
        var pattern = newTag.regex!;
        var caseSensitive = true;
        if (pattern.startsWith('(?i)')) {
          pattern = pattern.substring(4);
          caseSensitive = false;
        }
        _regexCache[newTag.name] = RegExp(
          pattern,
          caseSensitive: caseSensitive,
        );
      } catch (e) {
        print('Error compiling regex for learned tag ${newTag.name}: $e');
      }
    }
  }
}
