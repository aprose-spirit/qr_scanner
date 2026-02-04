import 'package:flutter/material.dart';

Future<void> exportScansToCsv(BuildContext context) async {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('CSV export is not supported on this platform.')),
  );
}
