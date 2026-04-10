String generateEntityId([String prefix = 'musa']) {
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  return '$prefix-$timestamp';
}
