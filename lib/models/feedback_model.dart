class WrongAnswerFeedback {
  final String question;
  final String correctAnswer;
  final String userAnswer;
  final String explanation;

  WrongAnswerFeedback({
    required this.question,
    required this.correctAnswer,
    required this.userAnswer,
    required this.explanation,
  });
}

class FeedbackModel {
  final int score;
  final int total;
  final List<WrongAnswerFeedback> wrongAnswers;

  FeedbackModel({
    required this.score,
    required this.total,
    required this.wrongAnswers,
  });

  // Below 60% counts as a "bad" score that should prompt a retake.
  bool get isGoodScore => total == 0 ? true : (score / total) >= 0.6;
}