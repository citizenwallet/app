String formatLongText(String text, {int length = 6}) {
  if (text.length < length) {
    return text;
  }

  final first = text.substring(0, length);
  final last = text.substring(text.length - length, text.length);

  return '$first...$last';
}

String ellipsizeLongText(String text, {int length = 6}) {
  if (text.length < length) {
    return text;
  }

  final first = text.substring(0, length);

  return '$first...';
}
