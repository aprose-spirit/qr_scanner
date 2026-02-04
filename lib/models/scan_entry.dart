import 'package:hive/hive.dart';

part 'scan_entry.g.dart';

@HiveType(typeId: 1)
class ScanEntry extends HiveObject {
  @HiveField(0)
  final String timestampIso;

  @HiveField(1)
  final String raw;

  @HiveField(2)
  final String? name;

  @HiveField(3)
  final String? id;

  @HiveField(4)
  final String? position;

  @HiveField(5)
  final String? company;

  ScanEntry({
    required this.timestampIso,
    required this.raw,
    this.name,
    this.id,
    this.position,
    this.company,
  });
}
