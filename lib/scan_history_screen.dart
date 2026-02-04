import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'export/export_csv.dart';
import 'models/scan_entry.dart';
import 'qr_result_screen.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmClearAll() async {
    final box = Hive.box<ScanEntry>('scans');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear scan history?'),
        content: const Text('This will delete all saved scans.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await box.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan history cleared.')),
      );
    }
  }

  bool _matches(ScanEntry s, String q) {
    if (q.isEmpty) return true;
    final qq = q.toLowerCase();

    final hay = [
      s.raw,
      s.name ?? '',
      s.id ?? '',
      s.position ?? '',
      s.company ?? '',
      s.timestampIso,
    ].join(' ').toLowerCase();

    return hay.contains(qq);
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<ScanEntry>('scans');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: () => exportScansToCsv(context),
            icon: const Icon(Icons.download),
          ),
          IconButton(
            tooltip: 'Clear all',
            onPressed: _confirmClearAll,
            icon: const Icon(Icons.delete_forever),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search name / ID / company / raw text',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),

          Expanded(
            child: ValueListenableBuilder(
              valueListenable: box.listenable(),
              builder: (context, Box<ScanEntry> b, _) {
                final q = _searchCtrl.text.trim();

                // Latest first (Hive stores in insertion order)
                final items = b.values
                    .where((s) => _matches(s, q))
                    .toList()
                    .reversed
                    .toList();

                if (items.isEmpty) {
                  return const Center(
                    child: Text('No scans yet.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final s = items[index];

                    final title = (s.name?.trim().isNotEmpty == true)
                        ? s.name!.trim()
                        : (s.id?.trim().isNotEmpty == true)
                            ? s.id!.trim()
                            : 'Unknown QR';

                    final subtitle = [
                      if ((s.id ?? '').trim().isNotEmpty) 'ID: ${s.id}',
                      if ((s.position ?? '').trim().isNotEmpty)
                        'Role: ${s.position}',
                      if ((s.company ?? '').trim().isNotEmpty)
                        'Company: ${s.company}',
                      'Time: ${s.timestampIso}',
                    ].join(' • ');

                    return Dismissible(
                      key: ValueKey(s.key),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete this scan?'),
                                content: const Text('This cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                      },
                      onDismissed: (_) async {
                        await s.delete();
                      },
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QrResultScreen(code: s.raw),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.qr_code, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
