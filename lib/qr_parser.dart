class ParsedQrText {
  final String name;
  final String id;
  final String position;
  final String company;

  ParsedQrText({
    required this.name,
    required this.id,
    required this.position,
    required this.company,
  });
}

ParsedQrText? parseProminentQr(String raw) {
  final lines = raw
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  if (lines.length < 4) return null;

  final name = lines[0];
  final id = lines[1];
  final position = lines[2];
  final company = lines[3];

  // match your ID like 26-0100-1007 (adjust if needed)
  final idOk = RegExp(r'^\d{2}-\d{4}-\d{4}$').hasMatch(id);
  if (!idOk) return null;

  return ParsedQrText(name: name, id: id, position: position, company: company);
}
