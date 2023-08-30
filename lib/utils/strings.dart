String formatLongText(String text, {int length = 6}) {
  if (text.length < length) {
    return text;
  }

  final first = text.substring(0, length);
  final last = text.substring(text.length - length, text.length);

  return '$first...$last';
}

String ellipsizeLongText(String text,
    {int startLength = 6, int endLength = 4}) {
  if (text.length < startLength || text.length < (startLength + endLength)) {
    return text;
  }

  final first = text.substring(0, startLength);
  final last = text.substring(text.length - endLength, text.length);

  return '$first...$last';
}
