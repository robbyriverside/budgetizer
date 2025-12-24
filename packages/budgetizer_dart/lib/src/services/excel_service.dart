import 'package:excel/excel.dart';
import '../models/financial_entities.dart';

class ExcelService {
  /// Exports a list of transactions to an Excel file buffer.
  /// Returns the bytes of the file.
  Future<List<int>> exportTransactions(
    List<BankTransaction> transactions, {
    Map<String, String>? errors,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Transactions'];
    excel.delete('Sheet1'); // Remove default sheet

    // Header Row
    sheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Date'),
      TextCellValue('Description'),
      TextCellValue('Amount'),
      TextCellValue('Vendor'),
      TextCellValue('Tags (Removable)'),
      TextCellValue('Corrections (AI)'),
      if (errors != null) TextCellValue('Errors (System)'),
    ]);

    // Data Rows
    for (var tx in transactions) {
      final dateStr = tx.date.toIso8601String().split('T')[0];
      // Format tags: [Tag1], [Tag2] (Exclude Vendor Name as it is permanent)
      final tagsStr = tx.tags
          .where((t) => t != tx.vendorName)
          .map((t) => '[$t]')
          .join(', ');

      sheet.appendRow([
        TextCellValue(tx.id),
        TextCellValue(dateStr),
        TextCellValue(tx.description),
        DoubleCellValue(tx.amount), // Raw double specific for calculation
        TextCellValue(tx.vendorName),
        TextCellValue(tagsStr),
        TextCellValue(''), // Empty corrections column for user input
        if (errors != null) TextCellValue(errors[tx.id] ?? ''),
      ]);
    }

    return excel.encode() ?? [];
  }

  /// Imports transactions from an Excel file buffer.
  /// Returns a list of simple objects representing the row edits.
  /// Note: This returns partial objects (ID + Vendor + Tags) to be reconciled with the DB.
  Future<List<TransactionImport>> importTransactions(List<int> bytes) async {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel['Transactions'];

    final imports = <TransactionImport>[];

    // Skip header (row 0)
    for (var i = 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      if (row.isEmpty) continue;

      // ID is column 0
      final idCell = row[0];
      if (idCell == null || idCell.value == null) continue;
      final id = idCell.value.toString();

      // Vendor is column 4
      final vendorCell = row[4];
      final vendorName = vendorCell?.value.toString() ?? '';

      // Tags is column 5
      final tagsCell = row[5];
      final tagsStr = tagsCell?.value.toString() ?? '';
      final tags = _parseTags(tagsStr);

      // Corrections is column 6
      final correctionCell = row[6];
      final correction = correctionCell?.value.toString() ?? '';

      imports.add(
        TransactionImport(
          id: id,
          vendorName: vendorName,
          tags: tags,
          correction: correction,
        ),
      );
    }

    return imports;
  }

  /// Exports a list of Tags (Budgets) to an Excel file buffer.
  Future<List<int>> exportBudgets(List<Tag> tags) async {
    final excel = Excel.createExcel();
    final sheet = excel['Budgets'];
    excel.delete('Sheet1');

    // Header
    sheet.appendRow([
      TextCellValue('Tag Name'),
      TextCellValue('Frequency (Days)'),
      TextCellValue('Limit (\$)'),
    ]);

    for (var tag in tags) {
      sheet.appendRow([
        TextCellValue(tag.name),
        IntCellValue(tag.frequency ?? 0), // Default to 0 (Monthly)
        DoubleCellValue(tag.budgetLimit ?? 0.0),
      ]);
    }

    return excel.encode() ?? [];
  }

  /// Imports budgets from an Excel file buffer.
  Future<List<BudgetImport>> importBudgets(List<int> bytes) async {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel['Budgets'];

    final imports = <BudgetImport>[];

    for (var i = 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      if (row.isEmpty) continue;

      final nameCell = row[0];
      if (nameCell == null || nameCell.value == null) continue;
      final name = nameCell.value.toString();

      final freqCell = row[1];
      final freq = int.tryParse(freqCell?.value.toString() ?? '0') ?? 0;

      final limitCell = row[2];
      final limit =
          double.tryParse(limitCell?.value.toString() ?? '0.0') ?? 0.0;

      imports.add(BudgetImport(name: name, frequency: freq, limit: limit));
    }

    return imports;
  }

  List<String> _parseTags(String raw) {
    // Expects "[Tag1], [Tag2]"
    // Regex to capture content inside [...]
    final regex = RegExp(r'\[(.*?)\]');
    final matches = regex.allMatches(raw);
    return matches.map((m) => m.group(1)!.trim()).toList();
  }
}

class TransactionImport {
  final String id;
  final String vendorName;
  final List<String> tags;
  final String correction;

  TransactionImport({
    required this.id,
    required this.vendorName,
    required this.tags,
    this.correction = '',
  });
}

class BudgetImport {
  final String name;
  final int frequency;
  final double limit;

  BudgetImport({
    required this.name,
    required this.frequency,
    required this.limit,
  });
}
