import 'package:flutter/material.dart';
import 'package:budgetizer_dart/budgetizer_dart.dart'; // For BankTransaction
import 'package:google_fonts/google_fonts.dart';
import 'tag_chip.dart';

class TransactionListTile extends StatelessWidget {
  final BankTransaction transaction;
  final Map<String, String>? tagTypeMap; // Map<TagName, TagType>
  final Function(String tag)? onTagDeleted;
  final Function(String tag)? onTagTap;
  final bool selected;
  final VoidCallback? onTap;

  const TransactionListTile({
    super.key,
    required this.transaction,
    this.tagTypeMap,
    this.onTagDeleted,
    this.onTagTap,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: selected ? Colors.teal.withValues(alpha: 0.1) : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.vendorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          transaction.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${transaction.amount.abs().toStringAsFixed(2)}',
                    style: GoogleFonts.robotoMono(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: transaction.amount < 0
                          ? Colors.greenAccent
                          : Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (transaction.tags.isNotEmpty)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: transaction.tags.map((tag) {
                    final type = tagTypeMap?[tag];
                    return TagChip(
                      label: tag,
                      type: type,
                      onDeleted: onTagDeleted != null
                          ? () => onTagDeleted!(tag)
                          : null,
                      onTap: onTagTap != null ? () => onTagTap!(tag) : null,
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
