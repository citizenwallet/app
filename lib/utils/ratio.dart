/// Clamps a value between a minimum and maximum value, with a progressive
/// effect based on a ratio between 0 and 1.
///
/// If the ratio is 1, the function returns the minimum value. If the ratio is
/// 0, the function returns the maximum value. For ratios between 0 and 1, the
/// function returns a value between the minimum and maximum values, with a
/// progressive effect based on the ratio. For example, if the ratio is 0.5,
/// the function returns a value halfway between the minimum and maximum
/// values.
///
/// If the maximum value is less than the minimum value, the function returns
/// the minimum value.
///
/// Example usage:
///
/// ```dart
/// double value = progressiveClamp(0, 10, 0.5); // Returns 5.0
/// ```
double progressiveClamp(double min, double max, double ratio) {
  if (max < min) {
    return min;
  }

  return switch (ratio) {
    1 => min,
    0 => max,
    _ => (min + ((max - min) * (1 - ratio))).clamp(min, max),
  };
}
