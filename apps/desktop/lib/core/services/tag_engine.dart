import 'dart:convert';
import '../models/financial_entities.dart';

class TagEngine {
  final List<Tag> _tags = [];
  final List<Tag> _accountTags = [];

  // Cache regexes for performance
  final Map<String, RegExp> _regexCache = {};

  // Tag Engine Logic with separation between Base and Account tags
  TagEngine(List<Tag> initialTags) {
    _tags.addAll(initialTags);
    _compileRegexes(initialTags);
  }

  void _compileRegexes(List<Tag> tags) {
    for (var tag in tags) {
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

  /// Loads account-specific tags overlaying the base tags
  void loadAccountTags(String jsonStr) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      final List<dynamic> tagList = data['tags'];
      final tags = tagList.map((t) => Tag.fromJson(t)).toList();

      _accountTags.clear();
      _accountTags.addAll(tags);
      // Recompile with new tags
      _compileRegexes(_accountTags);
    } catch (e) {
      print('Error loading account tags: $e');
    }
  }

  /// Analyzes a transaction and returns an updated one with tags applied.
  BankTransaction applyTags(BankTransaction tx) {
    final Set<String> newTags = {};
    String? matchedVendor;

    // Combine all tags for lookup
    final allTags = [..._tags, ..._accountTags];

    // 1. Tagging based on Regex (Vendor Matching)
    for (var tag in allTags) {
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

  /// Suggests tags to remove based on Previous Cycle Logic (History)
  List<String> predictRemovedTags(
    BankTransaction currentTx,
    List<BankTransaction> historyTxs,
  ) {
    final suggestions = <String>{};

    // Look for transactions with matching Vendor/Description in history
    final matches = historyTxs
        .where(
          (hTx) =>
              hTx.id != currentTx.id &&
              ((currentTx.vendorName != 'Unknown' &&
                      hTx.vendorName == currentTx.vendorName) ||
                  hTx.description == currentTx.description),
        )
        .toList();

    // If we find matches, check what tags were removed in those transactions
    for (var match in matches) {
      suggestions.addAll(match.removedTags);
    }

    return suggestions.toList();
  }

  Map<String, dynamic> analyzeDescription(String description) {
    final Set<String> tags = {};
    String vendor = description;

    final allTags = [..._tags, ..._accountTags];

    for (var tag in allTags) {
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

  List<Tag> get tags => List.unmodifiable([..._tags, ..._accountTags]);
  List<Tag> get accountTags => List.unmodifiable(_accountTags);

  /// Adds a new tag to the ACCOUNT tags list and compiles its regex.
  void learnTag(Tag newTag) {
    // Avoid duplicates by name in account tags
    final index = _accountTags.indexWhere((t) => t.name == newTag.name);
    if (index != -1) {
      _accountTags[index] = newTag;
    } else {
      _accountTags.add(newTag);
    }

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
