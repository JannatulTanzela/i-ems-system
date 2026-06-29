double calculateAttendancePercentage({required int total, required double presentCount}) {
  if (total <= 0) return 0;
  return ((presentCount / total) * 100).clamp(0, 100);
}

String formatAttendancePercentage({required int total, required double presentCount}) {
  return '${calculateAttendancePercentage(total: total, presentCount: presentCount).toStringAsFixed(0)}%';
}
