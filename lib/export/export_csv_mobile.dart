import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/scan_entry.dart';

Future<void> exportScansToCsv(BuildContext context) async {
  final box = Hive.box<ScanEntry>('scans');
  final scans = box.values.toList();

  if (scans.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No scans to export yet.')),
    );
    return;
  }

  final rows = <List<String>>[
    ['timestamp', 'raw', 'name', 'id', 'position', 'company'],
    ...scans.map((s) => [
          s.timestampIso,
          s.raw,
          s.name ?? '',
          s.id ?? '',
          s.position ?? '',
          s.company ?? '',
        ]),
  ];

  final csv = const ListToCsvConverter().convert(rows);

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/scans_${DateTime.now().millisecondsSinceEpoch}.csv');
  await file.writeAsString(csv);

  await Share.shareXFiles(
    [XFile(file.path)],
    text: 'Exported QR scan logs (CSV)',
  );
}
