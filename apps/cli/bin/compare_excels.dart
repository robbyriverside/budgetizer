import 'dart:io';
import 'package:excel/excel.dart';

void main(List<String> args) {
  if (args.length != 2) {
    print('Usage: dart run bin/compare_excels.dart <file1.xlsx> <file2.xlsx>');
    exit(1);
  }

  final file1 = args[0];
  final file2 = args[1];

  print('Comparing $file1 vs $file2...');

  final bytes1 = File(file1).readAsBytesSync();
  final bytes2 = File(file2).readAsBytesSync();

  final excel1 = Excel.decodeBytes(bytes1);
  final excel2 = Excel.decodeBytes(bytes2);

  final sheet1 = excel1['Transactions'];
  final sheet2 = excel2['Transactions'];

  if (sheet1.maxRows != sheet2.maxRows) {
    print('❌ Row count mismatch: ${sheet1.maxRows} vs ${sheet2.maxRows}');
    exit(1);
  }

  int diffs = 0;
  // Skip header (row 0)
  for (var i = 1; i < sheet1.maxRows; i++) {
    final row1 = sheet1.row(i);
    final row2 = sheet2.row(i);

    if (row1.isEmpty || row2.isEmpty) continue; // Skip empty rows if any

    // ID is column 0
    final id1 = row1[0]?.value.toString();
    final id2 = row2[0]?.value.toString();

    // Vendor is column 4
    final vendor1 = row1[4]?.value.toString();
    final vendor2 = row2[4]?.value.toString();

    // Tags is column 5
    final tags1 = row1[5]?.value.toString();
    final tags2 = row2[5]?.value.toString();

    bool rowDiff = false;
    if (vendor1 != vendor2) {
      print('❌ Row $i Vendor Mismatch: "$vendor1" vs "$vendor2" (ID: $id1)');
      rowDiff = true;
    }
    if (tags1 != tags2) {
      print('❌ Row $i Tags Mismatch: "$tags1" vs "$tags2" (ID: $id1)');
      rowDiff = true;
    }

    if (rowDiff) diffs++;
  }

  if (diffs == 0) {
    print(
      '✅ SUCCESS: Files are identical (Vendor & Tags). checked ${sheet1.maxRows - 1} rows.',
    );
  } else {
    print('❌ FAILURE: Found $diffs differences.');
    exit(1);
  }
}
