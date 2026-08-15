class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctIndex: json['correctIndex'] is int
          ? json['correctIndex']
          : int.tryParse(json['correctIndex'].toString()) ?? 0,
      explanation: json['explanation'] ?? '',
    );
  }
}

class QuizModel {
  final String topic;
  final List<QuizQuestion> questions;

  QuizModel({
    required this.topic,
    required this.questions,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      topic: json['topic'] ?? 'Quiz',
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}