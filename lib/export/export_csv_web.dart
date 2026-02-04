import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:hive/hive.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

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

  final bytes = utf8.encode(csv);
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8;');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..download = 'scans_${DateTime.now().millisecondsSinceEpoch}.csv'
    ..click();

  html.Url.revokeObjectUrl(url);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('CSV exported (download started).')),
  );
}
