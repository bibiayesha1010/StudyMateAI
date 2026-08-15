class ProgressEntry {
  final String topic;
  final int score;
  final int total;
  final DateTime date;

  ProgressEntry({
    required this.topic,
    required this.score,
    required this.total,
    required this.date,
  });

  double get percentage => total == 0 ? 0 : (score / total) * 100;
}