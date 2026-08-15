class TipsModel {
  final List<String> tips;

  TipsModel({required this.tips});

  // Built directly from the topics the user got wrong — no extra
  // Gemini call needed, since the quiz already carries an explanation
  // per question.
  factory TipsModel.fromWrongTopics(List<String> weakTopics) {
    if (weakTopics.isEmpty) {
      return TipsModel(
        tips: ["Great job! Keep revising regularly to stay sharp."],
      );
    }

    return TipsModel(
      tips: weakTopics.map((topic) => "Review: $topic").toList(),
    );
  }
}