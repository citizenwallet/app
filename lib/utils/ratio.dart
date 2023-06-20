double progressiveClamp(double min, double max, double ratio) {
  return (max * (1 - ratio)).clamp(min, max);
}
