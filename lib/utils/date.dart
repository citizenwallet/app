int generateCacheBusterValue() {
  return (DateTime.now().millisecondsSinceEpoch / 1000 / 60) ~/ 5;
}
